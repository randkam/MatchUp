import SwiftUI
import Combine
import CoreLocation

struct ChatView: View {
    @State private var searchText = ""
    @State private var chats: [Chat] = []
    @State private var showingNewChatView = false
    @State private var joinedLocations: [Int] = []
    @State private var isAnimating = false

    var body: some View {
        NavigationStack {
            ZStack {
                ModernColorScheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // New Chat Button
                    Button(action: {
                        showingNewChatView = true
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 20))
                                .foregroundColor(ModernColorScheme.primary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .sheet(isPresented: $showingNewChatView) {
                        NewChatView(chats: $chats)
                    }

                    // Search Bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)

                    if chats.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 60))
                                .foregroundColor(ModernColorScheme.primary.opacity(0.5))
                                .padding(.top, 60)
                            
                            Text("No chats joined yet!")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Join a court or create a new chat to get started")
                                .font(.system(size: 16))
                                .foregroundColor(ModernColorScheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxHeight: .infinity)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(chats.filter { searchText.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchText) }) { chat in
                                    NavigationLink(destination: ChatDetailedView(chat: chat)) {
                                        ChatRow(chat: chat)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    isAnimating = true
                }
                
                loadJoinedChats { success, error in
                    if let error = error {
                        print("Failed to load chats: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func loadJoinedChats(completion: @escaping (Bool, Error?) -> Void) {
        let networkManager = NetworkManager()

        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int else {
            print("User ID not found")
            return
        }

        networkManager.fetchUserLocations(userId: userId) { success, error in
            if !success {
                DispatchQueue.main.async {
                    completion(false, error)
                }
                return
            }
            let ids = UserDefaults.standard.array(forKey: "joinedLocations") as? [Int] ?? []
            self.joinedLocations = ids
            
            if ids.isEmpty {
                DispatchQueue.main.async {
                    self.chats = []
                    completion(true, nil)
                }
                return
            }
            
            let group = DispatchGroup()
            var fetchedChats: [Chat] = []
            
            for locationId in ids {
                group.enter()
                networkManager.getLocationById(locationId: locationId) { result in
                    switch result {
                    case .success(let location):
                        let chat = Chat(id: location.locationId, name: location.locationName)
                        fetchedChats.append(chat)
                    case .failure(let error):
                        print("Failed to fetch location \(locationId): \(error)")
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.chats = fetchedChats.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                completion(true, nil)
            }
        }
    }
}

//struct Chat: Identifiable, Decodable {
//    var id: Int
//    var name: String
//    var lastMessage: String = ""
//    var timestamp: Date = Date()
//    var unreadCount: Int = 0
//    var isActive: Bool = false
//
//    init(id: Int, name: String, lastMessage: String = "", timestamp: Date = Date(), unreadCount: Int = 0, isActive: Bool = false) {
//        self.id = id
//        self.name = name
//        self.lastMessage = lastMessage
//        self.timestamp = timestamp
//        self.unreadCount = unreadCount
//        self.isActive = isActive
//    }
//
//    enum CodingKeys: String, CodingKey {
//        case id, name
//    }
//}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ModernColorScheme.textSecondary)
            
            TextField("Search chats", text: $text)
                .font(.system(size: 17))
                .foregroundColor(.white)
            
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ModernColorScheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
    }
}

struct ChatRow: View {
    var chat: Chat

    var body: some View {
        HStack(spacing: 15) {
            // Court Icon
            Circle()
                .fill(ModernColorScheme.primary)
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: "basketball.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 22))
                )

            Text(chat.name)
                .font(.system(size: 17))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ModernColorScheme.textSecondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(ModernColorScheme.background)
        .contentShape(Rectangle())
    }
}
