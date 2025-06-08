import SwiftUI
import CoreLocation

struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct BasketballSchool: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    var activePlayers: Int
    var usernames: [String]
    let description: String
    let rating: Double
    let openHours: String
    let courtType: String
} 