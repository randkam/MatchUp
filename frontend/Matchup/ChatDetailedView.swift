import SwiftUI
import Combine

struct MessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let showAvatar: Bool
    let showSenderName: Bool
    let displayName: String
    
    private var timestampString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: message.timestamp)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser {
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(message.content)
                        .padding(12)
                        .background(ModernColorScheme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    Text(timestampString)
                        .font(.system(size: 12))
                        .foregroundColor(ModernColorScheme.textSecondary)
                        .padding(.horizontal, 4)
                }
            } else {
                Group {
                    if showAvatar {
                        AvatarView(userId: message.senderId, userName: message.senderUserName, size: 28)
                    } else {
                        Color.clear.frame(width: 28, height: 28)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    if showSenderName {
                        Text(displayName)
                            .font(.system(size: 12))
                            .foregroundColor(ModernColorScheme.textSecondary)
                            .padding(.leading, 4)
                    }
                    Text(message.content)
                        .padding(12)
                        .background(ModernColorScheme.surface)
                        .foregroundColor(ModernColorScheme.text)
                        .cornerRadius(20)
                    Text(timestampString)
                        .font(.system(size: 12))
                        .foregroundColor(ModernColorScheme.textSecondary)
                        .padding(.horizontal, 4)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct DateHeader: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ModernColorScheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
    }
}

struct MessageGroupView: View {
    let group: MessageGroup
    let currentUserId: Int?
    let anchorForMessage: (ChatMessage) -> String
    
    var body: some View {
        VStack(spacing: 12) {
            DateHeader(text: group.dateHeader)
            
            ForEach(group.messages.indices, id: \.self) { index in
                let message = group.messages[index]
                let isCurrent = message.senderId == currentUserId
                let isLastOfSender = index == group.messages.count - 1 || group.messages[index + 1].senderId != message.senderId
                let isFirstOfSender = index == 0 || group.messages[index - 1].senderId != message.senderId
                MessageBubble(
                    message: message,
                    isCurrentUser: isCurrent,
                    showAvatar: !isCurrent && isLastOfSender,
                    showSenderName: !isCurrent && isFirstOfSender,
                    displayName: message.senderUserName
                )
                .id(anchorForMessage(message))
            }
        }
    }
}

struct MessageListView: View {
    let messageGroups: [MessageGroup]
    let currentUserId: Int?
    let anchorForMessage: (ChatMessage) -> String
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(messageGroups) { group in
                MessageGroupView(
                    group: group,
                    currentUserId: currentUserId,
                    anchorForMessage: anchorForMessage
                )
            }
            Color.clear.frame(height: 0).id("bottomAnchor")
        }
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom, 16)
    }
}

struct ChatDetailedView: View {
    var chat: Chat
    @State private var messageText = ""
    @StateObject private var webSocketManager: WebSocketManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var keyboardResponder = KeyboardResponder()
    @State private var showLocationDetails = false
    @State private var location: Location?
    @State private var isLoading = true
    @State private var scrollViewProxy: ScrollViewProxy?
    @State private var currentPage = 0
    @State private var hasMorePages = true
    @State private var isLoadingMore = false
    @State private var isRefreshing = false
    @State private var shouldAutoScroll = true
    @State private var lastContentOffset: CGFloat = 0
    @State private var hasInitiallyScrolled = false
    @State private var messageCount = 0
    @State private var isAtBottom = true
    
    private var currentUserId: Int? {
        UserDefaults.standard.value(forKey: "loggedInUserId") as? Int
    }
    private var currentUserName: String? {
        UserDefaults.standard.value(forKey: "loggedInUserNickName") as? String
    }
    
    private var messageGroups: [MessageGroup] {
        MessageGroup.groupMessages(webSocketManager.messages)
    }
    
    init(chat: Chat) {
        self.chat = chat
        _webSocketManager = StateObject(wrappedValue: WebSocketManager())
    }
    
    private func messageAnchor(_ message: ChatMessage) -> String {
        if let id = message.id {
            return "msg_\(id)"
        }
        let millis = Int(message.timestamp.timeIntervalSince1970 * 1000)
        return "tmp_\(message.locationId)_\(message.senderId)_\(millis)_\(message.content.hashValue)"
    }

    private func forceScrollToBottom() {
        guard let proxy = scrollViewProxy else { return }
        
        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo("bottomAnchor", anchor: .bottom)
            }
        }
    }
    
    private func loadMorePreservingPosition() {
        guard hasMorePages && !isLoadingMore else { return }
        let preserveId = webSocketManager.messages.first.map { messageAnchor($0) }
        loadMessages(preserveAnchorId: preserveId)
    }
    
    private func refresh() async {
        isRefreshing = true
        loadMessages(refresh: true)
        isRefreshing = false
    }
    
    private func fetchLocationDetails() {
        isLoading = true
        guard let url = URL(string: "\(APIConfig.locationsEndpoint)/\(chat.id)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error fetching location: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .useDefaultKeys
                    let location = try decoder.decode(Location.self, from: data)
                    self.location = location
                } catch {
                    print("Error decoding location: \(error)")
                }
            }
        }.resume()
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                // Header
                let headerView = Group {
                    if let location = location {
                        Button(action: { showLocationDetails = true }) {
                            LocationHeaderContent(location: location, chatName: chat.name)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else if isLoading {
                        LoadingHeaderView()
                    }
                }
                
                headerView
                    .background(ModernColorScheme.surface)
                    .navigationBarBackButtonHidden(false)
                
                // Chat Messages
                ScrollView {
                    LazyVStack(spacing: 0) {
                        Color.clear
                            .frame(height: 1)
                            .id("topAnchor")
                            .onAppear {
                                if currentPage > 0 || !webSocketManager.messages.isEmpty {
                                    loadMorePreservingPosition()
                                }
                            }

                        if isLoadingMore && webSocketManager.messages.isEmpty {
                            ProgressView()
                                .padding()
                        }
                        
                        ForEach(messageGroups) { group in
                            MessageGroupView(
                                group: group,
                                currentUserId: currentUserId,
                                anchorForMessage: { message in messageAnchor(message) }
                            )
                            .id(group.id)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        .padding(.bottom, 16)
                        
                        Color.clear
                            .frame(height: 1)
                            .id("bottomAnchor")
                            .onAppear {
                                isAtBottom = true
                                shouldAutoScroll = true
                            }
                            .onDisappear {
                                isAtBottom = false
                                shouldAutoScroll = false
                            }
                    }
                }
                .background(ModernColorScheme.background)
                .onTapGesture {
                    self.endEditing()
                }
                .onAppear {
                    scrollViewProxy = proxy
                }
                .onChange(of: webSocketManager.messages.count) { newCount in
                    if newCount > messageCount {
                        // New messages have been added
                        messageCount = newCount
                        let lastMessage = webSocketManager.messages.last
                        let isFromCurrentUser = lastMessage?.senderId == currentUserId
                        
                        if isFromCurrentUser || shouldAutoScroll || isAtBottom {
                            forceScrollToBottom()
                        }
                    }
                }
                .onChange(of: keyboardResponder.keyboardHeight) { newHeight in
                    if newHeight > 0 {
                        shouldAutoScroll = true
                        forceScrollToBottom()
                    }
                }
                .simultaneousGesture(
                    DragGesture().onChanged { value in
                        let scrollDelta = value.translation.height
                        
                        // If user scrolls up more than 50 points, disable auto-scroll
                        if scrollDelta > 50 {
                            shouldAutoScroll = false
                        }
                        
                        // If user scrolls to bottom, enable auto-scroll
                        if value.translation.height < 0 && 
                           value.predictedEndTranslation.height < -50 {
                            shouldAutoScroll = true
                        }
                    }
                )
                .refreshable {
                    await refresh()
                }
                
                // Message Input
                MessageInputView(
                    messageText: $messageText,
                    currentUserId: currentUserId,
                    currentUserName: currentUserName,
                    onSend: sendMessage
                )
            }
        }
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showLocationDetails) {
            if let location = location {
                LocationDetailView(location: location)
            }
        }
        .onAppear {
            // Connect WebSocket when view appears
            webSocketManager.connect(locationId: chat.id) { success in
                if success {
                    loadMessages()
                }
            }
            
            fetchLocationDetails()
            
            // Initialize message count
            messageCount = webSocketManager.messages.count
        }
        .onDisappear {
            // Clean up
            webSocketManager.disconnect()
        }
    }
    
    private func loadMessages(refresh: Bool = false, preserveAnchorId: String? = nil) {
        if refresh {
            currentPage = 0
            webSocketManager.messages = []
            hasMorePages = true
        }
        
        guard hasMorePages && !isLoadingMore else { return }
        isLoadingMore = true
        
        NetworkManager().getPaginatedMessages(
            locationId: chat.id,
            page: currentPage,
            size: 20
        ) { result in
            DispatchQueue.main.async {
                isLoadingMore = false
                
                switch result {
                case .success(let response):
                    if currentPage == 0 {
                        webSocketManager.messages = response.content
                        messageCount = response.content.count
                        shouldAutoScroll = true
                        forceScrollToBottom()
                    } else {
                        webSocketManager.messages.insert(contentsOf: response.content, at: 0)
                        messageCount = webSocketManager.messages.count
                        if let preserveAnchorId = preserveAnchorId, let proxy = scrollViewProxy {
                            withAnimation(nil) {
                                proxy.scrollTo(preserveAnchorId, anchor: .top)
                            }
                        }
                    }
                    hasMorePages = !response.last
                    currentPage += 1
                    
                case .failure(let error):
                    print("Failed to load messages: \(error)")
                }
            }
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
            senderUserName: userName,
            timestamp: Date()
        )

        webSocketManager.sendMessage(message)
        messageText = ""
        
        // Enable auto-scroll and force scroll to bottom
        shouldAutoScroll = true
        forceScrollToBottom()
    }
    
    private func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Break out complex views into separate components
struct LocationHeaderContent: View {
    let location: Location
    let chatName: String
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(ModernColorScheme.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(chatName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(ModernColorScheme.text)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 12))
                            Text("\(location.locationActivePlayers) active")
                        }
                        
                        Text("•")
                        
                        Text(location.locationType?.rawValue.capitalized ?? "Outdoor")
                        
                        if let isLit = location.isLitAtNight, isLit {
                            Text("•")
                            
                            HStack(spacing: 4) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.yellow)
                                Text("Lit")
                            }
                        }
                    }
                    .font(.system(size: 13))
                    .foregroundColor(ModernColorScheme.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(ModernColorScheme.surface)
    }
}

struct LoadingHeaderView: View {
    var body: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ModernColorScheme.primary))
            Text("Loading location details...")
                .font(.system(size: 15))
                .foregroundColor(ModernColorScheme.textSecondary)
            
            Spacer()
        }
        .padding()
        .background(ModernColorScheme.surface)
    }
}

struct MessageInputView: View {
    @Binding var messageText: String
    let currentUserId: Int?
    let currentUserName: String?
    let onSend: (String, Int, String) -> Void
    
    var body: some View {
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
                        onSend(messageText, senderId, userName)
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

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
