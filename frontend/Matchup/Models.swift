import SwiftUI
import CoreLocation

struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

enum LocationType: String, Codable {
    case indoor = "INDOOR"
    case outdoor = "OUTDOOR"
}

struct Location: Identifiable, Codable {
    var id: Int{ locationId }
    var locationId: Int  // Changed to Int64 to match backend's Long type
    var locationName: String
    var locationAddress: String
    var locationZipCode: String
    var locationActivePlayers: Int
    var locationReviews: String?  // Added to match backend, optional since it might be null
    let locationType: LocationType?  // Made optional since existing locations might not have it set
    
    var coordinate: CLLocationCoordinate2D? {
        // Optional coordinate if needed later
        nil
    }
}

struct Chat: Identifiable {
    let id: Int
    let name: String
}

//struct Game: Identifiable {
//    let id: UUID
//    let courtId: Int
//    let title: String
//    let type: String
//    let maxPlayers: Int
//    var currentPlayers: Int
//    let date: Date
//    let skill: String
//    let creator: String
//}

//struct CourtChatData: Identifiable, Equatable {
//    let id = UUID()
//    let courtId: Int
//    let username: String
//    let message: String
//    let isCurrentUser: Bool
//    let timestamp: Date
//}

//struct BasketballSchool: Identifiable {
//    let id = UUID()
//    let name: String
//    let coordinate: CLLocationCoordinate2D
//    var activePlayers: Int
//    var usernames: [String]
//    let description: String
//    let rating: Double
//    let openHours: String
//    let courtType: String
//} 
