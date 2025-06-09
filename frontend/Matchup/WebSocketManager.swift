import Foundation
import Combine

enum WebSocketState {
    case connected, disconnected, error(Error)
}

enum WebSocketError: Error {
    case connectionFailed, messageEncodingFailed, notConnected
}

final class WebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    
    // MARK: – Public
    @Published var messages: [ChatMessage] = []
    
    func connect(locationId: Int, completion: @escaping (Bool) -> Void) {
        currentLocationId = locationId
        connectionCompletion = completion
        
        let urlString = APIConfig.wsChatEndpoint(locationId: locationId) // must return wss://…
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        session = URLSession(configuration: .default,
                             delegate: self,
                             delegateQueue: .main)            // main queue keeps UI work on main thread
        webSocket = session!.webSocketTask(with: url)
        webSocket?.resume()
        
        receiveMessage()        // start listening immediately
        startPingTimer()        // keep-alive
    }
    
    func sendMessage(_ message: ChatMessage) {
        guard isConnected else {
            print("WebSocket not connected – message not sent")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            if let json = String(data: data, encoding: .utf8) {
                webSocket?.send(.string(json)) { error in
                    if let error = error { print("Send error:", error) }
                }
            }
        } catch {
            print("Encoding error:", error)
        }
    }
    
    func disconnect() {
        pingTimer?.invalidate()
        pingTimer = nil
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        session = nil
        isConnected = false
    }
    
    func loadOldMessages(locationId: Int, completion: @escaping ([ChatMessage]) -> Void) {
        let urlString = "\(APIConfig.messagesEndpoint)/\(locationId)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let msgs = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
                print("Load-old-messages error:", error ?? WebSocketError.connectionFailed)
                return
            }
            DispatchQueue.main.async {
                self.messages = msgs
                completion(msgs)
            }
        }.resume()
    }
    
    // MARK: – Private
    @Published private(set) var state: WebSocketState = .disconnected
    
    private var session: URLSession?
    private var webSocket: URLSessionWebSocketTask?
    private var isConnected = false
    private var connectionCompletion: ((Bool) -> Void)?
    private var currentLocationId: Int = 0
    private var pingTimer: Timer?
    private var reconnectionAttempts = 0
    private let maxReconnections = 1         // simple back-off
    
    // Listen continuously
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let msg):
                if case .string(let text) = msg,
                   let data = text.data(using: .utf8),
                   let chat = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                    DispatchQueue.main.async { self.messages.append(chat) }
                }
                self.receiveMessage()            // loop!
            case .failure(let err):
                print("Receive error:", err)
                self.state = .error(err)
                self.attemptReconnect()
            }
        }
    }
    
    // MARK: – Keep-alive
    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.webSocket?.sendPing { error in
                if let error = error {
                    print("Ping failed:", error)
                    self?.attemptReconnect()
                }
            }
        }
    }
    
    // MARK: – Reconnection
    private func attemptReconnect() {
        guard reconnectionAttempts < maxReconnections else {
            print("Max reconnection attempts reached")
            return
        }
        reconnectionAttempts += 1
        disconnect()
        print("Reconnecting attempt \(reconnectionAttempts)…")
        connect(locationId: currentLocationId) { _ in }
    }
    
    // MARK: – URLSessionWebSocketDelegate
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        isConnected = true
        reconnectionAttempts = 0
        state = .connected
        connectionCompletion?(true); connectionCompletion = nil
        print("WebSocket connected")
    }
    
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        isConnected = false
        state = .disconnected
        if let reason,
           let reasonString = String(data: reason, encoding: .utf8) {
            print("Socket closed: \(closeCode) – \(reasonString)")
        } else {
            print("Socket closed: \(closeCode)")
        }
        attemptReconnect()
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
