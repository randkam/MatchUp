import SwiftUI

struct ContentView: View {
    @StateObject private var authCoordinator = AuthenticationCoordinator.shared

    var body: some View {
        Group {
            switch authCoordinator.authState {
            case .authenticated:
                CustomTabView()
            case .unauthenticated:
                AuthenticationView()
            }
        }
    }
}

// NextView is already defined in LoadingView.swift, so we don't need to redefine it here

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
