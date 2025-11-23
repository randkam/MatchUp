        import SwiftUI
    import UIKit

    // Define a modern color scheme
    struct ModernColorScheme {
        // Brand colors
        static let primary = Color(red: 0xED/255.0, green: 0x00/255.0, blue: 0x2D/255.0) // #ed002d
        static let background = Color(red: 0x19/255.0, green: 0x19/255.0, blue: 0x26/255.0) // #191926
        static let secondary = Color.white // Secondary is white
        static let accentMinimal = Color(red: 0x00/255.0, green: 0x97/255.0, blue: 0xB2/255.0) // #0097b2 (use sparingly)
        static let brandBlue = Color(red: 0x00/255.0, green: 0x2E/255.0, blue: 0x6D/255.0) // PSG deep blue #002E6D

        // Surfaces and text
        static let surface = Color(red: 0x22/255.0, green: 0x22/255.0, blue: 0x32/255.0) // slightly lighter than bg
        static let text = Color.white
        static let textSecondary = Color.white.opacity(0.7)
    }

    // Define a modern font scheme
    struct ModernFontScheme {
        static let title = Font.custom("Inter", size: 32).weight(.bold)
        static let heading = Font.custom("Inter", size: 24).weight(.semibold)
        static let body = Font.custom("Inter", size: 16)
        static let caption = Font.custom("Inter", size: 14)		    
    }

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
        @StateObject private var authCoordinator = AuthenticationCoordinator.shared

        var body: some Scene {
            WindowGroup {
                Group {
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
                .preferredColorScheme(.dark)
                .accentColor(ModernColorScheme.brandBlue)
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
