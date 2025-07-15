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
    @Published var currentPage = 0
    @Published var hasMorePages = true
    
    private let networkManager = NetworkManager()
    private let pageSize = 20
    
    private init() {
        // Initialize with empty data
        fetchLocations()
    }
    
    // MARK: - Location Methods
    
    func fetchLocations(search: String? = nil, isIndoor: Bool? = nil, isLit: Bool? = nil, refresh: Bool = false) {
        if refresh {
            currentPage = 0
            locations = []
            hasMorePages = true
        }
        
        guard hasMorePages else { return }
        isLoading = true
        
        networkManager.getPaginatedLocations(
            page: currentPage,
            size: pageSize,
            search: search,
            isIndoor: isIndoor,
            isLit: isLit
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    if self?.currentPage == 0 {
                        self?.locations = response.content
                    } else {
                        self?.locations.append(contentsOf: response.content)
                    }
                    self?.hasMorePages = !response.last
                    self?.currentPage += 1
                    
                    // Debug logging
                    print("Received \(response.content.count) locations")
                    print("Active courts: \(response.content.filter { $0.locationActivePlayers > 0 }.count)")
                    print("Inactive courts: \(response.content.filter { $0.locationActivePlayers == 0 }.count)")
                    print("Indoor courts: \(response.content.filter { $0.locationType == .indoor }.count)")
                    print("Outdoor courts: \(response.content.filter { $0.locationType == .outdoor }.count)")
                    
                case .failure(let error):
                    print("Failed to fetch locations: \(error)")
                    self?.error = error
                }
            }
        }
    }
    
    func loadMoreIfNeeded(currentItem item: Location) {
        guard !isLoading else { return }
        
        let thresholdIndex = locations.index(locations.endIndex, offsetBy: -5)
        if locations.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            fetchLocations()
        }
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
