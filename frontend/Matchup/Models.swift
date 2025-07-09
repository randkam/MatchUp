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
    let locationId: Int
    let locationName: String
    let locationAddress: String
    let locationZipCode: String
    let locationActivePlayers: Int
    let locationReviews: String
    let isLitAtNight: Bool?
    var locationType: LocationType?
    
    var id: Int { locationId }
    
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

// Model for creating a new review
struct CreateReviewRequest: Codable {
    let locationId: Int
    let userId: Int
    let rating: Float
    let comment: String?
    
    enum CodingKeys: String, CodingKey {
        case locationId = "location_id"
        case userId = "user_id"
        case rating
        case comment
    }
}

// Model for handling the server's response when creating a review
struct ReviewResponse: Codable {
    let id: Int?
    let locationId: Int
    let userId: Int
    let rating: Float
    let comment: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case locationId = "location_id"
        case userId = "user_id"
        case rating
        case comment
        case createdAt = "created_at"
    }
    
    // Convert ReviewResponse to Review
    func toReview() -> Review? {
        guard let id = id else { return nil }
        
        let date: Date
        if let createdAtString = createdAt,
           let parsedDate = ISO8601DateFormatter().date(from: createdAtString) {
            date = parsedDate
        } else {
            date = Date()
        }
        
        return Review(
            id: id,
            locationId: locationId,
            userId: userId,
            rating: rating,
            comment: comment,
            createdAt: date
        )
    }
}

struct Review: Codable, Identifiable {
    let id: Int
    let locationId: Int
    let userId: Int
    let rating: Float
    let comment: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case locationId = "location_id"
        case userId = "user_id"
        case rating
        case comment
        case createdAt = "created_at"
    }
    
    init(id: Int, locationId: Int, userId: Int, rating: Float, comment: String?, createdAt: Date) {
        self.id = id
        self.locationId = locationId
        self.userId = userId
        self.rating = rating
        self.comment = comment
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        locationId = try container.decode(Int.self, forKey: .locationId)
        userId = try container.decode(Int.self, forKey: .userId)
        rating = try container.decode(Float.self, forKey: .rating)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        
        // Handle the date decoding
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                createdAt = Date() // Fallback to current date if parsing fails
            }
        } else {
            createdAt = Date() // Fallback to current date if no date provided
        }
    }
}

// Feedback Models
struct FeedbackItem: Identifiable, Codable {
    let id: Int
    let userId: Int
    let type: FeedbackType
    let title: String
    let description: String
    let status: FeedbackStatus
    let createdAt: String
    
    var formattedDate: String {
        // Convert createdAt string to formatted date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = dateFormatter.date(from: createdAt) else { return createdAt }
        
        dateFormatter.dateFormat = "MMM d, yyyy"
        return dateFormatter.string(from: date)
    }
}

enum FeedbackType: String, Codable {
    case newLocation = "NEW_LOCATION"
    case locationUpdate = "LOCATION_UPDATE"
    case appConcern = "APP_CONCERN"
    case generalFeedback = "GENERAL_FEEDBACK"
}

enum FeedbackStatus: String, Codable {
    case pending = "PENDING"
    case inReview = "IN_REVIEW"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case resolved = "RESOLVED"
} 
