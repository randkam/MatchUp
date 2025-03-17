import SwiftUI
import Combine

struct ChatDetailView: View {
    var chat: Chat
    @State private var messageText = ""
    @StateObject private var webSocketManager: WebSocketManager

    private var currentUserId: Int? {
        UserDefaults.standard.value(forKey: "loggedInUserId") as? Int
    }
    private var currentUserName: String? {
        UserDefaults.standard.value(forKey: "loggedInUserName") as? String
    }
//    private var currentUserNickName: String? {
//        UserDefaults.standard.value(forKey: "loggedInUserNickName") as? String
//    }

    init(chat: Chat) {
        self.chat = chat
        _webSocketManager = StateObject(wrappedValue: WebSocketManager())
    }

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(webSocketManager.messages.enumerated()), id: \.offset) { index, message in
                            MessageBubble(
                                message: message,
                                isCurrentUser: message.senderId == currentUserId
                            )
                        }

                    }
                    .padding()
                }
                .onChange(of: webSocketManager.messages) { oldValue, newValue in
                    if let lastMessage = newValue.last {
                        proxy.scrollTo(lastMessage.locationId, anchor: .bottom)
                    }
                }
            }

            HStack {
                TextField("Type a message...", text: $messageText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                Button(action: {
                    sendMessage(content: messageText, senderId: currentUserId!, userName: currentUserName!)
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle(chat.name)
        .padding()
        .padding()
        .onAppear {
            webSocketManager.connect(locationId: chat.id) { success in
                if success {
                    print("Connected successfully to chat")
                    // Load old messages when the user enters the chat
                    webSocketManager.loadOldMessages(locationId: chat.id) { oldMessages in
                        webSocketManager.messages = oldMessages
                    }
                } else {
                    print("Failed to connect to chat")
                }
//                webSocketManager.subscribe(toLocationId: chat.id, handler: <#(ChatMessage) -> Void#>)
            }
        }
        .onDisappear {
            // Just disconnect when leaving the view
            webSocketManager.disconnect()
        }
    }

    func sendMessage(content: String, senderId: Int, userName: String) {
        guard !content.isEmpty else { return }
        
        let message = ChatMessage(
            id: nil,
            locationId: chat.id,
            senderId: senderId,
            content: content,
            senderUserName: userName
      
        )
        
        webSocketManager.sendMessage(message)
        messageText = "" // Clear the input field
    }
}

struct MessageBubble: View {
    var message: ChatMessage
    var isCurrentUser: Bool?

    var body: some View {
        VStack(alignment: isCurrentUser == true ? .trailing : .leading, spacing: 2) {
            if isCurrentUser == false {
                Text(message.senderUserName) // Display username only for other users
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 5)
            }

            HStack {
                if isCurrentUser == true { Spacer() }
                
                Text(message.content)
                    .padding()
                    .background(isCurrentUser == true ? Color.red : Color.gray.opacity(0.3))
                    .foregroundColor(isCurrentUser == true ? .white : .black)
                    .cornerRadius(10)
                    .frame(maxWidth: 250, alignment: isCurrentUser == true ? .trailing : .leading)
                
                if isCurrentUser == false { Spacer() }
            }
        }
//        .padding(.horizontal)
    }
}

