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
    @State private var pastTournaments: [Tournament] = []
    @State private var tournamentTab: Int = 0 // 0 = Upcoming, 1 = Past
    private let network = NetworkManager()
    @State private var stats: NetworkManager.TeamTournamentStats? = nil
    @State private var showDeleteConfirm: Bool = false
    
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
                    Section(header: Text("Tournaments")) {
                        VStack(alignment: .leading, spacing: 10) {
                            Picker("", selection: $tournamentTab) {
                                Text("Upcoming").tag(0)
                                Text("Past").tag(1)
                            }
                            .pickerStyle(.segmented)

                            let items = tournamentTab == 0 ? upcomingTournaments : pastTournaments
                            if items.isEmpty {
                                Text(tournamentTab == 0 ? "No upcoming tournaments" : "No past tournaments")
                                    .font(ModernFontScheme.caption)
                                    .foregroundColor(ModernColorScheme.textSecondary)
                                    .padding(.top, 4)
                            } else {
                                ForEach(items) { t in
                                    NavigationLink(destination: TournamentDetailView(tournament: t)) {
                                        TeamTournamentRow(
                                            tournament: t,
                                            isPast: tournamentTab == 1,
                                            showWinnerBadge: tournamentTab == 1,
                                            teamId: team.id
                                        )
                                    }
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(ModernColorScheme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(ModernColorScheme.accentMinimal.opacity(0.06), lineWidth: 1)
                                )
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                    if !readonly {
                        Section {
                            if let actionError = actionError {
                                Text(actionError).foregroundColor(.red)
                                if actionError.contains("Cannot delete team"), let t = upcomingTournaments.first {
                                    NavigationLink(destination: TournamentDetailView(tournament: t)) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "link")
                                            Text("View registered tournament")
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
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
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        .navigationTitle("Team")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ModernColorScheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { loadMembers(); loadUpcoming(); loadPast(); loadStats() }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(team.name)
                .font(ModernFontScheme.heading)
                .foregroundColor(ModernColorScheme.text)
            if let s = stats {
                HStack(spacing: 8) {
                    HeaderStatPill(icon: "chart.bar.fill", text: "\(s.wins)-\(s.losses)")
                    HeaderStatPill(icon: "crown.fill", text: "\(s.tournaments_won)")
                }
            }
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

    private func loadStats() {
        network.getTeamTournamentStats(teamId: team.id) { result in
            DispatchQueue.main.async {
                if case .success(let s) = result { self.stats = s }
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
                    // Exclude past/completed; include live
                    var upcoming = list.filter { !isPastOrCompleted($0) }
                    // Also merge live tournaments that this team is registered in
                    network.getLiveTournaments(page: 0, size: 50) { result in
                        switch result {
                        case .failure(_):
                            self.upcomingTournaments = upcoming
                        case .success(let page):
                            let lives = page.content
                            let dg = DispatchGroup()
                            var extra: [Tournament] = []
                            let q = DispatchQueue(label: "team.live.filter")
                            for t in lives {
                                dg.enter()
                                network.getTournamentRegistrationsExpanded(tournamentId: t.id) { resp in
                                    if case .success(let regs) = resp, regs.contains(where: { $0.teamId == team.id }) {
                                        q.async { extra.append(t) }
                                    }
                                    dg.leave()
                                }
                            }
                            dg.notify(queue: .main) {
                                let existingIds = Set(upcoming.map { $0.id })
                                let toAdd = extra.filter { !existingIds.contains($0.id) }
                                self.upcomingTournaments = upcoming + toAdd
                            }
                        }
                    }
                } else {
                    self.upcomingTournaments = []
                }
            }
        }.resume()
    }

    private func loadPast() {
        guard let url = URL(string: APIConfig.teamPastTournamentsEndpoint(teamId: team.id)) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data else { return }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    let isoWithFraction = ISO8601DateFormatter(); isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let d = isoWithFraction.date(from: dateString) { return d }
                    let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime]
                    if let d = iso.date(from: dateString) { return d }
                    let df = DateFormatter(); df.locale = Locale(identifier: "en_US_POSIX"); df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    if let d = df.date(from: dateString) { return d }
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid date: \(dateString)"))
                }
                if let list = try? decoder.decode([Tournament].self, from: data) {
                    // Ended or complete only
                    self.pastTournaments = list.filter { isPastOrCompleted($0) }
                }
            }
        }.resume()
    }

    private var actionButtons: some View {
        let loggedInUserId = UserDefaults.standard.integer(forKey: "loggedInUserId")
        let isCaptain = team.ownerUserId == loggedInUserId
        return HStack {
            if isCaptain {
                Button(role: .destructive) { showDeleteConfirm = true } label: {
                    Label("Delete Team", systemImage: "trash")
                }
                .alert("Delete Team?", isPresented: $showDeleteConfirm) {
                    Button("Delete", role: .destructive) {
                        network.delete("\(APIConfig.teamsEndpoint)/\(team.id)?requesting_user_id=\(loggedInUserId)") { err in
                            DispatchQueue.main.async {
                                if let err = err { actionError = err.localizedDescription } else { actionError = "Team deleted" }
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This will permanently delete the team and may remove related registrations. This action cannot be undone.")
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
    
    // MARK: - Status helpers (match TournamentsView)
    private func isLiveTournament(_ t: Tournament) -> Bool {
        return t.startsAt <= Date() && t.endsAt == nil
    }
    private func isPastTournament(_ t: Tournament) -> Bool {
        guard let end = t.endsAt else { return false }
        return end <= Date()
    }
    private func isPastOrCompleted(_ t: Tournament) -> Bool {
        if isLiveTournament(t) { return false }
        if isPastTournament(t) { return true }
        return t.status == .complete
    }
}

// MARK: - Team tournaments row (used in TeamDetailedView)
private struct TeamTournamentRow: View {
    let tournament: Tournament
    let isPast: Bool
    let showWinnerBadge: Bool
    var teamId: Int? = nil
    @State private var isWinner: Bool = false
    private let network = NetworkManager()

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ModernColorScheme.accentMinimal.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: isPast ? "trophy" : "calendar")
                    .foregroundColor(ModernColorScheme.accentMinimal)
            }
            VStack(alignment: .leading, spacing: 6) {
                // Larger tournament tag
                HStack(spacing: 8) {
                    Image(systemName: "trophy")
                    Text(tournament.name)
                }
                .font(ModernFontScheme.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ModernColorScheme.accentMinimal.opacity(0.15))
                .foregroundColor(ModernColorScheme.accentMinimal)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .lineLimit(1)

                Text(dateRange(tournament))
                    .font(ModernFontScheme.caption)
                    .foregroundColor(.gray)

                if isPast && showWinnerBadge && isWinner {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill").foregroundColor(Color.yellow)
                        Text("Winner")
                    }
                    .font(ModernFontScheme.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.15))
                    .foregroundColor(ModernColorScheme.text)
                    .cornerRadius(10)
                }
            }
            Spacer()
        }
        .overlay(alignment: .topTrailing) {
            if !isPast && tournament.startsAt <= Date() && tournament.endsAt == nil {
                Text("LIVE")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.95))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(.top, 6)
                    .padding(.trailing, 6)
            }
        }
        .padding(10)
        .background(ModernColorScheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

        .onAppear(perform: checkWinnerIfNeeded)
    }

    private func checkWinnerIfNeeded() {
        guard isPast, showWinnerBadge, let teamId = teamId else { return }
        network.getBracket(tournamentId: tournament.id) { result in
            DispatchQueue.main.async {
                if case .success(let matches) = result {
                    let maxRound = matches.map { $0.roundNumber }.max() ?? 0
                    let finals = matches.filter { $0.roundNumber == maxRound }
                    if let last = finals.sorted(by: { $0.matchNumber < $1.matchNumber }).last, let champ = last.winnerTeamId {
                        self.isWinner = (champ == teamId)
                    } else if let anyWinner = matches.compactMap({ $0.winnerTeamId }).last {
                        self.isWinner = (anyWinner == teamId)
                    }
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

private struct HeaderStatPill: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(ModernColorScheme.accentMinimal)
            Text(text).foregroundColor(ModernColorScheme.text)
        }
        .font(ModernFontScheme.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(ModernColorScheme.surface.opacity(0.6))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.black.opacity(0.06), lineWidth: 1))
    }
}


