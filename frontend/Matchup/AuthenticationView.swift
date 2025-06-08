import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authCoordinator = AuthenticationCoordinator.shared

    var body: some View {
        switch authCoordinator.authState {
        case .authenticated:
            CustomTabView()
        case .unauthenticated(let screen):
            switch screen {
            case .dropIn:
                DropInView()
            case .login:
                LoginView()
            case .createAccount:
                CreateAccountView()
            }
        }
    }
} 