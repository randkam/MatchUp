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
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var profileImageUrl: String?
    @State private var showEditCredentials = false
    @State private var showFeedbackForm = false

    @State private var userNickName: String = ""
    @State private var userName: String = ""
    @State private var userRegion: String = ""
    @State private var userPosition: String = ""
    @State private var matchWins: Int = 0
    @State private var matchLosses: Int = 0
    @State private var titles: Int = 0
    let networkManager = NetworkManager()
    private let cardHeight: CGFloat = 80

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    ZStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(ModernColorScheme.primary, lineWidth: 3)
                                )
                        } else if let imageUrl = profileImageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(ModernColorScheme.primary, lineWidth: 3)
                                        )
                                case .failure(_):
                                    defaultProfileImage
                                case .empty:
                                    defaultProfileImage
                                @unknown default:
                                    defaultProfileImage
                                }
                            }
                        } else {
                            defaultProfileImage
                        }

                        Button(action: { showImagePicker = true }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(ModernColorScheme.primary)
                                .background(ModernColorScheme.background)
                                .clipShape(Circle())
                        }
                        .offset(x: 40, y: 40)
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? -24 : -70)
                    .animation(.easeOut(duration: 0.8), value: isAnimating)

                    VStack(spacing: 6) {
                        Text(userNickName)
                            .font(ModernFontScheme.title)
                            .foregroundColor(ModernColorScheme.text)

                        // Region & Position (side by side, no boxes)
                        HStack(spacing: 1) {
                            HStack(spacing: 8) {
                                Image(systemName: "location.fill").foregroundColor(ModernColorScheme.primary)
                                Text(userRegion)
                                    .font(ModernFontScheme.body)
                                    .foregroundColor(ModernColorScheme.text)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)

                            HStack(spacing: 8) {
                                Image(systemName: "figure.run").foregroundColor(ModernColorScheme.primary)
                                Text(userPosition)
                                    .font(ModernFontScheme.body)
                                    .foregroundColor(ModernColorScheme.text)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.top, 0)
                        .padding(.horizontal, 16)

                        // Stats in one row
                        HStack(spacing: 10) {
                            StatCard(title: "Wins", value: String(matchWins), icon: "checkmark.seal", height: cardHeight)
                            StatCard(title: "Losses", value: String(matchLosses), icon: "xmark.seal", height: cardHeight)
                            StatCard(title: "Titles", value: String(titles), icon: "trophy.fill", height: cardHeight)
                        }
                        .padding(.top, 24)
                        .padding(.horizontal, 16)
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? -10 : -60)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)

                    // Settings Section
                    Button(action: { showSettings = true }) {
                        ProfileSettingsRow(icon: "gearshape.fill", title: "Settings")
                    }

                    // Feedback Section
                    Button(action: { showFeedbackForm = true }) {
                        ProfileSettingsRow(icon: "plus.bubble", title: "Submit Feedback")
                    }
                    
                    NavigationLink(destination: FeedbackHistoryView()) {
                        ProfileSettingsRow(icon: "clock.arrow.circlepath", title: "Feedback History")
                    }
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
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
                    .onDisappear {
                        if let image = selectedImage {
                            uploadProfilePicture(image)
                        }
                    }
            }
            .sheet(isPresented: $showEditCredentials) {
                EditCredentialsView(userName: $userName, userNickName: $userNickName)
            }
            .sheet(isPresented: $showFeedbackForm) {
                FeedbackView()
            }
            .onChange(of: authCoordinator.authState) { state in
                if case .unauthenticated = state {
                    dismiss()
                }
            }
            .onAppear {
                isAnimating = true
                loadUserProfile()
                loadUserStats()
            }
        }
    }

    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 120, height: 120)
            .foregroundColor(ModernColorScheme.primary)
            .overlay(
                Circle()
                    .stroke(ModernColorScheme.primary, lineWidth: 3)
            )
    }
    
    private func loadUserProfile() {
        print("Loading user profile...")
        networkManager.getUserProfile { userName, userNickName, email, profilePictureUrl in
            DispatchQueue.main.async {
                self.userName = userName ?? "Unknown"
                self.userNickName = userNickName ?? "Unknown"
                self.userRegion = UserDefaults.standard.string(forKey: "loggedInUserRegion") ?? "Unknown"
                self.userPosition = UserDefaults.standard.string(forKey: "loggedInUserPosition") ?? "Unknown"
                if let pictureUrl = profilePictureUrl {
                    print("Received profile picture URL: \(pictureUrl)")
                    self.profileImageUrl = pictureUrl
                    UserDefaults.standard.set(pictureUrl, forKey: "loggedInUserProfilePicture")
                } else {
                    print("No profile picture URL received")
                }
            }
        }
    }

    private func loadUserStats() {
        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int else { return }
        networkManager.getUserStats(userId: userId) { result in
            DispatchQueue.main.async {
                if case .success(let stats) = result {
                    self.matchWins = stats.matchWins
                    self.matchLosses = stats.matchLosses
                    self.titles = stats.titles
                }
            }
        }
    }

    private func uploadProfilePicture(_ image: UIImage) {
        print("Starting profile picture upload...")
        
        // Resize image
        let maxDimension: CGFloat = 800 // Maximum width or height
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let processedImage = resizedImage,
              let imageData = processedImage.jpegData(compressionQuality: 0.5), // Reduced quality
              let userId = UserDefaults.standard.string(forKey: "loggedInUserId") else {
            print("Failed to prepare image data or get user ID")
            return
        }
        
        print("Processed image size: \(imageData.count / 1024)KB")
        
        networkManager.uploadProfilePicture(userId: userId, imageData: imageData) { success, imageUrl in
            if success, let imageUrl = imageUrl {
                print("Profile picture upload successful. URL: \(imageUrl)")
                DispatchQueue.main.async {
                    self.profileImageUrl = imageUrl
                    UserDefaults.standard.set(imageUrl, forKey: "loggedInUserProfilePicture")
                }
            } else {
                print("Profile picture upload failed")
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var height: CGFloat = 120

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
        .frame(height: height)
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(15)
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    var height: CGFloat = 120

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ModernColorScheme.primary)
            Text(value)
                .font(ModernFontScheme.body)
                .foregroundColor(ModernColorScheme.text)
                .lineLimit(1)
            Text(title)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(15)
    }
}
