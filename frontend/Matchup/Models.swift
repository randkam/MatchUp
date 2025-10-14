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

// MARK: - Tournaments
enum TournamentStatus: String, Codable {
    case draft = "DRAFT"
    case signupsOpen = "SIGNUPS_OPEN"
    case full = "FULL"
    case locked = "LOCKED"
    case live = "LIVE"
    case complete = "COMPLETE"
}

struct Tournament: Identifiable, Codable {
    let id: Int
    let name: String
    let formatSize: Int
    let maxTeams: Int
    let entryFeeCents: Int?
    let depositHoldCents: Int?
    let currency: String?
    let prizeCents: Int?
    let signupDeadline: Date
    let startsAt: Date
    let endsAt: Date?
    let location: String?
    let status: TournamentStatus
    let createdBy: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case formatSize = "format_size"
        case maxTeams = "max_teams"
        case entryFeeCents = "entry_fee_cents"
        case depositHoldCents = "deposit_hold_cents"
        case currency
        case prizeCents = "prize_cents"
        case signupDeadline = "signup_deadline"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case location
        case status
        case createdBy = "created_by"
    }
}

// Tournament match models
struct TournamentMatchModel: Identifiable, Codable {
    let id: Int
    let tournamentId: Int
    let roundNumber: Int
    let matchNumber: Int
    let teamAId: Int?
    let teamBId: Int?
    let scoreA: Int?
    let scoreB: Int?
    let winnerTeamId: Int?
    let status: String
    let scheduledAt: String?
    let nextMatchId: Int?
    let nextMatchSlot: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId = "tournament_id"
        case roundNumber = "round_number"
        case matchNumber = "match_number"
        case teamAId = "team_a_id"
        case teamBId = "team_b_id"
        case scoreA = "score_a"
        case scoreB = "score_b"
        case winnerTeamId = "winner_team_id"
        case status
        case scheduledAt = "scheduled_at"
        case nextMatchId = "next_match_id"
        case nextMatchSlot = "next_match_slot"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct TournamentRegistrationModel: Identifiable, Codable {
    let id: Int
    let tournamentId: Int
    let teamId: Int
    let status: String
    let seed: Int?
    let checkedIn: Bool
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId = "tournament_id"
        case teamId = "team_id"
        case status
        case seed
        case checkedIn = "checked_in"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct TournamentRegistrationExpandedModel: Identifiable, Codable {
    let id: Int
    let teamId: Int
    let teamName: String
    let seed: Int
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case teamName = "team_name"
        case seed
        case createdAt = "created_at"
    }
}

// MARK: - Teams
struct TeamModel: Identifiable, Codable {
    let id: Int
    let name: String
    let sport: String
    let ownerUserId: Int
    let logoUrl: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sport
        case ownerUserId = "owner_user_id"
        case logoUrl = "logo_url"
        case createdAt = "created_at"
    }
}

struct TeamMemberModel: Identifiable, Codable {
    let id: Int
    let teamId: Int
    let userId: Int
    let role: String
    let joinedAt: String?
    let username: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
        case username
    }
}

struct TeamInviteModel: Identifiable, Codable {
    let id: Int
    let teamId: Int
    let inviteeUserId: Int
    let status: String
    let token: String?
    let expiresAt: String?
    let createdAt: String?
    let teamName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case inviteeUserId = "invitee_user_id"
        case status
        case token
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case teamName = "team_name"
    }
}

struct UserStatsModel: Codable {
    let userId: Int
    let sport: String
    let matchWins: Int
    let matchLosses: Int
    let titles: Int
    let lastUpdated: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case sport
        case matchWins = "match_wins"
        case matchLosses = "match_losses"
        case titles
        case lastUpdated = "last_updated"
    }
}

struct Location: Identifiable, Codable {
    let locationId: Int
    let locationName: String
    let locationAddress: String
    let locationZipCode: String
    let locationActivePlayers: Int
    let isLitAtNight: Bool?
    var locationType: LocationType?
    let locationLatitude: Double?
    let locationLongitude: Double?
    
    var id: Int { locationId }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = locationLatitude,
              let lon = locationLongitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    enum CodingKeys: String, CodingKey {
        case locationId = "id"
        case locationName = "name"
        case locationAddress = "address"
        case locationZipCode = "zip_code"
        case locationActivePlayers = "active_players"
        case isLitAtNight = "is_lit_at_night"
        case locationType = "type"
        case locationLatitude = "latitude"
        case locationLongitude = "longitude"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        locationId = try container.decode(Int.self, forKey: .locationId)
        locationName = try container.decode(String.self, forKey: .locationName)
        locationAddress = try container.decode(String.self, forKey: .locationAddress)
        locationZipCode = try container.decode(String.self, forKey: .locationZipCode)
        locationActivePlayers = try container.decode(Int.self, forKey: .locationActivePlayers)
        isLitAtNight = try container.decodeIfPresent(Bool.self, forKey: .isLitAtNight)
        locationType = try container.decodeIfPresent(LocationType.self, forKey: .locationType)
        locationLatitude = try container.decodeIfPresent(Double.self, forKey: .locationLatitude)
        locationLongitude = try container.decodeIfPresent(Double.self, forKey: .locationLongitude)
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
        
        // Try to decode comment, handle null or empty string
        if let commentString = try container.decodeIfPresent(String.self, forKey: .comment),
           !commentString.isEmpty {
            comment = commentString
        } else {
            comment = nil
        }
        
        // Handle the date decoding
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                // Try alternative date format
                let backupFormatter = DateFormatter()
                backupFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                if let date = backupFormatter.date(from: dateString) {
                    createdAt = date
                } else {
                    createdAt = Date() // Fallback to current date if parsing fails
                }
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

struct MessageGroup: Identifiable {
    let id: String
    let date: Date
    var messages: [ChatMessage]
    
    static func groupMessages(_ messages: [ChatMessage]) -> [MessageGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: messages) { message in
            calendar.startOfDay(for: message.timestamp)
        }
        
        return grouped.map { (date, messages) in
            MessageGroup(id: date.ISO8601Format(), date: date, messages: messages.sorted(by: { $0.timestamp < $1.timestamp }))
        }.sorted(by: { $0.date < $1.date })
    }
    
    var dateHeader: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Full day name
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
} 
