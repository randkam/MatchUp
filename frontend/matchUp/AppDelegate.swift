import SwiftUI
import UIKit

// Define the AppDelegatex  
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Perform any final initialization of your application.
        return true
    }
}

// Define the SwiftUI App
@main
struct matchUp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var showLoadingScreen = true
    @State private var isAuthenticated = false
    @State private var showDropInView = true  // Show DropInView first
    @State private var showLogin = false      // Initially hide LoginView
    @State private var showCreateAccount = false  // New state for handling create account view

    var body: some Scene {
        WindowGroup {
            if showLoadingScreen {
                LoadingScreenView()
                    .onAppear {
                        // Delay the loading screen for 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showLoadingScreen = false
                        }
                    }
            } else if !isAuthenticated && showLogin {
                // Show the LoginView when `showLogin` is true and the user is not authenticated
                LoginView(isAuthenticated: $isAuthenticated,
                          showDropInView: $showDropInView,
                          showLogin: $showLogin,
                          showCreateAccount: $showCreateAccount)  // Pass showCreateAccount binding
            } else if showDropInView {
                // Show DropInView when the flag is set to true
                DropInView(
                           showDropInView: $showDropInView,
                           showLogin: $showLogin,
                           showCreateAccount: $showCreateAccount)  // Pass showCreateAccount if needed
            } else {
                // If the user is authenticated, show the main content
                CustomTabView(isAuthenticated: $isAuthenticated)
            }
        }
    }
}
