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
        ZStack {
            ModernColorScheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Uber-style back button - shifted down
                HStack {
                    Button(action: {
                        authCoordinator.showDropIn()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(ModernColorScheme.text)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)
                    Spacer()
                }
                .opacity(isAnimating ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: isAnimating)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Uber-style large title - shifted down
                        Text("Sign in")
                            .font(.system(size: 48, weight: .bold, design: .default))
                            .foregroundColor(ModernColorScheme.text)
                            .padding(.top, 20)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(x: isAnimating ? 0 : -20)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: isAnimating)

                        // Uber-style input fields - clean with borders
                        VStack(spacing: 24) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email or username")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(ModernColorScheme.textSecondary)
                                
                                TextField("", text: $emailOrUsername)
                                    .font(.system(size: 18, weight: .regular))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .foregroundColor(ModernColorScheme.text)
                                    .tint(ModernColorScheme.primary)
                                    .background(ModernColorScheme.surface)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(ModernColorScheme.textSecondary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .padding(.top, 20)

                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Password")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(ModernColorScheme.textSecondary)
                                    Spacer()
                                    Button("Forgot?") {
                                        // Implement forgot password
                                    }
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(ModernColorScheme.primary)
                                }
                                
                                HStack {
                                    Group {
                                        if showPassword {
                                            TextField("", text: $password)
                                                .font(.system(size: 18, weight: .regular))
                                                .foregroundColor(ModernColorScheme.text)
                                                .tint(ModernColorScheme.primary)
                                        } else {
                                            SecureField("", text: $password)
                                                .font(.system(size: 18, weight: .regular))
                                                .foregroundColor(ModernColorScheme.text)
                                                .tint(ModernColorScheme.primary)
                                        }
                                    }
                                    
                                    Button(action: { 
                                        showPassword.toggle()
                                    }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(ModernColorScheme.textSecondary)
                                    }
                                    .padding(.trailing, 8)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(ModernColorScheme.surface)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(ModernColorScheme.textSecondary.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: isAnimating)

                        // Uber-style large button
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: ModernColorScheme.text))
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(ModernColorScheme.primary)
                            .cornerRadius(8)
                            .padding(.top, 32)
                        } else {
                            Button(action: login) {
                                Text("Continue")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(ModernColorScheme.text)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(ModernColorScheme.primary)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 32)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.3), value: isAnimating)
                        }

                        // Simple sign up link - Uber style
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(ModernColorScheme.textSecondary)
                                Text("Sign up")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(ModernColorScheme.primary)
                            }
                            Spacer()
                        }
                        .padding(.top, 24)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            authCoordinator.showCreateAccount()
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: isAnimating)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error")
                    .foregroundColor(ModernColorScheme.text),
                message: Text(alertMessage)
                    .foregroundColor(ModernColorScheme.textSecondary),
                dismissButton: .default(Text("OK"))
            )
        }
        .tint(ModernColorScheme.brandBlue)
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
