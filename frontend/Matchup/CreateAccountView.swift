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
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Back button
                Button(action: {
                    withAnimation {
                        authCoordinator.showDropIn()
                    }
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
                
                // Title section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(ModernColorScheme.primary)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
                        
                        Text("Create Account")
                            .font(ModernFontScheme.title)
                            .foregroundColor(ModernColorScheme.text)
                    }
                    
                    Text("Join our basketball community")
                        .font(ModernFontScheme.body)
                        .foregroundColor(ModernColorScheme.textSecondary)
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : -50)
                .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)
                
                // Input fields
                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        
                        TextField("", text: $email)
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
                    
                    // Username field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        
                        TextField("", text: $username)
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
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        
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
                    
                    // Confirm Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        
                        HStack {
                            if showConfirmPassword {
                                TextField("", text: $confirmPassword)
                                    .font(ModernFontScheme.body)
                                    .foregroundColor(ModernColorScheme.text)
                            } else {
                                SecureField("", text: $confirmPassword)
                                    .font(ModernFontScheme.body)
                                    .foregroundColor(ModernColorScheme.text)
                            }
                            
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
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
                
                // Create Account button
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ModernColorScheme.primary))
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                } else {
                    Button(action: createAccount) {
                        Text("Create Account")
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
                
                // Terms and Conditions
                VStack(spacing: 10) {
                    Text("By creating an account, you agree to our")
                        .font(ModernFontScheme.caption)
                        .foregroundColor(ModernColorScheme.textSecondary)
                    
                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            // Show terms of service
                        }
                        .font(ModernFontScheme.caption)
                        .foregroundColor(ModernColorScheme.primary)
                        
                        Text("and")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        
                        Button("Privacy Policy") {
                            // Show privacy policy
                        }
                        .font(ModernFontScheme.caption)
                        .foregroundColor(ModernColorScheme.primary)
                    }
                }
                .padding(.top, 10)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 50)
                .animation(.easeOut(duration: 0.8).delay(0.8), value: isAnimating)
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
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
