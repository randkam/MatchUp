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
                                .foregroundColor(Color(red: 0.0, green: 0.55, blue: 0.95))
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
                                .foregroundColor(Color(red: 0.0, green: 0.55, blue: 0.95).opacity(0.5))
                                .padding(.top, 60)
                            
                            Text("No chats joined yet!")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Join a court or create a new chat to get started")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
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

                if chats.isEmpty {
                    chats = getBasketballCourtChats()
                }
            }
        }
    }

    func getBasketballCourtChats() -> [Chat] {
        let schools = SharedDataStore.shared.locations
        return schools.map { school in
            Chat(
                id: school.id,
                name: school.locationName
//                lastMessage: "test",
//                timestamp: Date(),
//                isActive: school.locationActivePlayers > 0
            )
        }
    }

    func loadJoinedChats(completion: @escaping (Bool, Error?) -> Void) {
        let networkManager = NetworkManager()

        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int else {
            print("User ID not found")
            return
        }

        networkManager.fetchUserLocations(userId: userId) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.joinedLocations = UserDefaults.standard.array(forKey: "joinedLocations") as? [Int] ?? []
                } else {
                    print("Error fetching joined locations: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }

        guard let url = URL(string: APIConfig.locationsEndpoint) else {
            completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(false, error)
                return
            }

            guard let data = data else {
                print("Error: No data received")
                completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from the server."]))
                return
            }

            do {
                struct Location: Codable {
                    var locationId: Int
                    var locationName: String
                    var locationAddress: String
                    var locationZipCode: String
                    var locationActivePlayers: Int
                    var locationReviews: String
                }

                let locations: [Location] = try JSONDecoder().decode([Location].self, from: data)

                if let savedLocations = UserDefaults.standard.array(forKey: "joinedLocations") as? [Int] {
                    joinedLocations = savedLocations
                }

                let joinedChats = locations.filter { joinedLocations.contains($0.locationId) }
                chats = joinedChats.map { Chat(id: $0.locationId, name: $0.locationName) }

                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                print("Error decoding chats: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false, error)
                }
            }
        }.resume()
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
                .foregroundColor(Color.gray)
            
            TextField("Search chats", text: $text)
                .font(.system(size: 17))
                .foregroundColor(.white)
            
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.15))
        .cornerRadius(10)
    }
}

struct ChatRow: View {
    var chat: Chat

    var body: some View {
        HStack(spacing: 15) {
            // Court Icon
            Circle()
                .fill(Color(red: 0.0, green: 0.55, blue: 0.95))
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
                .foregroundColor(Color.gray.opacity(0.8))
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(ModernColorScheme.background)
        .contentShape(Rectangle())
    }
}
