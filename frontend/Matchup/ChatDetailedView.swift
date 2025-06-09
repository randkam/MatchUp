import SwiftUI
import Combine

struct ChatDetailedView: View {
    var chat: Chat
    @State private var messageText = ""
    @StateObject private var webSocketManager: WebSocketManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var keyboardResponder = KeyboardResponder()

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
                        Color.clear.frame(height: 0).id("bottomAnchor")
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 16)
                }
                .background(ModernColorScheme.background)
                .simultaneousGesture(DragGesture().onChanged({ _ in
                    self.endEditing()
                }))
                .onTapGesture {
                    self.endEditing()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo("bottomAnchor", anchor: .bottom)
                    }
                }
                .onChange(of: webSocketManager.messages) { messages in
                    if !messages.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo("bottomAnchor", anchor: .bottom)
                            }
                        }
                    }
                }
                .onChange(of: keyboardResponder.keyboardHeight) { newHeight in
                    if newHeight > 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                                proxy.scrollTo("bottomAnchor", anchor: .bottom)
                            }
                        }
                    }
                }
            }

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
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        .onAppear {
            let locationIdInt = Int(chat.id)
            webSocketManager.connect(locationId: locationIdInt) { success in
                if success {
                    print("Connected successfully to chat")
                    webSocketManager.loadOldMessages(locationId: locationIdInt) { oldMessages in
                        webSocketManager.messages = oldMessages
                    }
                } else {
                    print("Failed to connect to chat")
                }
            }
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
    }

    private func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
    }

    struct MessageBubble: View {
        var message: ChatMessage
        var isCurrentUser: Bool?
        
        private func formatTimestamp(_ date: Date?) -> String? {
            guard let date = date else { return nil }
            
            let calendar = Calendar.current
            let now = Date()
            
            // If the message is from today, show only time
            if calendar.isDateInToday(date) {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }
            
            // If the message is from yesterday, show "Yesterday" and time
            if calendar.isDateInYesterday(date) {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Yesterday " + formatter.string(from: date)
            }
            
            // If the message is from this week, show day name and time
            if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day, daysAgo < 7 {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE h:mm a"
                return formatter.string(from: date)
            }
            
            // Otherwise show full date
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }

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

                    VStack(alignment: isCurrentUser == true ? .trailing : .leading, spacing: 4) {
                        Text(message.content)
                            .font(ModernFontScheme.body)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(isCurrentUser == true ? ModernColorScheme.primary : ModernColorScheme.surface)
                            .foregroundColor(isCurrentUser == true ? .white : ModernColorScheme.text)
                            .cornerRadius(16)
                            .frame(maxWidth: 280, alignment: isCurrentUser == true ? .trailing : .leading)
                        
                        if let timestampStr = formatTimestamp(message.timestamp) {
                            Text(timestampStr)
                                .font(.system(size: 11))
                                .foregroundColor(ModernColorScheme.textSecondary.opacity(0.8))
                                .padding(.horizontal, 4)
                        }
                    }

                    if isCurrentUser == false { Spacer() }
                }
            }
        }
    }
}

final class KeyboardResponder: ObservableObject {
    @Published private(set) var keyboardHeight: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        let keyboardWillShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map(\.height)

        let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        Publishers.Merge(keyboardWillShow, keyboardWillHide)
            .subscribe(on: RunLoop.main)
            .assign(to: \.keyboardHeight, on: self)
            .store(in: &cancellables)
    }
}
