import SwiftUI
import Combine

struct ChatDetailedView: View {
    var chat: Chat
    @State private var messageText = ""
    @StateObject private var webSocketManager: WebSocketManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var keyboardResponder = KeyboardResponder()
    @State private var showLocationDetails = false
    @State private var location: Location?
    @State private var isLoading = true

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
            VStack(spacing: 0) {
                if let location = location {
                    Button(action: { showLocationDetails = true }) {
                        HStack(spacing: 12) {
                            // Location Icon and Info
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(ModernColorScheme.primary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(chat.name)
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
                                        
                                        if location.isLitAtNight {
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
                    .buttonStyle(PlainButtonStyle())
                } else if isLoading {
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
            .background(ModernColorScheme.surface)
            .navigationBarBackButtonHidden(false)
            
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
        .sheet(isPresented: $showLocationDetails) {
            if let location = location {
                LocationDetailView(location: location)
            }
        }
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
            
            // Fetch location details
            fetchLocationDetails()
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
    }

    private func fetchLocationDetails() {
        guard let url = URL(string: "\(APIConfig.locationsEndpoint)/\(chat.id)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
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
                    print("Error decoding location: \(error.localizedDescription)")
                    // Try fetching from SharedDataStore as fallback
                    self.location = SharedDataStore.shared.findCourt(by: chat.id)
                }
            }
        }.resume()
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
