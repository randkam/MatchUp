import SwiftUI

struct DropInView: View {
    @StateObject private var authCoordinator = AuthenticationCoordinator.shared
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 30) {
            // Logo placeholder
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 400)
                .padding(.top, 50)
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimating)


//            Spacer()

            // Welcome text with modern styling and animation
//            VStack(alignment: .leading, spacing: 5) {
//                Text("Need runs?")
//                    .font(.system(size: 45, weight: .bold))
//                    .foregroundColor(ModernColorScheme.text)
//                    .opacity(isAnimating ? 1 : 0)
//                    .offset(x: isAnimating ? 0 : -50)
//                    .animation(.easeOut(duration: 0.8), value: isAnimating)
//
//                Text("MatchUp.")
//                    .font(.system(size: 45, weight: .bold))
//                    .foregroundColor(ModernColorScheme.primary)
//                    .opacity(isAnimating ? 1 : 0)
//                    .offset(x: isAnimating ? 0 : -50)
//                    .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)
//            }
//            .padding(.bottom, 30)
//            .frame(maxWidth: .infinity, alignment: .leading)

//            Spacer()

            // Modern styled buttons
            VStack(spacing: 20) {
                Button(action: {
                    withAnimation {
                        print("Sign in via Email button pressed")
                        authCoordinator.showLogin()
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(ModernColorScheme.text)
                        Text("Sign in")
                            .font(ModernFontScheme.body)
                            .foregroundColor(ModernColorScheme.text)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ModernColorScheme.primary)
                    .cornerRadius(15)
                    .shadow(color: ModernColorScheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                }

                Text("OR")
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.textSecondary)
                    .padding(.vertical, 5)

                Button(action: {
                    withAnimation {
                        print("Create an Account button pressed")
                        authCoordinator.showCreateAccount()
                    }
                }) {
                    HStack {
                        Image(systemName: "person.fill.badge.plus")
                            .foregroundColor(ModernColorScheme.text)
                        Text("Create an Account")
                            .font(ModernFontScheme.body)
                            .foregroundColor(ModernColorScheme.text)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ModernColorScheme.secondary)
                    .cornerRadius(15)
                    .shadow(color: ModernColorScheme.secondary.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 50)
            .animation(.easeOut(duration: 0.8).delay(0.6), value: isAnimating)

            // Footer with modern styling
            Text("By continuing, you agree to the Terms and Conditions")
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.8), value: isAnimating)
        }
        .padding()
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        .onAppear {
            isAnimating = true
        }
    }
}
