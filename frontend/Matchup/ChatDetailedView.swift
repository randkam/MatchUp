import SwiftUI
import Combine

struct MessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    
    private var timestampString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: message.timestamp)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if isCurrentUser {
                Spacer(minLength: 0)
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
                if !isCurrentUser {
                    Text(message.senderUserName)
                        .font(.system(size: 12))
                        .foregroundColor(ModernColorScheme.textSecondary)
                        .padding(.leading, 4)
                }
                
                Text(message.content)
                    .padding(12)
                    .background(isCurrentUser ? ModernColorScheme.primary : ModernColorScheme.surface)
                    .foregroundColor(isCurrentUser ? .white : ModernColorScheme.text)
                    .cornerRadius(20)
                
                Text(timestampString)
                    .font(.system(size: 12))
                    .foregroundColor(ModernColorScheme.textSecondary)
                    .padding(.horizontal, 4)
            }
            
            if !isCurrentUser {
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
    
    var body: some View {
        VStack(spacing: 12) {
            DateHeader(text: group.dateHeader)
            
            ForEach(group.messages, id: \.id) { message in
                MessageBubble(
                    message: message,
                    isCurrentUser: message.senderId == currentUserId
                )
            }
        }
    }
}

struct MessageListView: View {
    let messageGroups: [MessageGroup]
    let currentUserId: Int?
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(messageGroups) { group in
                MessageGroupView(
                    group: group,
                    currentUserId: currentUserId
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
    
    // Timer for periodic scroll checks
    @State private var scrollTimer: Timer?
    
    private var currentUserId: Int? {
        UserDefaults.standard.value(forKey: "loggedInUserId") as? Int
    }
    private var currentUserName: String? {
        UserDefaults.standard.value(forKey: "loggedInUserName") as? String
    }
    
    private var messageGroups: [MessageGroup] {
        MessageGroup.groupMessages(webSocketManager.messages)
    }
    
    init(chat: Chat) {
        self.chat = chat
        _webSocketManager = StateObject(wrappedValue: WebSocketManager())
    }
    
    private func forceScrollToBottom() {
        guard let proxy = scrollViewProxy else { return }
        
        // Execute multiple scroll attempts with different delays
        let delays = [0.1, 0.3, 0.5]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation {
                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                }
            }
        }
    }
    
    private func setupScrollTimer() {
        // Invalidate existing timer if any
        scrollTimer?.invalidate()
        
        // Create new timer that checks scroll position every 0.5 seconds
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if shouldAutoScroll {
                forceScrollToBottom()
            }
        }
    }
    
    private func loadMoreIfNeeded(currentItem item: ChatMessage) {
        guard !isLoadingMore else { return }
        
        let thresholdIndex = 5
        if webSocketManager.messages.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            loadMessages()
        }
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
                        if isLoadingMore && webSocketManager.messages.isEmpty {
                            ProgressView()
                                .padding()
                        }
                        
                        ForEach(messageGroups) { group in
                            MessageGroupView(
                                group: group,
                                currentUserId: currentUserId
                            )
                            .id(group.id) // Ensure each group has unique ID
                            .onAppear {
                                if let firstMessage = group.messages.first {
                                    loadMoreIfNeeded(currentItem: firstMessage)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        .padding(.bottom, 16)
                        
                        Color.clear.frame(height: 1).id("bottomAnchor")
                    }
                }
                .background(ModernColorScheme.background)
                .onTapGesture {
                    self.endEditing()
                }
                .onAppear {
                    scrollViewProxy = proxy
                    setupScrollTimer()
                    forceScrollToBottom()
                }
                .onChange(of: webSocketManager.messages.count) { newCount in
                    if newCount > messageCount {
                        // New messages have been added
                        messageCount = newCount
                        let lastMessage = webSocketManager.messages.last
                        let isFromCurrentUser = lastMessage?.senderId == currentUserId
                        
                        if isFromCurrentUser || shouldAutoScroll {
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
            scrollTimer?.invalidate()
            scrollTimer = nil
            webSocketManager.disconnect()
        }
    }
    
    private func loadMessages(refresh: Bool = false) {
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
