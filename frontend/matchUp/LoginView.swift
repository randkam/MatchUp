import SwiftUI

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @Binding var showDropInView: Bool
    @Binding var showLogin: Bool
    @Binding var showCreateAccount: Bool  // Binding for the create account flow

    @State private var emailOrUsername = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button(action: {
                // Back to DropInView
                showLogin = false
                showDropInView = true
            }) {
                Image(systemName: "arrow.left")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
            }

            Text("Login")
                .font(Font.custom("Inter", size: 32))
                .foregroundColor(.white)
                .padding(.top, 50)

            Text("Login to Get Started")
                .font(Font.custom("Inter", size: 14))
                .foregroundColor(.gray)

            // TextField for email or username
            TextField("Email or Username", text: $emailOrUsername)
                .font(Font.custom("Inter", size: 16))
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 1)
                )
                .autocapitalization(.none) // Ensure no auto-capitalization for email

            // SecureField for password
            SecureField("Password", text: $password)
                .font(Font.custom("Inter", size: 16))
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 1)
                )

            if isLoading {
                ProgressView().padding()
            } else {
                Button(action: login) {
                    Text("Login")
                        .foregroundColor(.white)
                        .font(Font.custom("Inter", size: 18))
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 20)
            }

            // Create Account Button
            Button(action: {
                // Show Create Account View
                showCreateAccount = true
                showLogin = false
            }) {
                Text("Create Account")
                    .foregroundColor(.white)
                    .font(Font.custom("Inter", size: 18))
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 10)

            Spacer()
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    isAuthenticated = true
                    showLogin = false
                } else {
                    alertMessage = error?.localizedDescription ?? "Login failed for an unknown reason."
                    showAlert = true
                }
            }
        }
    }
}
