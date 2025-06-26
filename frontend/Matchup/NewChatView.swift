import SwiftUI

struct NewChatView: View {
    @Binding var chats: [Chat]
    @Environment(\.dismiss) var dismiss
    @State private var locations: [Location] = []  // List of all available locations
    @State private var selectedLocation: Location? // Selected location for new chat
    @State private var isLoading = true            // Loading state for locations

    var body: some View {
        NavigationStack {
            Form {
                if isLoading {
                    // Show loading indicator while fetching locations
                    ProgressView("Loading locations...")
                } else {
                    // Display a list of locations to select
                    Section(header: Text("Select Location to Join")) {
                        List(locations, id: \.locationId) { location in
                            HStack {
                                Text(location.locationName)
                                Spacer()
                                if selectedLocation?.locationId == location.locationId {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedLocation = location
                            }
                        }
                    }
                }
            }
            .navigationTitle("Join New Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Join") {
                        if let selectedLocation = selectedLocation {
                            joinChat(for: selectedLocation)
                            dismiss()
                        }
                    }
                    .disabled(selectedLocation == nil) // Disable button if no location is selected
                }
            }
            .onAppear {
                fetchLocations()
            }
        }
    }

    // Fetch all available locations from the API
    func fetchLocations() {
        guard let url = URL(string: "https://matchup-api.xyz/api/v1/locations") else {
            print("Invalid URL for fetching locations.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching locations: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Error: No data received.")
                return
            }
            
            do {
                // Decode locations from the server response
                locations = try JSONDecoder().decode([Location].self, from: data)
                isLoading = false
            } catch {
                print("Error decoding locations: \(error.localizedDescription)")
            }
        }.resume()
    }

    // Join or create a chat for the selected location
    func joinChat(for location: Location) {
        // Check if chat already exists for this location
        if !chats.contains(where: { $0.name == location.locationName }) {
            let newChat = Chat(id: location.id, name: location.locationName)
            chats.append(newChat)

            // Retrieve user ID from UserDefaults
            guard let userId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int else {
                print("User ID not found in UserDefaults")
                return
            }

            // Prepare API URL
            guard let url = URL(string: "https://matchup-api.xyz/api/user-locations") else {
                print("Invalid URL for adding user location.")
                return
            }

            // Prepare JSON payload
            let requestBody: [String: Any] = [
                "locationId": location.locationId,
                "userId": userId
            ]

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])

                // Create and configure the POST request
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData

                // Perform the POST request
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error making POST request: \(error.localizedDescription)")
                        return
                    }

                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                        print("User successfully joined the location and chat.")
                    } else {
                        print("Failed to join location and chat. Status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                    }
                }.resume()
            } catch {
                print("Error serializing JSON payload: \(error.localizedDescription)")
            }
        }
    }

}
