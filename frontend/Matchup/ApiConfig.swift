import Foundation

struct APIConfig {
    //  static let baseAPI = "https://matchup-api.xyz"
   static let baseAPI = "http://localhost:9095"
    
    // Determine if we're using local or remot  e environment
    private static var isLocal: Bool {
        return baseAPI.contains("localhost")
    }
    
    // API endpoints
    static let usersEndpoint = "\(baseAPI)/api/v1/users"
    static let locationsEndpoint = "\(baseAPI)/api/v1/locations"
    static let messagesEndpoint = "\(baseAPI)/api/messages"
    static let userLocationsEndpoint = "\(baseAPI)/api/user-locations"
    static let reviewsEndpoint = "\(baseAPI)/api/reviews"
    static let tournamentsEndpoint = "\(baseAPI)/api/v1/tournaments"
    static let upcomingTournamentsEndpoint = "\(tournamentsEndpoint)/upcoming"
    static let teamsEndpoint = "\(baseAPI)/api/v1/teams"
    static let userSearchEndpoint = "\(usersEndpoint)/search"
    static func tournamentRegistrationsEndpoint(tournamentId: Int) -> String { "\(tournamentsEndpoint)/\(tournamentId)/registrations" }
    static func tournamentRegistrationsExpandedEndpoint(tournamentId: Int) -> String { "\(tournamentsEndpoint)/\(tournamentId)/registrations/expanded" }
    static func tournamentEligibilityEndpoint(tournamentId: Int, userId: Int) -> String { "\(tournamentsEndpoint)/\(tournamentId)/eligibility?user_id=\(userId)" }
    static func tournamentBracketEndpoint(tournamentId: Int) -> String { "\(tournamentsEndpoint)/\(tournamentId)/bracket" }
    static func tournamentGenerateBracketEndpoint(tournamentId: Int, shuffle: Bool, requestingUserId: Int) -> String {
        "\(tournamentsEndpoint)/\(tournamentId)/bracket/generate?shuffle=\(shuffle)&requesting_user_id=\(requestingUserId)"
    }
    static func tournamentMatchScoreEndpoint(tournamentId: Int, matchId: Int, requestingUserId: Int) -> String {
        "\(tournamentsEndpoint)/\(tournamentId)/matches/\(matchId)/score?requesting_user_id=\(requestingUserId)"
    }
    static func activitiesEndpoint(userId: Int) -> String { "\(baseAPI)/api/v1/activities/user/\(userId)" }
    static func teamUpcomingTournamentsEndpoint(teamId: Int) -> String { "\(tournamentsEndpoint)/teams/\(teamId)/upcoming" }
    static func teamPastTournamentsEndpoint(teamId: Int) -> String { "\(tournamentsEndpoint)/teams/\(teamId)/past" }
    static func teamTournamentStatsEndpoint(teamId: Int) -> String { "\(teamsEndpoint)/\(teamId)/tournament-stats" }
    
    
    // WebSocket configuration
    private static let wsHost = isLocal ? "localhost" : "matchup-api.xyz"
    private static let wsPort = isLocal ? 9095 : nil
    private static let wsProtocol = isLocal ? "ws" : "wss"
    
    static let wsBase: String = {
        if let port = wsPort {
            return "\(wsProtocol)://\(wsHost):\(port)"
        } else {
            return "\(wsProtocol)://\(wsHost)"
        }
    }()

    static func wsChatEndpoint(locationId: Int) -> String {
        let url = "\(wsBase)/ws/chat?locationId=\(locationId)"
        print("WebSocket URL: \(url)")  // Debug print
        return url
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

    static func userByIdEndpoint(userId: Int) -> String {
        return "\(usersEndpoint)/id/\(userId)"
    }

    static func locationImagesEndpoint(locationId: Int) -> String {
        return "\(locationsEndpoint)/\(locationId)/images"
    }
} 
