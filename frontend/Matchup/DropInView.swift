import SwiftUI

struct DropInView: View {
    @StateObject private var authCoordinator = AuthenticationCoordinator.shared
    @State private var isAnimating = false

    var body: some View {
        VStack {
            Spacer()

            // Title with modern styling and animation
            VStack(alignment: .leading, spacing: -20) {  // Increased negative spacing to bring text lines closer
                Text("Drop")
                    .font(.system(size: 80, weight: .bold))  // Much larger font size
                    .foregroundColor(ModernColorScheme.text)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(x: isAnimating ? 0 : -50)
                    .animation(.easeOut(duration: 0.8), value: isAnimating)

                Text("In The")
                    .font(.system(size: 80, weight: .bold))  // Much larger font size
                    .foregroundColor(ModernColorScheme.text)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(x: isAnimating ? 0 : -50)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)

                Text("6ix")
                    .font(.system(size: 120, weight: .bold))  // Even larger font size
                    .foregroundColor(ModernColorScheme.primary)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(x: isAnimating ? 0 : -50)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: isAnimating)
            }
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            Spacer(minLength: 20)

            // Modern styled buttons
            VStack(spacing: 20) {
                Button(action: {
                    withAnimation {
                        print("Sign in via Email button pressed")
                        authCoordinator.showLogin()
                    }
                }) {
                    Text("Sign in via Email")
                        .font(ModernFontScheme.body)
                        .foregroundColor(ModernColorScheme.text)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ModernColorScheme.primary)
                        .cornerRadius(15)
                        .shadow(color: ModernColorScheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                }

                Text("OR")
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.textSecondary)
                    .padding(.vertical, 10)

                Button(action: {
                    withAnimation {
                        print("Create an Account button pressed")
                        authCoordinator.showCreateAccount()
                    }
                }) {
                    Text("Create an Account")
                        .font(ModernFontScheme.body)
                        .foregroundColor(ModernColorScheme.text)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ModernColorScheme.secondary)
                        .cornerRadius(15)
                        .shadow(color: ModernColorScheme.secondary.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
            .padding(.horizontal)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 50)
            .animation(.easeOut(duration: 0.8).delay(1.0), value: isAnimating)

            Spacer(minLength: 10)

            // Footer with modern styling
            Text("By continuing, you agree to the Terms and Conditions")
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(1.2), value: isAnimating)
        }
        .padding()
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        .onAppear {
            isAnimating = true
        }
    }
}
