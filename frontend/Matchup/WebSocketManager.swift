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
        guard let url = URL(string: urlString) else {
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
                    if let data = text.data(using: .utf8) {
                        do {
                            let chatMessage = try JSONDecoder().decode(ChatMessage.self, from: data)
                            DispatchQueue.main.async {
                                self?.messages.append(chatMessage)
                            }
                        } catch {
                            print("Failed to decode message: \(error)")
                        }
                    }
                default:
                    break
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
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
    }

    func loadOldMessages(locationId: Int, completion: @escaping ([ChatMessage]) -> Void) {
        let url = URL(string: "\(APIConfig.messagesEndpoint)/\(locationId)")!

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Failed to load messages: \(error)")
                return
            }

            guard let data = data else { return }

            do {
                let messages = try JSONDecoder().decode([ChatMessage].self, from: data)
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
        print("WebSocket Disconnected")
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: Int?
    let locationId: Int
    let senderId: Int
    let content: String
    let senderUserName: String
    let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case id
        case locationId
        case senderId
        case content
        case senderUserName
        case timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        locationId = try container.decode(Int.self, forKey: .locationId)
        senderId = try container.decode(Int.self, forKey: .senderId)
        content = try container.decode(String.self, forKey: .content)
        senderUserName = try container.decode(String.self, forKey: .senderUserName)
        
        // Handle ISO 8601 timestamp from server
        let timestampString = try container.decode(String.self, forKey: .timestamp)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: timestampString) {
            timestamp = date
        } else {
            // Try without fractional seconds if the first attempt fails
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: timestampString) {
                timestamp = date
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .timestamp,
                    in: container,
                    debugDescription: "Date string does not match expected format: \(timestampString)"
                )
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(locationId, forKey: .locationId)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(content, forKey: .content)
        try container.encode(senderUserName, forKey: .senderUserName)
        
        // Convert Date to ISO 8601 string
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestampString = formatter.string(from: timestamp)
        try container.encode(timestampString, forKey: .timestamp)
    }
    
    init(id: Int?, locationId: Int, senderId: Int, content: String, senderUserName: String, timestamp: Date = Date()) {
        self.id = id
        self.locationId = locationId
        self.senderId = senderId
        self.content = content
        self.senderUserName = senderUserName
        self.timestamp = timestamp
    }
}
