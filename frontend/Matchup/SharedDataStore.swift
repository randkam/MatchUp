import SwiftUI
import CoreLocation
import Combine

// Court chat message model for the shared data store
struct CourtChatData: Identifiable, Equatable {
    let id = UUID()
    let courtId: UUID  // The ID of the court this message belongs to
    let username: String
    let message: String
    let isCurrentUser: Bool
    let timestamp: Date
}

// Game model for the shared data store
struct Game: Identifiable {
    let id = UUID()
    let courtId: UUID  // The ID of the court this game is at
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
    
    // Published properties for chat and games
    @Published var courtChatMessages: [CourtChatData] = []
    @Published var activeGames: [Game] = []
    
    // MARK: - Chat Methods
    
    // Add a new message to a specific court's chat
    func addMessage(courtId: UUID, username: String, message: String, isCurrentUser: Bool = true) {
        let newMessage = CourtChatData(
            courtId: courtId,
            username: username,
            message: message,
            isCurrentUser: isCurrentUser,
            timestamp: Date()
        )
        courtChatMessages.append(newMessage)
        
        // Sort messages by timestamp to ensure chronological order
        courtChatMessages.sort { $0.timestamp < $1.timestamp }
    }
    
    // Get all messages for a specific court
    func getMessages(for courtId: UUID) -> [CourtChatData] {
        return courtChatMessages.filter { $0.courtId == courtId }
    }
    
    // MARK: - Game Methods
    
    // Create a new game at a specific court
    func createGame(courtId: UUID, title: String, type: String, maxPlayers: Int, date: Date, skill: String, creator: String) -> Game {
        let newGame = Game(
            courtId: courtId,
            title: title,
            type: type,
            maxPlayers: maxPlayers,
            currentPlayers: 1, // Creator is the first player
            date: date,
            skill: skill,
            creator: creator
        )
        activeGames.append(newGame)
        return newGame
    }
    
    // Get all games for a specific court
    func getGames(for courtId: UUID) -> [Game] {
        return activeGames.filter { $0.courtId == courtId }
    }
    
    // Join a game (increment player count)
    func joinGame(gameId: UUID, username: String) -> Bool {
        if let index = activeGames.firstIndex(where: { $0.id == gameId }) {
            // Check if the game is not full
            if activeGames[index].currentPlayers < activeGames[index].maxPlayers {
                activeGames[index].currentPlayers += 1
                return true
            }
        }
        return false
    }
    
    @Published var basketballCourts: [BasketballSchool] = [
        BasketballSchool(
            name: "Dr Norman Bethune Collegiate Institute", 
            coordinate: CLLocationCoordinate2D(latitude: 43.8016, longitude: -79.3181), 
            activePlayers: 5, 
            usernames: ["player1", "player2", "player3"],
            description: "Outdoor court with 2 hoops, freshly painted lines, and good lighting for evening games.",
            rating: 4.7,
            openHours: "6:00 AM - 10:00 PM",
            courtType: "Full court with bleachers"
        ),
        BasketballSchool(
            name: "Lester B. Pearson Collegiate Institute", 
            coordinate: CLLocationCoordinate2D(latitude: 43.8035, longitude: -79.2256), 
            activePlayers: 0, // Made inactive for testing
            usernames: [],
            description: "Indoor gymnasium with 6 hoops, perfect for rainy days and competitive games.",
            rating: 4.5,
            openHours: "7:00 AM - 9:00 PM",
            courtType: "Indoor full court"
        ),
        BasketballSchool(
            name: "Maplewood High School", 
            coordinate: CLLocationCoordinate2D(latitude: 43.7694, longitude: -79.1927), 
            activePlayers: 2, 
            usernames: ["playerX", "playerY"],
            description: "Outdoor court with 4 hoops, popular spot for weekend pickup games and tournaments.",
            rating: 4.2,
            openHours: "8:00 AM - 8:00 PM",
            courtType: "Two half courts"
        ),
        BasketballSchool(
            name: "George B Little Public School", 
            coordinate: CLLocationCoordinate2D(latitude: 43.7654, longitude: -79.2154), 
            activePlayers: 0, // Made inactive for testing
            usernames: [],
            description: "Small but well-maintained court, great for beginners and casual players.",
            rating: 4.0,
            openHours: "7:00 AM - 7:00 PM",
            courtType: "Half court"
        ),
        BasketballSchool(
            name: "David and Mary Thomson Collegiate Institute", 
            coordinate: CLLocationCoordinate2D(latitude: 43.7506, longitude: -79.2707), 
            activePlayers: 0, // Made inactive for testing
            usernames: [],
            description: "Recently renovated court with new backboards and nets, excellent playing surface.",
            rating: 4.8,
            openHours: "6:00 AM - 9:00 PM",
            courtType: "Full court with lights"
        ),
        BasketballSchool(
            name: "Newtonbrook Secondary School", 
            coordinate: CLLocationCoordinate2D(latitude: 43.7981, longitude: -79.4198), 
            activePlayers: 6, 
            usernames: ["playerF", "playerG"],
            description: "Large outdoor court that hosts local tournaments, with water fountains nearby.",
            rating: 4.6,
            openHours: "7:00 AM - 10:00 PM",
            courtType: "Full court with spectator area"
        ),
        BasketballSchool(
            name: "Georges Vanier Secondary School", 
            coordinate: CLLocationCoordinate2D(latitude: 43.7772, longitude: -79.3464), 
            activePlayers: 3, 
            usernames: ["playerH", "playerI"],
            description: "Covered outdoor court, perfect for playing in light rain or hot sunny days.",
            rating: 4.4,
            openHours: "8:00 AM - 8:00 PM",
            courtType: "Covered full court"
        ),
        BasketballSchool(
            name: "Northview Heights Secondary School", 
            coordinate: CLLocationCoordinate2D(latitude: 43.7808, longitude: -79.4391), 
            activePlayers: 0, // Made inactive for testing
            usernames: [],
            description: "Multiple courts with varying skill levels, from beginner to advanced players.",
            rating: 4.3,
            openHours: "6:30 AM - 9:30 PM",
            courtType: "Multiple courts (3)"
        ),
        BasketballSchool(
            name: "Earl Haig Secondary School", 
            coordinate: CLLocationCoordinate2D(latitude: 43.7663, longitude: -79.4018), 
            activePlayers: 7, 
            usernames: ["playerL", "playerM"],
            description: "Popular spot for competitive players, with regular weekend tournaments.",
            rating: 4.9,
            openHours: "7:00 AM - 11:00 PM",
            courtType: "Professional full court"
        ),
        BasketballSchool(
            name: "Albert Campbell Collegiate Institute", 
            coordinate: CLLocationCoordinate2D(latitude: 43.7774, longitude: -79.2551), 
            activePlayers: 4, 
            usernames: ["playerN", "playerO"],
            description: "Well-maintained court with good lighting for evening games.",
            rating: 4.1,
            openHours: "7:00 AM - 9:00 PM",
            courtType: "Full court"
        )
    ]
    
    // Notification handler for court join events
    init() {
        setupNotificationHandlers()
    }
    
    private func setupNotificationHandlers() {
        // Set up notification observer for court join events
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("JoinCourt"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let courtId = notification.userInfo?["courtId"] as? UUID {
                // Find the court and update its player count
                if let index = self.basketballCourts.firstIndex(where: { $0.id == courtId }) {
                    self.basketballCourts[index].activePlayers += 1
                    if self.basketballCourts[index].usernames.isEmpty {
                        // Add a default username for the current user
                        self.basketballCourts[index].usernames = ["You"]
                    } else {
                        // Add the current user to the existing usernames
                        self.basketballCourts[index].usernames.append("You")
                    }
                    
                    // Provide haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Print confirmation
                    print("Successfully joined court: " + self.basketballCourts[index].name)
                }
            }
        }
    }
    
    // Get active courts
    var activeCourts: [BasketballSchool] {
        basketballCourts.filter { $0.activePlayers > 0 }
    }
    
    // Get inactive courts
    var inactiveCourts: [BasketballSchool] {
        basketballCourts.filter { $0.activePlayers == 0 }
    }
    
    // Find a court by ID
    func findCourt(by id: UUID) -> BasketballSchool? {
        basketballCourts.first { $0.id == id }
    }
    
    // Find a court by name
    func findCourt(by name: String) -> BasketballSchool? {
        basketballCourts.first { $0.name == name }
    }
    
    // Join a court (increase player count)
    func joinCourt(id: UUID) {
        if let index = basketballCourts.firstIndex(where: { $0.id == id }) {
            basketballCourts[index].activePlayers += 1
            if basketballCourts[index].usernames.isEmpty {
                basketballCourts[index].usernames = ["You"]
            } else {
                basketballCourts[index].usernames.append("You")
            }
        }
    }
}
