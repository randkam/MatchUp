import SwiftUI

struct LoginView: View {
    @StateObject private var authCoordinator = AuthenticationCoordinator.shared
    @State private var emailOrUsername = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isAnimating = false
    @State private var showPassword = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Back button
                Button(action: {
                    authCoordinator.showDropIn()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(ModernColorScheme.text)
                        .padding()
                        .background(ModernColorScheme.surface)
                        .clipShape(Circle())
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : -50)
                .animation(.easeOut(duration: 0.8), value: isAnimating)

                // Title
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "basketball.fill")
                            .font(.system(size: 40))
                            .foregroundColor(ModernColorScheme.primary)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)

                        Text("Welcome Back")
                            .font(ModernFontScheme.title)
                            .foregroundColor(ModernColorScheme.text)
                    }

                    Text("Sign in to continue")
                        .font(ModernFontScheme.body)
                        .foregroundColor(ModernColorScheme.textSecondary)
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : -50)
                .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)

                // Input fields
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email or Username")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)

                        TextField("", text: $emailOrUsername)
                            .font(ModernFontScheme.body)
                            .padding()
                            .background(ModernColorScheme.surface)
                            .foregroundColor(ModernColorScheme.text)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ModernColorScheme.primary.opacity(0.3), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Password")
                                .font(ModernFontScheme.caption)
                                .foregroundColor(ModernColorScheme.textSecondary)
                            Spacer()
                            Button("Forgot Password?") {
                                // Implement forgot password
                            }
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.primary)
                        }

                        HStack {
                            if showPassword {
                                TextField("", text: $password)
                                    .font(ModernFontScheme.body)
                                    .foregroundColor(ModernColorScheme.text)
                            } else {
                                SecureField("", text: $password)
                                    .font(ModernFontScheme.body)
                                    .foregroundColor(ModernColorScheme.text)
                            }

                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(ModernColorScheme.textSecondary)
                            }
                        }
                        .padding()
                        .background(ModernColorScheme.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ModernColorScheme.primary.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 50)
                .animation(.easeOut(duration: 0.8).delay(0.4), value: isAnimating)

                // Login button
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ModernColorScheme.primary))
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                } else {
                    Button(action: login) {
                        Text("Sign In")
                            .font(ModernFontScheme.body)
                            .foregroundColor(ModernColorScheme.text)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ModernColorScheme.primary)
                            .cornerRadius(12)
                            .shadow(color: ModernColorScheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.top, 20)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 50)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: isAnimating)
                }

                // Create account
                Button(action: {
                    authCoordinator.showCreateAccount()
                }) {
                    HStack {
                        Text("Don't have an account?")
                            .font(ModernFontScheme.body)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        Text("Sign Up")
                            .font(ModernFontScheme.body)
                            .foregroundColor(ModernColorScheme.primary)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ModernColorScheme.surface)
                    .cornerRadius(12)
                }
                .padding(.top, 10)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 50)
                .animation(.easeOut(duration: 0.8).delay(0.8), value: isAnimating)

                // Social login buttons moved to bottom
                VStack(spacing: 15) {
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(ModernColorScheme.textSecondary.opacity(0.3))
                        Text("or")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(ModernColorScheme.textSecondary.opacity(0.3))
                    }

                    Button(action: { /* Implement Google Sign In */ }) {
                        HStack {
                            Image("google_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            Text("Continue with Google")
                                .font(ModernFontScheme.body)
                        }
                        .foregroundColor(ModernColorScheme.text)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ModernColorScheme.surface)
                        .cornerRadius(12)
                    }

                    Button(action: { /* Implement Apple Sign In */ }) {
                        HStack {
                            Image(systemName: "apple.logo")
                                .font(.title3)
                            Text("Continue with Apple")
                                .font(ModernFontScheme.body)
                        }
                        .foregroundColor(ModernColorScheme.text)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ModernColorScheme.surface)
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 20)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 50)
                .animation(.easeOut(duration: 0.8).delay(1.0), value: isAnimating)

                Spacer(minLength: 20)
            }
            .padding()
        }
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error")
                    .foregroundColor(ModernColorScheme.text),
                message: Text(alertMessage)
                    .foregroundColor(ModernColorScheme.textSecondary),
                dismissButton: .default(Text("OK"))
            )
        }
        .tint(ModernColorScheme.primary)
        .onAppear {
            isAnimating = true
        }
    }

    private func login() {
        guard !emailOrUsername.isEmpty, !password.isEmpty else {
            alertMessage = "Email/Username and Password cannot be empty."
            showAlert = true
            return
        }

        isLoading = true

        let networkManager = NetworkManager()
        networkManager.loginUser(identifier: emailOrUsername, password: password) { success, error in
            isLoading = false
            if success {
                DispatchQueue.main.async {
                    authCoordinator.signIn()
                }
            } else {
                DispatchQueue.main.async {
                    self.alertMessage = error?.localizedDescription ?? "Login failed. Please check your credentials."
                    self.showAlert = true
                }
            }
        }
    }
}
