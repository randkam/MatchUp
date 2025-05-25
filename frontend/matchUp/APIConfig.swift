import Foundation

struct APIConfig {
    static let baseAPI = "http://18.234.212.218:9095"
    
    // API endpoints
    static let usersEndpoint = "\(baseAPI)/api/v1/users"
    static let locationsEndpoint = "\(baseAPI)/api/v1/locations"
    static let messagesEndpoint = "\(baseAPI)/api/messages"
    static let userLocationsEndpoint = "\(baseAPI)/api/user-locations"
    
    static let wsBase = "ws://18.234.212.218:9095"
    static func wsChatEndpoint(locationId: Int) -> String {
        return "\(wsBase)/ws/chat?locationId=\(locationId)"
    }
} 