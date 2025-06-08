import SwiftUI

enum AuthenticationState: Equatable {
    case authenticated
    case unauthenticated(AuthenticationScreen)
    
    enum AuthenticationScreen: Equatable {
        case dropIn
        case login
        case createAccount
    }
}

@MainActor
class AuthenticationCoordinator: ObservableObject {
    @Published private(set) var authState: AuthenticationState = .unauthenticated(.dropIn)
    
    static let shared = AuthenticationCoordinator()
    private init() {}
    
    func signIn() {
        authState = .authenticated
    }
    
    func signOut() {
        // Clear user defaults
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        authState = .unauthenticated(.dropIn)
    }
    
    func showLogin() {
        guard case .unauthenticated = authState else { return }
        authState = .unauthenticated(.login)
    }
    
    func showDropIn() {
        guard case .unauthenticated = authState else { return }
        authState = .unauthenticated(.dropIn)
    }
    
    func showCreateAccount() {
        guard case .unauthenticated = authState else { return }
        authState = .unauthenticated(.createAccount)
    }
} 