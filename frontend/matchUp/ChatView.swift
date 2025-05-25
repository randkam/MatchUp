import SwiftUI
import Combine

struct ChatView: View {
    @State private var searchText = ""
    @State private var chats: [Chat] = []  // Chats will be fetched based on the user's joined locations
    @State private var showingNewChatView = false
    @State private var joinedLocations: [Int] = []  // Store location IDs as integers

    var body: some View {
        NavigationStack {
            VStack {
                // Right-aligned New Chat Button
                Button(action: {
                    showingNewChatView = true
                }) {
                    HStack {
                        Spacer()  // Push content to the right
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
//                        Text("Join Group Chat")
//                            .font(.headline)
//                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.top, 0.5) // Adjust to your preferred spacing

                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .sheet(isPresented: $showingNewChatView) {
                    NewChatView(chats: $chats)
                }

                // Search bar below the New Chat button
                SearchBar(text: $searchText)
                    .padding(.top, 0.5) // Adjust to your preferred spacing


                // List of chats
                List {
                    ForEach(chats.filter { searchText.isEmpty ? true : $0.name.contains(searchText) }) { chat in
                        NavigationLink(destination: ChatDetailView(chat: chat)) {
                            ChatRow(chat: chat)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .onAppear {
                loadJoinedChats { success, error in
                    if let error = error {
                        print("Failed to load chats: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // Load joined chats based on location IDs stored in UserDefaults
    // (Keep the rest of the code the same as in your original implementation)
    // Load joined chats based on location IDs stored in UserDefaults
    func loadJoinedChats(completion: @escaping (Bool, Error?) -> Void) {
        let networkManager = NetworkManager()

        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int else {
//            print(UserDefaults.standard.value(forKey: "loggedInUserId"))
            print("User ID not found")
            return
        }
        networkManager.fetchUserLocations(userId: userId) { success, error in
            DispatchQueue.main.async {
                if success {
                    // Retrieve the location IDs from UserDefaults
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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
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
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Server second Response: \(jsonString)")
            }
            
            
            do {
                // Define the structure of the response based on the API's JSON
                struct Location: Decodable {
                    var locationId: Int
                    var locationName: String
                    var locationAddress: String
                    var locationZipCode: String
                    var locationActivePlayers: Int
                    var locationReviews: String
                }

                
                // Decode the array of Location objects

                let locations: [Location] = try JSONDecoder().decode([Location].self, from: data)
                
                // Load the joined location IDs from UserDefaults
                if let savedLocations = UserDefaults.standard.array(forKey: "joinedLocations") as? [Int] {
                    joinedLocations = savedLocations
                }
                
                // Filter locations based on the user's joined locations
                print(joinedLocations)
                let joinedChats = locations.filter { location in
                    joinedLocations.contains(location.locationId)
                }
                
                // Create Chat objects for each joined location
                chats = joinedChats.map { location in
                    Chat(id: location.locationId, name: location.locationName)
                }
                
                DispatchQueue.main.async {
                    completion(true, nil)  // Success
                }
                
            } catch {
                print("Error decoding chats: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false, error)  // Failure
                }
            }
        }.resume()
    }
}

//        if let savedLocations = UserDefaults.standard.array(forKey: "joinedLocations") as? [UUID] {
//            joinedLocations = savedLocations

            // Fetch chats corresponding to the joined location IDs
//            let allChats: [Chat] = [
//                Chat(id: UUID(), name: "Slone School chat", lastMessage: "Welcome to location A!", timestamp: "10:45 AM"),
//                Chat(id: UUID(), name: "Hoop Dome chat", lastMessage: "Hey, let's play!", timestamp: "Yesterday"),
//                Chat(id: UUID(), name: "Don Valley chat", lastMessage: "Great game!", timestamp: "Monday")
//            ]
//        chats = allChats
//            chats = allChats.filter { joinedLocations.contains($0.id) }
//        }
//    }


struct Chat: Identifiable, Decodable {
    var id: Int  // Change id to Int
    var name: String
    
//    var lastMessage: String
//    var timestamp: String
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
            Circle()
                .fill(Color.blue)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(chat.name.prefix(1))
                        .foregroundColor(.white)
                        .font(.title2)
                )
            VStack(alignment: .leading) {
                Text(chat.name)
                    .font(.headline)
//                Text(chat.lastMessage)
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
            }
            Spacer()
//            Text(chat.timestamp)
//                .font(.footnote)
//                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}



