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
    @Published var isConnected = false
    private var hasInitialLoad = false

    func connect(locationId: Int, completion: @escaping (Bool) -> Void) {
        // Disconnect existing connection if any
        disconnect()
        
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
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        do {
                            let chatMessage = try JSONDecoder().decode(ChatMessage.self, from: data)
                            DispatchQueue.main.async {
                                // Only add if the message doesn't exist
                                if !self.messages.contains(where: { $0.id == chatMessage.id }) {
                                    self.messages.append(chatMessage)
                                    // Sort messages by timestamp
                                    self.messages.sort { $0.timestamp < $1.timestamp }
                                }
                            }
                        } catch {
                            print("Failed to decode message: \(error)")
                        }
                    }
                default:
                    break
                }
                
                // Only continue receiving if still connected
                if self.isConnected {
                    self.receiveMessage()
                }

            case .failure(let error):
                print("Error receiving message: \(error)")
                // Only try to reconnect if still connected
                if self.isConnected {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.receiveMessage()
                    }
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
                webSocket?.send(wsMessage) { error in
                    if let error = error {
                        print("Error sending message: \(error)")
                    }
                    // Don't add message locally - wait for server response
                }
            }
        } catch {
            print("Failed to encode message: \(error)")
        }
    }

    func disconnect() {
        isConnected = false
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        // Clear messages when disconnecting
        messages = []
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
        
        // Handle timestamp from server - can be either a string or an array of components
        if let timestampArray = try? container.decode([Int].self, forKey: .timestamp) {
            // Handle array format [year, month, day, hour, minute, second, nanosecond]
            let components = DateComponents(
                year: timestampArray[0],
                month: timestampArray[1],
                day: timestampArray[2],
                hour: timestampArray[3],
                minute: timestampArray[4],
                second: timestampArray[5]
            )
            if let date = Calendar.current.date(from: components) {
                timestamp = date
            } else {
                timestamp = Date() // Fallback to current date if conversion fails
            }
        } else if let timestampString = try? container.decode(String.self, forKey: .timestamp) {
            // Try the original string format as fallback
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = formatter.date(from: timestampString) {
                timestamp = date
            } else {
                timestamp = Date() // Fallback to current date if parsing fails
            }
        } else {
            timestamp = Date() // Fallback to current date if both methods fail
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
