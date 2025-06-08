import SwiftUI
import Combine

struct ChatDetailedView: View {
    var chat: Chat
    @State private var messageText = ""
    @StateObject private var webSocketManager: WebSocketManager
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isInputFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollToBottom = false
    @State private var isFullScreen = false
    
    private var currentUserId: Int? {
        UserDefaults.standard.value(forKey: "loggedInUserId") as? Int
    }
    private var currentUserName: String? {
        UserDefaults.standard.value(forKey: "loggedInUserName") as? String
    }

    init(chat: Chat) {
        self.chat = chat
        _webSocketManager = StateObject(wrappedValue: WebSocketManager())
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(chat.name)
                        .font(ModernFontScheme.heading)
                        .foregroundColor(ModernColorScheme.text)
                    
                    Spacer()
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(ModernColorScheme.textSecondary)
                    }
                }
                .padding()
                .background(ModernColorScheme.surface)
                
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(webSocketManager.messages.enumerated()), id: \.offset) { index, message in
                                MessageBubble(
                                    message: message,
                                    isCurrentUser: message.senderId == currentUserId
                                )
                            }
                        }
                        .padding()
                        .id("messagesEnd")
                    }
                    .background(ModernColorScheme.background)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.height > 50 && isInputFocused {
                                    isInputFocused = false
                                    isFullScreen = true
                                }
                            }
                    )
                    .onChange(of: webSocketManager.messages) { oldValue, newValue in
                        withAnimation {
                            proxy.scrollTo("messagesEnd", anchor: .bottom)
                        }
                    }
                    .onChange(of: isInputFocused) { oldValue, newValue in
                        if newValue {
                            withAnimation {
                                proxy.scrollTo("messagesEnd", anchor: .bottom)
                            }
                        }
                    }
                }
                .frame(maxHeight: isFullScreen ? .infinity : geometry.size.height - (isInputFocused ? keyboardHeight + 60 : 60))

                // Message Input
                VStack(spacing: 0) {
                    Divider()
                        .background(ModernColorScheme.textSecondary.opacity(0.2))
                    
                    HStack(spacing: 12) {
                        TextField("Type a message...", text: $messageText)
                            .padding(12)
                            .background(ModernColorScheme.surface)
                            .cornerRadius(20)
                            .foregroundColor(ModernColorScheme.text)
                            .focused($isInputFocused)
                        
                        Button(action: {
                            if let senderId = currentUserId, let userName = currentUserName {
                                sendMessage(content: messageText, senderId: senderId, userName: userName)
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(ModernColorScheme.primary)
                                .clipShape(Circle())
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(ModernColorScheme.background)
                }
            }
        }
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        .onAppear {
            let locationIdInt = Int(chat.id)
            webSocketManager.connect(locationId: locationIdInt) { success in
                if success {
                    print("Connected successfully to chat")
                    webSocketManager.loadOldMessages(locationId: locationIdInt) { oldMessages in
                        webSocketManager.messages = oldMessages
                        // Scroll to bottom after loading messages
                        scrollToBottom = true
                    }
                } else {
                    print("Failed to connect to chat")
                }
            }
            
            // Add keyboard observers
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardHeight = 0
            }
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
    }

    func sendMessage(content: String, senderId: Int, userName: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let locationIdInt = chat.id
        let message = ChatMessage(
            id: nil,
            locationId: locationIdInt,
            senderId: senderId,
            content: content,
            senderUserName: userName
        )

        webSocketManager.sendMessage(message)
        messageText = ""
        scrollToBottom = true
    }

    struct MessageBubble: View {
        var message: ChatMessage
        var isCurrentUser: Bool?

        var body: some View {
            VStack(alignment: isCurrentUser == true ? .trailing : .leading, spacing: 2) {
                if isCurrentUser == false {
                    Text(message.senderUserName)
                        .font(ModernFontScheme.caption)
                        .foregroundColor(ModernColorScheme.textSecondary)
                        .padding(.leading, 5)
                }

                HStack {
                    if isCurrentUser == true { Spacer() }

                    Text(message.content)
                        .font(ModernFontScheme.body)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(isCurrentUser == true ? ModernColorScheme.primary : ModernColorScheme.surface)
                        .foregroundColor(isCurrentUser == true ? .white : ModernColorScheme.text)
                        .cornerRadius(16)
                        .frame(maxWidth: 280, alignment: isCurrentUser == true ? .trailing : .leading)

                    if isCurrentUser == false { Spacer() }
                }
            }
        }
    }
}
