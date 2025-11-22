import SwiftUI

struct DropInView: View {
    @StateObject private var authCoordinator = AuthenticationCoordinator.shared
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.7
    @State private var showContent: Bool = false
    @State private var taglineOpacity: Double = 0
    @State private var logoPulse: CGFloat = 1.0
    @State private var logoPosition: LogoPosition = .center
    @State private var logoSize: CGFloat = 200
    
    enum LogoPosition {
        case center
        case top
    }

    var body: some View {
        ZStack {
            ModernColorScheme.background
                .ignoresSafeArea()
            
            // Logo - single view that transitions from center to top
            GeometryReader { geometry in
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoSize, height: logoSize)
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale * logoPulse)
                    .animation(.easeOut(duration: 0.8), value: logoOpacity)
                    .animation(.easeInOut(duration: 0.8), value: logoScale)
                    .animation(.easeInOut(duration: 1.2), value: logoPulse)
                    .animation(.easeInOut(duration: 0.8), value: logoSize)
                    .position(
                        x: geometry.size.width / 2,
                        y: logoPosition == .top ? 100 : geometry.size.height / 2
                    )
                    .animation(.easeInOut(duration: 0.8), value: logoPosition)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                // Spacer for logo at top
                if logoPosition == .top {
                    Spacer()
                        .frame(height: 180)
                }
                
                // Large left-aligned text - centered vertically, takes most of screen
                if showContent {
                    Spacer()
                        .frame(height: 40)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Drop In")
                            .font(.system(size: 95, weight: .bold, design: .default))
                            .foregroundColor(ModernColorScheme.text)
                            .opacity(taglineOpacity)
                            .offset(x: taglineOpacity == 1 ? 0 : -20)
                            .animation(.easeOut(duration: 0.6), value: taglineOpacity)
                        
                        Text("The 6ix")
                            .font(.system(size: 95, weight: .bold, design: .default))
                            .foregroundColor(ModernColorScheme.text)
                            .padding(.top, 4)
                            .opacity(taglineOpacity)
                            .offset(x: taglineOpacity == 1 ? 0 : -20)
                            .animation(.easeOut(duration: 0.6).delay(0.1), value: taglineOpacity)
                        
                        Text("Find Your Next Game")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(ModernColorScheme.textSecondary.opacity(0.8))
                            .padding(.top, 28)
                            .padding(.leading, 8)
                            .opacity(taglineOpacity)
                            .offset(x: taglineOpacity == 1 ? 0 : -20)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: taglineOpacity)
                    }
                    .padding(.leading, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                // Uber-style buttons - appear after animation
                if showContent {
                    VStack(spacing: 0) {
                        // Primary button - large and bold
                        Button(action: {
                            authCoordinator.showCreateAccount()
                        }) {
                            Text("Get started")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(ModernColorScheme.text)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(ModernColorScheme.primary)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: showContent)
                        
                        // Secondary button - clean and minimal
                        Button(action: {
                            authCoordinator.showLogin()
                        }) {
                            Text("Sign in")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(ModernColorScheme.text)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.clear)
                        }
                        .padding(.horizontal, 24)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: showContent)
                    }
                    .padding(.bottom, 50)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onAppear {
            // Phase 1: Logo fades in and scales up in center (0.6s)
            withAnimation(.easeOut(duration: 0.6)) {
                logoOpacity = 1.0
                logoScale = 1.0
            }
            
            // Phase 2: Obvious fade in/out animation (starts at 0.8s, runs for ~1.5s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                // Fade out
                withAnimation(.easeInOut(duration: 0.5)) {
                    logoOpacity = 0.3
                }
                // Fade in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        logoOpacity = 1.0
                    }
                }
                // Fade out again
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        logoOpacity = 0.3
                    }
                }
                // Fade in again
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        logoOpacity = 1.0
                    }
                }
            }
            
            // Phase 3: After ~2.5 seconds, transition logo to top and show content
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                // Animate logo to top center (bigger size at top)
                withAnimation(.easeInOut(duration: 0.8)) {
                    logoPulse = 1.0
                    logoScale = 0.6  // Scale down to 120px (200 * 0.6)
                    logoSize = 120
                    logoPosition = .top
                    logoOpacity = 1.0
                }
                
                // Show content after logo transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showContent = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.6)) {
                            taglineOpacity = 1.0
                        }
                    }
                }
            }
        }
    }
}
