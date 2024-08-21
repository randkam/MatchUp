import SwiftUI

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showCreateAccount = false

    var body: some View {
        VStack {
            Text("Login")
                .font(.largeTitle)
                .padding()
            
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                Button(action: login) {
                    Text("Login")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
                
                Button(action: {
                    showCreateAccount = true
                }) {
                    Text("Create Account")
                        .foregroundColor(.blue)
                        .padding()
                }
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showCreateAccount) {
            CreateAccountView(isAuthenticated: $isAuthenticated)
        }
    }

    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Email and Password cannot be empty."
            showAlert = true
            return
        }

        isLoading = true

        let networkManager = NetworkManager()
        networkManager.loginUser(email: email, password: password) { success, error in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    isAuthenticated = true
                } else {
                    alertMessage = error?.localizedDescription ?? "Login failed for an unknown reason."
                    showAlert = true
                }
            }
        }
    }
}
