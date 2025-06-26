import SwiftUI
import CoreLocation
import Combine

// Court chat message model for the shared data store
struct CourtChatData: Identifiable, Equatable {
    let id = UUID()
    let courtId: Int  // The ID of the court this message belongs to
    let username: String
    let message: String
    let isCurrentUser: Bool
    let timestamp: Date
}

// Game model for the shared data store
struct Game: Identifiable {
    let id = UUID()
    let courtId: Int  // The ID of the court this game is at
    let title: String
    let type: String  // e.g., "3v3", "5v5"
    let maxPlayers: Int
    var currentPlayers: Int  // Changed to var so it can be modified
    let date: Date
    let skill: String  // e.g., "Beginner", "Intermediate", "Advanced"
    let creator: String  // Username of the creator
}

// A central data store that will be shared across all views
class SharedDataStore: ObservableObject {
    static let shared = SharedDataStore() // Singleton instance
    
    @Published var locations: [Location] = []
    @Published var activeGames: [Game] = []
    @Published var courtChatMessages: [CourtChatData] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private init() {
        // Initialize with empty data
        fetchLocations()
    }
    
    // MARK: - Location Methods
    
    func fetchLocations() {
        guard let url = URL(string: APIConfig.locationsEndpoint) else { return }
        isLoading = true
        
        print("Fetching locations from: \(APIConfig.locationsEndpoint)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Error fetching locations: \(error)")
                    self?.error = error
                    return
                }
                
                guard let data = data else {
                    print("No data received from API")
                    self?.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let locations = try decoder.decode([Location].self, from: data)
                    print("Received \(locations.count) locations")
                    print("Active courts: \(locations.filter { $0.locationActivePlayers > 0 }.count)")
                    print("Inactive courts: \(locations.filter { $0.locationActivePlayers == 0 }.count)")
                    print("Indoor courts: \(locations.filter { $0.locationType == .indoor }.count)")
                    print("Outdoor courts: \(locations.filter { $0.locationType == .outdoor }.count)")
                    for location in locations {
                        print("Location: \(location.locationName), Active Players: \(location.locationActivePlayers), Type: \(location.locationType)")
                    }
                    self?.locations = locations
                } catch {
                    print("Failed to decode locations: \(error)")
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("Raw data: \(dataString)")
                    }
                    self?.error = error
                }
            }
        }.resume()
    }
    
    var activeCourts: [Location] {
        let courts = locations.filter { $0.locationActivePlayers > 0 }
        print("Active courts count: \(courts.count)")
        return courts
    }
    
    var inactiveCourts: [Location] {
        let courts = locations.filter { $0.locationActivePlayers == 0 }
        print("Inactive courts count: \(courts.count)")
        return courts
    }
    
    func findCourt(by id: Int) -> Location? {
        locations.first { $0.locationId == id }
    }
    
    func findCourt(by name: String) -> Location? {
        locations.first { $0.locationName == name }
    }
    
    func getGames(for courtId: Int) -> [Game] {
        return activeGames.filter { $0.courtId == courtId }
    }
    
    func joinGame(gameId: UUID) -> Bool {
        guard let index = activeGames.firstIndex(where: { $0.id == gameId }),
              activeGames[index].currentPlayers < activeGames[index].maxPlayers else {
            return false
        }
        activeGames[index].currentPlayers += 1
        return true
    }
    
    // MARK: - Chat Methods
    
    func addMessage(courtId: Int, username: String, message: String, isCurrentUser: Bool = true) {
        let newMessage = CourtChatData(
            courtId: courtId,
            username: username,
            message: message,
            isCurrentUser: isCurrentUser,
            timestamp: Date()
        )
        courtChatMessages.append(newMessage)
        courtChatMessages.sort { $0.timestamp < $1.timestamp }
    }
    
    func getMessages(for courtId: Int) -> [CourtChatData] {
        return courtChatMessages.filter { $0.courtId == courtId }
    }
}
