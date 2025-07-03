import SwiftUI

enum ActiveAlert: Identifiable {
    case logoutConfirmation
    
    var id: Self { self }
}

struct UserSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authCoordinator = AuthenticationCoordinator.shared
    @State private var activeAlert: ActiveAlert?
    @State private var showEditCredentials = false

    @State private var userName = UserDefaults.standard.string(forKey: "loggedInUserName") ?? ""
    @State private var userNickName = UserDefaults.standard.string(forKey: "loggedInUserNickName") ?? ""

    let networkManager = NetworkManager()

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Account")) {
                    Button(action: {
                        showEditCredentials = true
                    }) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(ModernColorScheme.primary)
                            Text("Edit Credentials")
                                .foregroundColor(ModernColorScheme.text)
                        }
                    }

                    Button(action: {
                        activeAlert = .logoutConfirmation
                    }) {
                        HStack {
                            Image(systemName: "arrow.backward.square.fill")
                                .foregroundColor(ModernColorScheme.primary)
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEditCredentials) {
                EditCredentialsView(userName: $userName, userNickName: $userNickName)
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .logoutConfirmation:
                    return Alert(
                        title: Text("Logout"),
                        message: Text("Are you sure you want to logout?"),
                        primaryButton: .destructive(Text("Logout")) {
                            performLogout()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }
    
    private func performLogout() {
        authCoordinator.signOut()
    }
}
