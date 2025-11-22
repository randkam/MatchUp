import SwiftUI

struct CreateAccountView: View {
    @StateObject private var authCoordinator = AuthenticationCoordinator.shared
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isAnimating = false
    
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
                        Text("Create account")
                            .font(.system(size: 48, weight: .bold, design: .default))
                            .foregroundColor(ModernColorScheme.text)
                            .padding(.top, 20)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(x: isAnimating ? 0 : -20)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: isAnimating)
                        
                        // Uber-style input fields - shifted down
                        VStack(spacing: 24) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(ModernColorScheme.textSecondary)
                                
                                TextField("", text: $email)
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
                            
                            // Username field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(ModernColorScheme.textSecondary)
                                
                                TextField("", text: $username)
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
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(ModernColorScheme.textSecondary)
                                
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
                                    
                                    Button(action: { showPassword.toggle() }) {
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
                            
                            // Confirm Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(ModernColorScheme.textSecondary)
                                
                                HStack {
                                    Group {
                                        if showConfirmPassword {
                                            TextField("", text: $confirmPassword)
                                                .font(.system(size: 18, weight: .regular))
                                                .foregroundColor(ModernColorScheme.text)
                                                .tint(ModernColorScheme.primary)
                                        } else {
                                            SecureField("", text: $confirmPassword)
                                                .font(.system(size: 18, weight: .regular))
                                                .foregroundColor(ModernColorScheme.text)
                                                .tint(ModernColorScheme.primary)
                                        }
                                    }
                                    
                                    Button(action: { showConfirmPassword.toggle() }) {
                                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
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
                            Button(action: createAccount) {
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
                        
                        // Terms and Conditions - Uber style (centered)
                        VStack(spacing: 8) {
                            Text("By creating an account, you agree to our")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(ModernColorScheme.textSecondary)
                            
                            HStack(spacing: 4) {
                                Button("Terms of Service") {
                                    // Show terms of service
                                }
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(ModernColorScheme.primary)
                                
                                Text("and")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(ModernColorScheme.textSecondary)
                                
                                Button("Privacy Policy") {
                                    // Show privacy policy
                                }
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(ModernColorScheme.primary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
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
                title: Text("Account Creation"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertMessage == "Account created successfully. Please login." {
                        authCoordinator.showLogin()
                    }
                }
            )
        }
        .tint(ModernColorScheme.primary)
        .onAppear {
            isAnimating = true
        }
    }
    
    private func createAccount() {
        // Validate inputs
        guard !email.isEmpty, !username.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            alertMessage = "All fields are required."
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match."
            showAlert = true
            return
        }
        
        guard password.count >= 8 else {
            alertMessage = "Password must be at least 8 characters long."
            showAlert = true
            return
        }
        
        isLoading = true
        
        let networkManager = NetworkManager()
        networkManager.createAccount(userName: username, userNickName: username, email: email, userId: Int.random(in: 100...999), password: password) { success, error in
            isLoading = false
            if success {
                alertMessage = "Account created successfully. Please login."
                showAlert = true
            } else {
                alertMessage = error?.localizedDescription ?? "An unknown error occurred."
                showAlert = true
            }
        }
    }
}
