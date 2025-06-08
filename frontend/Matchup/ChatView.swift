import SwiftUI
import Combine
import CoreLocation

struct ChatView: View {
    @State private var searchText = ""
    @State private var chats: [Chat] = []
    @State private var showingNewChatView = false
    @State private var joinedLocations: [Int] = []

    var body: some View {
        NavigationStack {
            VStack {
                Button(action: {
                    showingNewChatView = true
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.top, 0.5)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .sheet(isPresented: $showingNewChatView) {
                    NewChatView(chats: $chats)
                }

                SearchBar(text: $searchText)
                    .padding(.top, 0.5)

                if chats.isEmpty {
                    List {
                        ForEach(getBasketballCourtChats()) { chat in
                            NavigationLink(destination: CourtChatView(courtName: chat.name)) {
                                ChatRow(chat: chat)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                } else {
                    List {
                        ForEach(chats.filter { searchText.isEmpty ? true : $0.name.contains(searchText) }) { chat in
                            NavigationLink(destination: ChatDetailedView(chat: chat)) {
                                ChatRow(chat: chat)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .onAppear {
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
        let schools = SharedDataStore.shared.basketballCourts
        return schools.map { school in
            Chat(
                id: Int.random(in: 1000...9999),
                name: school.name,
                lastMessage: "\(school.activePlayers) active players",
                timestamp: Date(),
                unreadCount: school.activePlayers > 0 ? Int.random(in: 0...school.activePlayers) : 0,
                isActive: school.activePlayers > 0
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

struct Chat: Identifiable, Decodable {
    var id: Int
    var name: String
    var lastMessage: String = ""
    var timestamp: Date = Date()
    var unreadCount: Int = 0
    var isActive: Bool = false

    init(id: Int, name: String, lastMessage: String = "", timestamp: Date = Date(), unreadCount: Int = 0, isActive: Bool = false) {
        self.id = id
        self.name = name
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.unreadCount = unreadCount
        self.isActive = isActive
    }

    enum CodingKeys: String, CodingKey {
        case id, name
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            TextField("Search", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)

                        if !text.isEmpty {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 10)
        }
        .padding(.top)
    }
}

struct ChatRow: View {
    var chat: Chat

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(chat.isActive ? Color.green : Color.blue)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "basketball.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                    )

                if chat.unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 22, height: 22)

                        Text("\(chat.unreadCount)")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .offset(x: 18, y: -18)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(chat.name)
                    .font(.headline)
                    .lineLimit(1)

                if !chat.lastMessage.isEmpty {
                    Text(chat.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }

            Spacer()

            if chat.timestamp > Date(timeIntervalSince1970: 0) {
                Text(formatTimestamp(chat.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yy"
            return formatter.string(from: date)
        }
    }
}
