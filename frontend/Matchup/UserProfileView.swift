import SwiftUI
import UIKit

struct UserProfileView: View {
    let userId: Int
    @State private var userName: String = ""
    @State private var userNickName: String = ""
    @State private var userRegion: String = ""
    @State private var userPosition: String = ""
    @State private var profileImageUrl: String? = nil
    @State private var isAnimating: Bool = false
    @State private var matchWins: Int = 0
    @State private var matchLosses: Int = 0
    @State private var titles: Int = 0
    struct UserTournamentItem: Identifiable {
        let id: Int
        let tournament: Tournament
        let teamId: Int
        let teamName: String
        let teamLogoUrl: String?
    }

    @State private var upcomingItems: [UserTournamentItem] = []
    @State private var pastItems: [UserTournamentItem] = []
    @State private var selectedTab: Int = 0 // 0 = Upcoming, 1 = Past

    // Self-only states
    @State private var showSettings: Bool = false
    @State private var showFeedbackMenu: Bool = false
    @State private var showFeedbackForm: Bool = false
    @State private var showFeedbackHistory: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var selectedImage: UIImage?

    private let networkManager = NetworkManager()
    private let cardHeight: CGFloat = 80

    private var isSelf: Bool {
        UserDefaults.standard.integer(forKey: "loggedInUserId") == userId
    }

    var body: some View {
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
                                    .stroke(ModernColorScheme.accentMinimal, lineWidth: 3)
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
                                            .stroke(ModernColorScheme.accentMinimal, lineWidth: 3)
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

                    if isSelf {
                        Button(action: { showImagePicker = true }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(ModernColorScheme.accentMinimal)
                                .background(ModernColorScheme.background)
                                .clipShape(Circle())
                        }
                        .offset(x: 40, y: 40)
                    }
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? -24 : -70)
                .animation(.easeOut(duration: 0.8), value: isAnimating)

                VStack(spacing: 6) {
                    Text("@\(userName)")
                        .font(ModernFontScheme.title)
                        .foregroundColor(ModernColorScheme.text)

                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill").foregroundColor(ModernColorScheme.accentMinimal)
                            Text(userRegion)
                                .font(ModernFontScheme.body)
                                .foregroundColor(ModernColorScheme.text)
                                .lineLimit(1)
                        }

                        Divider()
                            .frame(height: 16)
                            .background(ModernColorScheme.textSecondary.opacity(0.6))

                        HStack(spacing: 6) {
                            Image(systemName: "figure.run").foregroundColor(ModernColorScheme.accentMinimal)
                            Text(userPosition)
                                .font(ModernFontScheme.body)
                                .foregroundColor(ModernColorScheme.text)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .fill(ModernColorScheme.surface)
                    )
                    .overlay(
                        Capsule()
                            .stroke(ModernColorScheme.accentMinimal.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.top, 2)

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
                .padding(.top, -12)

                // Segmented control for Upcoming / Past
                Picker("", selection: $selectedTab) {
                    Text("Upcoming").tag(0)
                    Text("Past").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Tournaments list (modern cards) showing user's team
                VStack(spacing: 12) {
                    let items = selectedTab == 0 ? upcomingItems : pastItems
                    if items.isEmpty {
                        Text(selectedTab == 0 ? "No upcoming tournaments" : "No past tournaments")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                            .padding(.top, 8)
                    } else {
                        ForEach(items) { item in
                            TournamentCard(item: item)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isSelf {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            showFeedbackForm = true
                        } label: {
                            Label("Submit Feedback", systemImage: "plus.bubble")
                        }
                        Button {
                            showFeedbackHistory = true
                        } label: {
                            Label("Feedback History", systemImage: "clock.arrow.circlepath")
                        }
                    } label: {
                        Image(systemName: "bubble.left.and.bubble.right")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) { UserSettingsView() }
        .sheet(isPresented: $showFeedbackForm) {
            NavigationStack {
                FeedbackView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showFeedbackForm = false }
                        }
                    }
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFeedbackHistory) {
            NavigationStack {
                FeedbackHistoryView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showFeedbackHistory = false }
                        }
                    }
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
                .onDisappear {
                    if let image = selectedImage, isSelf {
                        uploadProfilePicture(image)
                    }
                }
        }
        .onAppear {
            isAnimating = true
            loadUser()
            loadStats()
            loadUpcomingTournaments()
        }
    }

    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 120, height: 120)
            .foregroundColor(.white)
            .overlay(
                Circle()
                    .stroke(ModernColorScheme.accentMinimal, lineWidth: 3)
            )
    }

    private func loadUser() {
        networkManager.getUser(userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self.userName = user.userName
                    self.userNickName = user.userNickName
                    self.userRegion = user.userRegion
                    self.userPosition = user.userPosition
                    self.profileImageUrl = user.profilePictureUrl
                case .failure(_):
                    self.userName = "Unknown"
                    self.userNickName = "Unknown"
                    self.userRegion = "Unknown"
                    self.userPosition = "Unknown"
                    self.profileImageUrl = nil
                }
            }
        }
    }

    private func loadStats() {
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

    private func loadUpcomingTournaments() {
        networkManager.getTeamsForUser(userId: userId) { result in
            switch result {
            case .failure(_):
                break
            case .success(let teams):
                let group = DispatchGroup()
                var aggregated: [UserTournamentItem] = []
                let queue = DispatchQueue(label: "user.tournaments.merge")
                for team in teams {
                    group.enter()
                    fetchTeamUpcoming(teamId: team.id) { tournaments in
                        queue.async {
                            let mapped = tournaments.map { t in
                                UserTournamentItem(id: t.id, tournament: t, teamId: team.id, teamName: team.name, teamLogoUrl: team.logoUrl)
                            }
                            aggregated.append(contentsOf: mapped)
                            group.leave()
                        }
                    }
                }
                group.notify(queue: .main) {
                    // Deduplicate by tournament id and sort by start date
                    let unique = Dictionary(grouping: aggregated, by: { $0.id }).compactMap { $0.value.first }
                    self.upcomingItems = unique.sorted { $0.tournament.startsAt < $1.tournament.startsAt }
                }
            }
        }
    }

    private func fetchTeamUpcoming(teamId: Int, completion: @escaping ([Tournament]) -> Void) {
        guard let url = URL(string: APIConfig.teamUpcomingTournamentsEndpoint(teamId: teamId)) else { completion([]); return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { DispatchQueue.main.async { completion([]) }; return }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                let isoWithFraction = ISO8601DateFormatter()
                isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let d = isoWithFraction.date(from: dateString) { return d }
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime]
                if let d = iso.date(from: dateString) { return d }
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                if let d = df.date(from: dateString) { return d }
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid date: \(dateString)"))
            }
            if let list = try? decoder.decode([Tournament].self, from: data) {
                DispatchQueue.main.async { completion(list) }
            } else {
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }

    private func uploadProfilePicture(_ image: UIImage) {
        // Resize image
        let maxDimension: CGFloat = 800
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let processedImage = resizedImage,
              let imageData = processedImage.jpegData(compressionQuality: 0.5) else {
            return
        }

        let uid = String(userId)
        networkManager.uploadProfilePicture(userId: uid, imageData: imageData) { success, imageUrl in
            if success, let imageUrl = imageUrl {
                DispatchQueue.main.async {
                    self.profileImageUrl = imageUrl
                    if self.isSelf {
                        UserDefaults.standard.set(imageUrl, forKey: "loggedInUserProfilePicture")
                    }
                }
            }
        }
    }

    private func formatDateRange(_ t: Tournament) -> String {
        let calendar = Calendar.current
        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .medium
        dateFmt.timeStyle = .none
        let timeFmt = DateFormatter()
        timeFmt.dateStyle = .none
        timeFmt.timeStyle = .short
        let startDate = dateFmt.string(from: t.startsAt)
        let startTime = timeFmt.string(from: t.startsAt)
        if let end = t.endsAt {
            if calendar.isDate(t.startsAt, inSameDayAs: end) {
                let endTime = timeFmt.string(from: end)
                return "\(startDate), \(startTime) – \(endTime)"
            } else {
                let endDate = dateFmt.string(from: end)
                let endTime = timeFmt.string(from: end)
                return "\(startDate), \(startTime) – \(endDate), \(endTime)"
            }
        }
        return "\(startDate), \(startTime)"
    }
}

private struct TournamentCard: View {
    let item: UserProfileView.UserTournamentItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(ModernColorScheme.accentMinimal.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "calendar")
                    .foregroundColor(ModernColorScheme.accentMinimal)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.tournament.name)
                    .foregroundColor(ModernColorScheme.text)
                    .font(ModernFontScheme.body)
                    .lineLimit(1)

                Text(formatDateRange(item.tournament))
                    .foregroundColor(ModernColorScheme.textSecondary)
                    .font(ModernFontScheme.caption)
            }

            Spacer()

            TeamAvatarCircle(name: item.teamName, logoUrl: item.teamLogoUrl)
        }
        .padding(12)
        .background(ModernColorScheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ModernColorScheme.accentMinimal.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    private func formatDateRange(_ t: Tournament) -> String {
        let calendar = Calendar.current
        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .medium
        dateFmt.timeStyle = .none
        let timeFmt = DateFormatter()
        timeFmt.dateStyle = .none
        timeFmt.timeStyle = .short
        let startDate = dateFmt.string(from: t.startsAt)
        let startTime = timeFmt.string(from: t.startsAt)
        if let end = t.endsAt {
            if calendar.isDate(t.startsAt, inSameDayAs: end) {
                let endTime = timeFmt.string(from: end)
                return "\(startDate), \(startTime) – \(endTime)"
            } else {
                let endDate = dateFmt.string(from: end)
                let endTime = timeFmt.string(from: end)
                return "\(startDate), \(startTime) – \(endDate), \(endTime)"
            }
        }
        return "\(startDate), \(startTime)"
    }
}

private struct TeamAvatarCircle: View {
    let name: String
    let logoUrl: String?

    var body: some View {
        ZStack {
            if let logoUrl = logoUrl, let url = URL(string: logoUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(ModernColorScheme.accentMinimal, lineWidth: 2)
        )
    }

    private var placeholder: some View {
        Text(initials(from: name))
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(ModernColorScheme.text)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ModernColorScheme.primary.opacity(0.15))
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        if let first = parts.first { return String(first.prefix(1)).uppercased() }
        return String(name.prefix(1)).uppercased()
    }
}


