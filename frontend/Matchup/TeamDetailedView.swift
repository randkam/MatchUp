import SwiftUI

struct TeamDetailedView: View {
    let team: TeamModel
    let readonly: Bool
    @State private var members: [TeamMemberModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var userNames: [Int: String] = [:]
    @State private var actionError: String? = nil
    @State private var upcomingTournaments: [Tournament] = []
    private let network = NetworkManager()
    
    init(team: TeamModel, readonly: Bool = false) {
        self.team = team
        self.readonly = readonly
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
                .padding(.horizontal)
                .padding(.top)
            
            // Invite button (captain only), hidden in read-only mode
            HStack {
                let loggedInUserId = UserDefaults.standard.integer(forKey: "loggedInUserId")
                let isCaptain = team.ownerUserId == loggedInUserId
                if !readonly && isCaptain {
                    NavigationLink(destination: InviteUsersView(team: team)) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Invite Users")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(ModernColorScheme.accentMinimal.opacity(0.15))
                        .foregroundColor(ModernColorScheme.accentMinimal)
                        .cornerRadius(10)
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
            
            if isLoading && members.isEmpty {
                ProgressView().tint(ModernColorScheme.brandBlue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(ModernColorScheme.textSecondary)
                    .padding()
            } else {
                List {
                    Section(header: Text("Roster")) {
                        ForEach(members) { member in
                            HStack(spacing: 12) {
                                if member.userId == UserDefaults.standard.integer(forKey: "loggedInUserId") {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle().fill(ModernColorScheme.primary.opacity(0.15)).frame(width: 32, height: 32)
                                            Image(systemName: member.role == "CAPTAIN" ? "crown.fill" : "person.fill")
                                                .foregroundColor(member.role == "CAPTAIN" ? .yellow : ModernColorScheme.accentMinimal)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(member.username ?? userNames[member.userId] ?? "User #\(member.userId)")
                                                .foregroundColor(ModernColorScheme.text)
                                            Text(member.role.capitalized)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                } else {
                                    NavigationLink(destination: UserProfileView(userId: member.userId)) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle().fill(ModernColorScheme.primary.opacity(0.15)).frame(width: 32, height: 32)
                                                Image(systemName: member.role == "CAPTAIN" ? "crown.fill" : "person.fill")
                                                    .foregroundColor(member.role == "CAPTAIN" ? .yellow : ModernColorScheme.accentMinimal)
                                            }
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(member.username ?? userNames[member.userId] ?? "User #\(member.userId)")
                                                    .foregroundColor(ModernColorScheme.text)
                                                Text(member.role.capitalized)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(ModernColorScheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if canRemove(member: member) {
                                    Button(role: .destructive) {
                                        remove(member: member)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    if !upcomingTournaments.isEmpty {
                        Section(header: Text("Upcoming Tournaments")) {
                            ForEach(upcomingTournaments) { t in
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(ModernColorScheme.accentMinimal.opacity(0.15)).frame(width: 40, height: 40)
                                        Image(systemName: "calendar").foregroundColor(ModernColorScheme.accentMinimal)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(t.name).foregroundColor(ModernColorScheme.text)
                                        Text(dateRange(t)).font(.caption).foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .background(ModernColorScheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                    if !readonly {
                        Section {
                            if let actionError = actionError {
                                Text(actionError).foregroundColor(.red)
                            }
                            actionButtons
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            Spacer(minLength: 0)
        }
        .background(ModernColorScheme.background.ignoresSafeArea())
        .navigationTitle("Team")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadMembers(); loadUpcoming() }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(team.name)
                .font(ModernFontScheme.heading)
                .foregroundColor(ModernColorScheme.text)
            Text("Basketball")
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
        }
    }
    
    private func loadMembers() {
        isLoading = true
        errorMessage = nil
        network.getTeamMembers(teamId: team.id) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    members = response
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        }
    }

    private func loadUpcoming() {
        guard let url = URL(string: APIConfig.teamUpcomingTournamentsEndpoint(teamId: team.id)) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data else { return }
                let decoder = JSONDecoder()
                // Match tournament date decoding used elsewhere
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
                    self.upcomingTournaments = list
                }
            }
        }.resume()
    }

    private var actionButtons: some View {
        let loggedInUserId = UserDefaults.standard.integer(forKey: "loggedInUserId")
        let isCaptain = team.ownerUserId == loggedInUserId
        return HStack {
            if isCaptain {
                Button(role: .destructive) {
                    network.delete("\(APIConfig.teamsEndpoint)/\(team.id)?requesting_user_id=\(loggedInUserId)") { err in
                        DispatchQueue.main.async {
                            if let err = err { actionError = err.localizedDescription } else { actionError = "Team deleted" }
                        }
                    }
                } label: {
                    Label("Delete Team", systemImage: "trash")
                }
            } else {
                Button(role: .destructive) {
                    // POST /teams/{teamId}/leave?user_id=
                    guard let url = URL(string: "\(APIConfig.teamsEndpoint)/\(team.id)/leave?user_id=\(loggedInUserId)") else { return }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        DispatchQueue.main.async {
                            if let error = error { actionError = error.localizedDescription; return }
                            guard let http = response as? HTTPURLResponse else { actionError = "Server error"; return }
                            if (200...299).contains(http.statusCode) { actionError = "Left team" } else {
                                let msg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Server error"
                                actionError = msg
                            }
                        }
                    }.resume()
                } label: {
                    Label("Leave Team", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
    }

    private func canRemove(member: TeamMemberModel) -> Bool {
        let loggedInUserId = UserDefaults.standard.integer(forKey: "loggedInUserId")
        let isCaptain = team.ownerUserId == loggedInUserId
        return !readonly && isCaptain && member.role != "CAPTAIN"
    }

    private func remove(member: TeamMemberModel) {
        let loggedInUserId = UserDefaults.standard.integer(forKey: "loggedInUserId")
        network.removeTeamMember(teamId: team.id, targetUserId: member.userId, requestingUserId: loggedInUserId) { err in
            DispatchQueue.main.async {
                if let err = err { actionError = err.localizedDescription } else {
                    members.removeAll { $0.id == member.id }
                }
            }
        }
    }

    private func dateRange(_ t: Tournament) -> String {
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


