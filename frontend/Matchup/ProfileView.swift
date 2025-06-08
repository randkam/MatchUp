import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authCoordinator = AuthenticationCoordinator.shared
    @State private var isEditingProfile = false
    @State private var showSettings = false
    @State private var showLogoutAlert = false
    @State private var showFriends = false
    @State private var isAnimating = false

    @State private var userNickName = ""
    @State private var userName = ""
    
    @State private var userRegion = ""
    @State private var userPosition = ""
    let networkManager = NetworkManager()

//    @State private var favoriteCourts = ["Placeholder Court 1", "Placeholder Court 2"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    VStack(spacing: 15) {
                        ZStack {
                            Image("profile_placeholder")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(ModernColorScheme.primary, lineWidth: 3)
                                )

                            Button(action: { isEditingProfile = true }) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(ModernColorScheme.primary)
                                    .background(ModernColorScheme.background)
                                    .clipShape(Circle())
                            }
                            .offset(x: 40, y: 40)
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : -50)
                        .animation(.easeOut(duration: 0.8), value: isAnimating)

                        VStack(spacing: 8) {
                            Text(userNickName)
                                .font(ModernFontScheme.title)
                                .foregroundColor(ModernColorScheme.text)

    

                            HStack(spacing: 20) {
                                VStack(spacing: 6) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(ModernColorScheme.primary)
                                    Text("Region")
                                        .font(ModernFontScheme.caption)
                                        .foregroundColor(ModernColorScheme.textSecondary)
                                    Text(userRegion)
                                        .font(ModernFontScheme.body)
                                        .foregroundColor(ModernColorScheme.text)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(ModernColorScheme.surface)
                                .cornerRadius(15)

                                VStack(spacing: 6) {
                                    Image(systemName: "figure.run")
                                        .foregroundColor(ModernColorScheme.primary)
                                    Text("Position")
                                        .font(ModernFontScheme.caption)
                                        .foregroundColor(ModernColorScheme.textSecondary)
                                    Text(userPosition)
                                        .font(ModernFontScheme.body)
                                        .foregroundColor(ModernColorScheme.text)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(ModernColorScheme.surface)
                                .cornerRadius(15)
                            }
                            .padding(.top, 8)
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : -50)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)
                    }
                    .padding(.top)

                    

                    Button(action: { showSettings = true }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(ModernColorScheme.primary)
                            Text("User Settings")
                                .font(ModernFontScheme.body)
                                .foregroundColor(ModernColorScheme.text)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(ModernColorScheme.textSecondary)
                        }
                        .padding()
                        .background(ModernColorScheme.surface)
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }


//                    Button(action: {}) {
//                        HStack {
//                            Image(systemName: "mappin.and.ellipse")
//                                .foregroundColor(ModernColorScheme.primary)
//                            Text("Favorite Courts")
//                                .font(ModernFontScheme.body)
//                                .foregroundColor(ModernColorScheme.text)
//                            Spacer()
//                            Image(systemName: "chevron.right")
//                                .foregroundColor(ModernColorScheme.textSecondary)
//                        }
//                        .padding()
//                        .background(ModernColorScheme.surface)
//                        .cornerRadius(15)
//                        .padding(.horizontal)
//                    }

                    
                }
                .padding(.bottom)
            }
            .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isEditingProfile) {
                EditCredentialsView(userName: $userName, userNickName: $userNickName)
            }
            .sheet(isPresented: $showSettings) {
                UserSettingsView()
            }
            .onChange(of: authCoordinator.authState) { oldValue, newValue in
                if case .unauthenticated = newValue {
                    dismiss()
                }
            }
            .onAppear {
                isAnimating = true
                userNickName = UserDefaults.standard.string(forKey: "loggedInUserNickName") ?? "Unknown"
                userRegion = UserDefaults.standard.string(forKey: "loggedInUserRegion") ?? "Unknown"
                userPosition = UserDefaults.standard.string(forKey: "loggedInUserPosition") ?? "Unknown"
                userName = UserDefaults.standard.string(forKey: "loggedInUserName") ?? "Unknown"
            }

        }
    }
}




struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ModernColorScheme.primary)

            Text(value)
                .font(ModernFontScheme.heading)
                .foregroundColor(ModernColorScheme.text)

            Text(title)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(15)
    }
}
