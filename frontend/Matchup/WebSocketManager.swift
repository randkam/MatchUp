import Foundation

// Enum for WebSocket connection state
enum WebSocketState {
    case connected
    case disconnected
    case error(Error)
}

// Custom error type
enum WebSocketError: Error {
    case connectionFailed
    case messageEncodingFailed
    case notConnected
}

class WebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    @Published var messages: [ChatMessage] = []
    private var webSocket: URLSessionWebSocketTask?
    private var isConnected = false

    func connect(locationId: Int, completion: @escaping (Bool) -> Void) {
        let urlString = APIConfig.wsChatEndpoint(locationId: locationId)
        print("Connecting to WebSocket: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("Invalid WebSocket URL")
            completion(false)
            return
        }

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()

        receiveMessage()
        completion(true)
    }

    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received WebSocket message: \(text)")
                    if let data = text.data(using: .utf8) {
                        do {
                            let chatMessage = try JSONDecoder().decode(ChatMessage.self, from: data)
                            print("Successfully decoded message with timestamp: \(String(describing: chatMessage.timestamp))")
                            DispatchQueue.main.async {
                                self?.messages.append(chatMessage)
                            }
                        } catch {
                            print("Failed to decode message: \(error)")
                            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                                print("Raw JSON structure: \(jsonObject)")
                            }
                        }
                    }
                case .data(let data):
                    print("Received unexpected binary message")
                @unknown default:
                    print("Received unknown message type")
                }
                self?.receiveMessage()

            case .failure(let error):
                print("Error receiving message: \(error)")
            }
        }
    }

    func sendMessage(_ message: ChatMessage) {
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(message)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Sending WebSocket message: \(jsonString)")
                let message = URLSessionWebSocketTask.Message.string(jsonString)
                webSocket?.send(message) { error in
                    if let error = error {
                        print("Error sending message: \(error)")
                    }
                }
            }
        } catch {
            print("Failed to encode message: \(error)")
        }
    }

    func disconnect() {
        print("Disconnecting WebSocket")
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
    }

    func loadOldMessages(locationId: Int, completion: @escaping ([ChatMessage]) -> Void) {
        let urlString = "\(APIConfig.messagesEndpoint)/\(locationId)"
        print("Loading old messages from: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("Invalid URL for loading old messages")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Failed to load messages: \(error)")
                return
            }

            guard let data = data else {
                print("No data received when loading old messages")
                return
            }

            do {
                if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                    print("Raw JSON for old messages: \(jsonObject)")
                }
                
                let messages = try JSONDecoder().decode([ChatMessage].self, from: data)
                print("Successfully loaded \(messages.count) old messages")
                DispatchQueue.main.async {
                    self.messages = messages
                    completion(messages)
                }
            } catch {
                print("Failed to decode messages: \(error)")
            }
        }.resume()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        print("WebSocket Connected")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
        print("WebSocket Disconnected with code: \(closeCode)")
        if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
            print("Disconnect reason: \(reasonString)")
        }
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: Int?
    let locationId: Int
    let senderId: Int
    let content: String
    let senderUserName: String
    var timestamp: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case locationId
        case senderId
        case content
        case senderUserName
        case timestamp
    }
    
    init(id: Int?, locationId: Int, senderId: Int, content: String, senderUserName: String, timestamp: Date? = nil) {
        self.id = id
        self.locationId = locationId
        self.senderId = senderId
        self.content = content
        self.senderUserName = senderUserName
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        locationId = try container.decode(Int.self, forKey: .locationId)
        senderId = try container.decode(Int.self, forKey: .senderId)
        content = try container.decode(String.self, forKey: .content)
        senderUserName = try container.decode(String.self, forKey: .senderUserName)
        
        // Handle timestamp from backend (ISO 8601 string)
        if let timestampString = try? container.decodeIfPresent(String.self, forKey: .timestamp) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            timestamp = formatter.date(from: timestampString)
        } else {
            timestamp = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(locationId, forKey: .locationId)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(content, forKey: .content)
        try container.encode(senderUserName, forKey: .senderUserName)
        
        // Only encode timestamp if it exists
        if let timestamp = timestamp {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(formatter.string(from: timestamp), forKey: .timestamp)
        }
    }
}
