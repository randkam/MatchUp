import SwiftUI

enum ActiveAlert {
    case logout, delete
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
                        activeAlert = .delete
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Delete Account")
                                .foregroundColor(.red)
                        }
                    }

                    Button(action: {
                        activeAlert = .logout
                    }) {
                        HStack {
                            Image(systemName: "arrow.backward.square.fill")
                                .foregroundColor(ModernColorScheme.primary)
                            Text("Log Out")
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
                case .logout:
                    return Alert(
                        title: Text("Logout"),
                        message: Text("Are you sure you want to log out?"),
                        primaryButton: .destructive(Text("Log Out")) {
                            print("Logout confirmed")
                            authCoordinator.signOut()
                            dismiss()
                        },
                        secondaryButton: .cancel()
                    )

                case .delete:
                    return Alert(
                        title: Text("Delete Account"),
                        message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            networkManager.deleteAccount { success in
                                if success {
                                    DispatchQueue.main.async {
                                        authCoordinator.signOut()
                                    }
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }
}

// Conform to Identifiable so `.alert(item:)` works
extension ActiveAlert: Identifiable {
    var id: Int {
        hashValue
    }
}
