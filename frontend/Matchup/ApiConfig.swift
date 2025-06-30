import Foundation

struct APIConfig {
    static let baseAPI = "https://matchup-api.xyz"
    
    // API endpoints
    static let usersEndpoint = "\(baseAPI)/api/v1/users"
    static let locationsEndpoint = "\(baseAPI)/api/v1/locations"
    static let messagesEndpoint = "\(baseAPI)/api/messages"
    static let userLocationsEndpoint = "\(baseAPI)/api/user-locations"
    static let reviewsEndpoint = "\(baseAPI)/api/reviews"
    
    static let wsBase = "wss://matchup-api.xyz"

    static func wsChatEndpoint(locationId: Int) -> String {
        return "\(wsBase)/ws/chat?locationId=\(locationId)"
    }
    
    // Review endpoints
    static func locationReviewsEndpoint(locationId: Int) -> String {
        return "\(reviewsEndpoint)/location/\(locationId)"
    }
    
    static func userReviewsEndpoint(userId: Int) -> String {
        return "\(reviewsEndpoint)/user/\(userId)"
    }
    
    static func checkUserReviewEndpoint(locationId: Int, userId: Int) -> String {
        return "\(reviewsEndpoint)/check/\(locationId)/\(userId)"
    }
    
    static func averageRatingEndpoint(locationId: Int) -> String {
        return "\(reviewsEndpoint)/average/\(locationId)"
    }
} 
