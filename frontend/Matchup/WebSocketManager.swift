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
                                // Check if message already exists to avoid duplicates
                                if let messages = self?.messages {
                                    // Only add if the message doesn't exist and has a valid ID
                                    if let messageId = chatMessage.id, !messages.contains(where: { $0.id == messageId }) {
                                        self?.messages.append(chatMessage)
                                        // Sort messages by timestamp
                                        self?.messages.sort { $0.timestamp < $1.timestamp }
                                    }
                                }
                            }
                        } catch {
                            print("Failed to decode message: \(error)")
                        }
                    }
                default:
                    break
                }
                // Continue listening for new messages
                self?.receiveMessage()

            case .failure(let error):
                print("Error receiving message: \(error)")
                // Try to reconnect or handle error
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.receiveMessage()
                }
            }
        }
    }

    func sendMessage(_ message: ChatMessage) {
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(message)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
                webSocket?.send(wsMessage) { [weak self] error in
                    if let error = error {
                        print("Error sending message: \(error)")
                    } else {
                        // Optimistically add message to the local array
                        DispatchQueue.main.async {
                            self?.messages.append(message)
                            // Sort messages by timestamp
                            if let messages = self?.messages {
                                self?.messages = messages.sorted { $0.timestamp < $1.timestamp }
                            }
                        }
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

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Failed to load messages: \(error)")
                return
            }

            guard let data = data else { return }

            do {
                let messages = try JSONDecoder().decode([ChatMessage].self, from: data)
                DispatchQueue.main.async {
                    self?.messages = messages.sorted { $0.timestamp < $1.timestamp }
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
        
        // Handle timestamp from server
        let timestampString = try container.decode(String.self, forKey: .timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let date = formatter.date(from: timestampString) {
            timestamp = date
        } else {
            // Try other common formats as fallback
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = formatter.date(from: timestampString) {
                timestamp = date
            } else {
                let isoFormatter = ISO8601DateFormatter()
                if let date = isoFormatter.date(from: timestampString) {
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
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(locationId, forKey: .locationId)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(content, forKey: .content)
        try container.encode(senderUserName, forKey: .senderUserName)
        
        // Convert Date to server format with microseconds
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
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
