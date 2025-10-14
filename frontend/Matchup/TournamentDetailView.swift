import SwiftUI
import MapKit

struct TournamentDetailView: View {
    let tournament: Tournament
    
    @State private var selectedTab: DetailTab = .overview
    @State private var registeredTeams: [TournamentRegistrationExpandedModel] = []
    @State private var userTeamIds: Set<Int> = []
    @State private var userTeams: [TeamModel] = []
    @State private var errorMessage: String?
    private let network = NetworkManager()
    @State private var latestStatus: TournamentStatus? = nil
    @State private var teamStatsById: [Int: NetworkManager.TeamTournamentStats] = [:]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
            VStack(spacing: 12) {
                heroHeader
                    .padding(.horizontal)
                    .padding(.top)

                Picker("View", selection: $selectedTab) {
                    Text("Overview").tag(DetailTab.overview)
                    Text("Registered Teams").tag(DetailTab.registered)
                    Text("Bracket").tag(DetailTab.bracket)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                Group {
                    switch selectedTab {
                    case .overview:
                        overviewDetails
                    case .registered:
                        RegisteredTeamsView(totalSlots: tournament.maxTeams, teams: registeredTeams, userTeamIds: userTeamIds, userTeamsById: userTeamsById, statsByTeamId: teamStatsById)
                    case .bracket:
                        TournamentBracketSection(tournament: tournament)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                EmptyView() // hide default title; we use our own large title
            }
        }
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        .onAppear {
            loadRegisteredTeams()
        }
    }
    
    private var userTeamsById: [Int: TeamModel] {
        Dictionary(uniqueKeysWithValues: userTeams.map { ($0.id, $0) })
    }

    private var userAlreadyRegistered: Bool {
        // Determine if any of the user's teams are already registered for this tournament
        return registeredTeams.contains { reg in
            userTeamIds.contains(reg.teamId)
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title + status
            HStack(alignment: .center, spacing: 10) {
                Text(tournament.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(ModernColorScheme.text)
                    .lineLimit(2)
                Spacer(minLength: 8)
                statusPill(status: latestStatus ?? tournament.status)
            }
        }
    }

    // Overview-only detail content
    private var overviewDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Capacity / progress card
            capacityCard

            // Summary grid card
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], alignment: .leading, spacing: 12) {
                    summaryTile(icon: "figure.basketball", title: "Format", value: "\(tournament.formatSize)v\(tournament.formatSize)")
                    summaryTile(icon: "person.3", title: "Max Teams", value: "\(tournament.maxTeams)")
                    summaryTile(icon: "trophy", title: "Prize", value: (tournament.prizeCents.flatMap { priceString(cents: $0, currency: tournament.currency ?? "CAD") }) ?? "TBA")
                    if let fee = tournament.entryFeeCents, fee > 0 {
                        summaryTile(icon: "dollarsign.circle", title: "Entry", value: priceString(cents: fee, currency: tournament.currency ?? "CAD"))
                    } else {
                        summaryTile(icon: "gift", title: "Entry", value: "Free")
                    }
                    summaryTile(icon: "calendar", title: "Schedule", value: shortDateRange)
                    summaryTile(icon: "mappin.and.ellipse", title: "Location", value: (tournament.location?.isEmpty == false ? tournament.location! : "TBA"))
                }
                Divider()
                if let venue = tournament.location, !venue.isEmpty {
                    Button(action: { openInAppleMaps(address: venue) }) {
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.and.ellipse").foregroundColor(ModernColorScheme.accentMinimal)
                            Text(venue)
                                .font(ModernFontScheme.body)
                                .foregroundColor(ModernColorScheme.text)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(ModernFontScheme.caption)
                                .foregroundColor(ModernColorScheme.textSecondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ModernColorScheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
                    .shadow(color: ModernColorScheme.primary.opacity(0.06), radius: 5, x: 0, y: 2)
            )

            // Notes card
            VStack(alignment: .leading, spacing: 8) {
                Text("What to expect")
                    .font(ModernFontScheme.heading)
                VStack(alignment: .leading, spacing: 8) {
                    infoRow(icon: "checkmark.seal", text: "Official referees on-site")
                    infoRow(icon: "video", text: "Videographer capturing highlights")
                    infoRow(icon: "square.grid.2x2", text: "Competitive bracket play")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ModernColorScheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
                    .shadow(color: ModernColorScheme.primary.opacity(0.06), radius: 5, x: 0, y: 2)
            )
        }
    }

    private var stickyRegisterButton: some View {
        NavigationLink(destination: registerDestination()) {
            HStack {
                Image(systemName: "square.and.pencil")
                Text("Register for Tournament")
                    .font(ModernFontScheme.body)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(LinearGradient(colors: [ModernColorScheme.accentMinimal, ModernColorScheme.accentMinimal.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.black.opacity(0.06), lineWidth: 1))
            .foregroundColor(.white)
            .cornerRadius(15)
            .shadow(color: ModernColorScheme.primary.opacity(0.12), radius: 10, x: 0, y: 6)
        }
    }

    private var shortDateRange: String {
        let calendar = Calendar.current
        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .medium
        dateFmt.timeStyle = .none
        let startDate = dateFmt.string(from: tournament.startsAt)
        if let end = tournament.endsAt, !calendar.isDate(tournament.startsAt, inSameDayAs: end) {
            let endDate = dateFmt.string(from: end)
            return "\(startDate) – \(endDate)"
        }
        return startDate
    }
    
    private var startDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: tournament.startsAt)
    }
    
    private var dateRange: String {
        let calendar = Calendar.current
        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .medium
        dateFmt.timeStyle = .none
        let timeFmt = DateFormatter()
        timeFmt.dateStyle = .none
        timeFmt.timeStyle = .short
        let startDate = dateFmt.string(from: tournament.startsAt)
        let startTime = timeFmt.string(from: tournament.startsAt)
        if let end = tournament.endsAt {
            if calendar.isDate(tournament.startsAt, inSameDayAs: end) {
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

    private var signupCountdownText: String {
        let now = Date()
        let remaining = tournament.signupDeadline.timeIntervalSince(now)
        if remaining <= 0 { return "Signups closed" }
        let days = Int(remaining) / 86_400
        let hours = (Int(remaining) % 86_400) / 3600
        let mins = (Int(remaining) % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h left to sign up" }
        if hours > 0 { return "\(hours)h \(mins)m left to sign up" }
        return "\(mins)m left to sign up"
    }
    
    private func priceString(cents: Int, currency: String) -> String {
        let amount = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }

    private func openInAppleMaps(address: String) {
        let query = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
            UIApplication.shared.open(url)
        }
    }

    private func loadRegisteredTeams() {
        // Load registrations
        network.getTournamentRegistrationsExpanded(tournamentId: tournament.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let regs):
                    self.registeredTeams = regs
                    // Fetch team stats for all teams
                    let ids = Set(regs.map { $0.teamId })
                    ids.forEach { tid in
                        self.network.getTeamTournamentStats(teamId: tid) { res in
                            DispatchQueue.main.async {
                                if case .success(let s) = res { self.teamStatsById[tid] = s }
                            }
                        }
                    }
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                }
            }
        }
        // Refresh the tournament to get up-to-date status
        network.getTournamentById(tournamentId: tournament.id) { result in
            DispatchQueue.main.async {
                if case .success(let t) = result {
                    self.latestStatus = t.status
                }
            }
        }
        // Load user's teams to highlight
        let userId = UserDefaults.standard.integer(forKey: "loggedInUserId")
        network.getTeamsForUser(userId: userId) { result in
            DispatchQueue.main.async {
                if case .success(let teams) = result {
                    self.userTeamIds = Set(teams.map { $0.id })
                    self.userTeams = teams
                }
            }
        }
    }

    private var capacityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Capacity")
                    .font(ModernFontScheme.caption)
                    .foregroundColor(ModernColorScheme.textSecondary)
                Spacer()
                Text("\(min(registeredTeams.count, max(0, tournament.maxTeams))) / \(tournament.maxTeams)")
                    .font(ModernFontScheme.caption)
                    .foregroundColor(ModernColorScheme.textSecondary)
            }
            GeometryReader { geo in
                let fraction = CGFloat(min(max(Double(registeredTeams.count) / Double(max(tournament.maxTeams, 1)), 0), 1))
                ZStack(alignment: .leading) {
                    // Track (unfilled portion) uses a contrasting tint vs background
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ModernColorScheme.textSecondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [ModernColorScheme.accentMinimal.opacity(0.9), ModernColorScheme.accentMinimal], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * fraction)
                }
                .frame(height: 12)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.06), lineWidth: 1))
            }
            .frame(height: 12)
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(ModernColorScheme.accentMinimal)
                Text(signupCountdownText)
                    .font(ModernFontScheme.caption)
                    .foregroundColor(ModernColorScheme.textSecondary)
                Spacer()
                if (latestStatus ?? tournament.status) == .signupsOpen && registeredTeams.count < tournament.maxTeams {
                    if userAlreadyRegistered {
                        // Show message instead of sign up when already registered
                        Text("Already registered")
                            .font(ModernFontScheme.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .foregroundColor(ModernColorScheme.accentMinimal)
                            .background(ModernColorScheme.accentMinimal.opacity(0.12))
                            .clipShape(Capsule())
                    } else {
                        NavigationLink(destination: registerDestination()) {
                            Text("Sign up")
                                .font(ModernFontScheme.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(ModernColorScheme.accentMinimal)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ModernColorScheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
                .shadow(color: ModernColorScheme.primary.opacity(0.06), radius: 5, x: 0, y: 2)
        )
    }

    // Extracted to help the compiler type-check closures
    private func registerDestination() -> some View {
        RegisterTournamentView(tournament: tournament, onRegistered: {
            self.selectedTab = .registered
            self.loadRegisteredTeams()
        })
    }
}

private func chip(icon: String, text: String) -> some View {
    HStack(spacing: 6) {
        Image(systemName: icon)
        Text(text)
    }
    .font(ModernFontScheme.caption)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(ModernColorScheme.surface)
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.06), lineWidth: 1))
    .foregroundColor(ModernColorScheme.text)
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
}

private func statusPill(status: TournamentStatus) -> some View {
    let (label, tint): (String, Color) = {
        switch status {
        case .draft: return ("Draft", Color.gray)
        case .signupsOpen: return ("Signups Open", ModernColorScheme.accentMinimal)
        case .full: return ("Full", Color.red)
        case .locked: return ("Locked", Color.orange)
        case .live: return ("Live", Color.green)
        case .complete: return ("Complete", Color.blue)
        }
    }()
    return HStack(spacing: 6) {
        Circle().fill(tint).frame(width: 6, height: 6)
        Text(label)
            .font(.caption)
            .fontWeight(.semibold)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(tint.opacity(0.12))
    .foregroundColor(tint)
    .clipShape(Capsule())
}

 

private func heroPill(text: String) -> some View {
    Text(text)
        .font(ModernFontScheme.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.12))
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
}

private struct Badge: View {
    let icon: String
    let text: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.12))
        .foregroundColor(tint)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private func infoRow(icon: String, text: String) -> some View {
    HStack(spacing: 10) {
        Image(systemName: icon)
            .foregroundColor(ModernColorScheme.accentMinimal)
        Text(text)
            .font(ModernFontScheme.body)
            .foregroundColor(ModernColorScheme.text)
        Spacer()
    }
}

private func summaryTile(icon: String, title: String, value: String) -> some View {
    HStack(alignment: .top, spacing: 10) {
        Image(systemName: icon)
            .foregroundColor(ModernColorScheme.accentMinimal)
            .imageScale(.medium)
            .frame(width: 28, alignment: .leading)
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
            Text(value)
                .font(ModernFontScheme.body)
                .foregroundColor(ModernColorScheme.text)
        }
        Spacer(minLength: 0)
    }
    .padding()
    .background(ModernColorScheme.surface.opacity(0.6))
    .cornerRadius(12)
}

private enum DetailTab { case overview, registered, bracket }

private struct OverviewPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview coming soon")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RegisteredTeamsView: View {
    let totalSlots: Int
    let teams: [TournamentRegistrationExpandedModel]
    let userTeamIds: Set<Int>
    let userTeamsById: [Int: TeamModel]
    let statsByTeamId: [Int: NetworkManager.TeamTournamentStats]

    private var registeredCount: Int { min(teams.count, totalSlots) }
    private var display: [DisplayItem] {
        let filled = teams.prefix(totalSlots).map { reg in
            DisplayItem(teamId: reg.teamId, name: reg.teamName, seed: reg.seed, isEmpty: false)
        }
        let placeholdersCount = max(0, totalSlots - filled.count)
        let empties: [DisplayItem] = (0..<placeholdersCount).map { _ in
            DisplayItem(teamId: -1, name: "Open Slot", seed: nil, isEmpty: true)
        }
        return filled + empties
    }

    private struct DisplayItem: Identifiable { let id = UUID(); let teamId: Int; let name: String; let seed: Int?; let isEmpty: Bool }
    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Registered Teams")
                    .font(ModernFontScheme.heading)
                    .foregroundColor(ModernColorScheme.text)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "person.3")
                    Text("\(registeredCount)/\(totalSlots)")
                        .fontWeight(.semibold)
                }
                .font(ModernFontScheme.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ModernColorScheme.accentMinimal.opacity(0.12))
                .foregroundColor(ModernColorScheme.accentMinimal)
                .clipShape(Capsule())
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(display) { item in
                    if item.isEmpty {
                        TeamSlotCard(name: item.name, seed: nil, isEmpty: true, isUserTeam: false)
                    } else {
                        if let myTeam = userTeamsById[item.teamId] {
                            NavigationLink(destination: TeamDetailedView(team: myTeam)) {
                                TeamSlotCardWithStats(name: item.name, seed: item.seed, isEmpty: false, isUserTeam: true, stats: statsByTeamId[item.teamId])
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink(destination: LazyTeamDetailDestination(teamId: item.teamId, teamName: item.name)) {
                                TeamSlotCardWithStats(name: item.name, seed: item.seed, isEmpty: false, isUserTeam: userTeamIds.contains(item.teamId), stats: statsByTeamId[item.teamId])
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ModernColorScheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 1))
                .shadow(color: ModernColorScheme.primary.opacity(0.06), radius: 5, x: 0, y: 2)
        )
    }
}

// Destination that builds a lightweight TeamModel and shows read-only TeamDetailedView
private struct LazyTeamDetailDestination: View {
    let teamId: Int
    let teamName: String

    var body: some View {
        TeamDetailedView(team: TeamModel(id: teamId, name: teamName, sport: "basketball", ownerUserId: -1, logoUrl: nil, createdAt: nil), readonly: true)
        .navigationTitle("Team")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TeamSlotCard: View {
    let name: String
    let seed: Int?
    let isEmpty: Bool
    let isUserTeam: Bool
    
    private var gradient: LinearGradient {
        LinearGradient(colors: [ModernColorScheme.accentMinimal.opacity(0.18), ModernColorScheme.accentMinimal.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Card background
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ModernColorScheme.surface)
                .overlay(
                    Group {
                        if isEmpty {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                .foregroundColor(Color.black.opacity(0.08))
                        } else if isUserTeam {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(ModernColorScheme.accentMinimal, lineWidth: 2)
                        } else {
                            EmptyView()
                        }
                    }
                )
                .shadow(color: ModernColorScheme.primary.opacity(0.05), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        if isEmpty {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 40, height: 40)
                        } else {
                            Circle()
                                .fill(gradient)
                                .frame(width: 40, height: 40)
                        }
                        if !isEmpty {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(ModernColorScheme.accentMinimal)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(ModernFontScheme.body)
                            .foregroundColor(isEmpty ? .gray : ModernColorScheme.text)
                            .lineLimit(1)
                        if isUserTeam && !isEmpty {
                            Text("Your team")
                                .font(ModernFontScheme.caption)
                                .foregroundColor(ModernColorScheme.accentMinimal)
                        }
                    }
                    Spacer()
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
    }
}

private struct TeamSlotCardWithStats: View {
    let name: String
    let seed: Int?
    let isEmpty: Bool
    let isUserTeam: Bool
    let stats: NetworkManager.TeamTournamentStats?

    var body: some View {
        VStack(spacing: 6) {
            TeamSlotCard(name: name, seed: seed, isEmpty: isEmpty, isUserTeam: isUserTeam)
            if let s = stats, !isEmpty {
                HStack(spacing: 6) {
                    Text("Record:")
                        .font(ModernFontScheme.caption)
                        .foregroundColor(ModernColorScheme.textSecondary)
                    Text("\(s.wins)-\(s.losses)")
                        .font(ModernFontScheme.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(ModernColorScheme.text)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill").foregroundColor(.yellow)
                        Text("\(s.tournaments_won)")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.text)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
}

private struct BracketLockedView: View {
    let startsAt: Date
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(ModernColorScheme.surface)
                    .frame(height: 240)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
                    .shadow(color: ModernColorScheme.primary.opacity(0.06), radius: 5, x: 0, y: 2)
                    .overlay(
                        // Faux bracket graphic behind blur
                        bracketPlaceholder()
                            .padding(16)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    )
                    .overlay(
                        // Blur-like frosted overlay
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(ModernColorScheme.textSecondary)
                    Text("Bracket will be available 24 hours before start time")
                        .font(ModernFontScheme.body)
                        .foregroundColor(ModernColorScheme.textSecondary)
                    Text(availabilityText)
                        .font(ModernFontScheme.caption)
                        .foregroundColor(ModernColorScheme.textSecondary)
                }
            }
        }
    }
    
    private var availabilityText: String {
        let date = Calendar.current.date(byAdding: .hour, value: -24, to: startsAt) ?? startsAt
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return "Available after \(df.string(from: date))"
    }
}

private struct TournamentBracketSection: View {
    let tournament: Tournament
    @State private var matches: [TournamentMatchModel] = []
    @State private var errorMessage: String?
    @State private var isGenerating: Bool = false
    private let network = NetworkManager()
    @State private var teamNamesById: [Int: String] = [:]

    private var isWithin24h: Bool {
        let now = Date()
        guard let unlocked = Calendar.current.date(byAdding: .hour, value: -24, to: tournament.startsAt) else { return false }
        return now >= unlocked
    }

    private var rounds: [[TournamentMatchModel]] {
        let grouped = Dictionary(grouping: matches, by: { $0.roundNumber })
        let keys = grouped.keys.sorted()
        return keys.map { grouped[$0]!.sorted { $0.matchNumber < $1.matchNumber } }
    }

    private var championTeamId: Int? {
        guard let lastRound = rounds.last, lastRound.count == 1 else { return nil }
        let final = lastRound[0]
        guard final.status == "COMPLETE", let winner = final.winnerTeamId else { return nil }
        return Int(truncatingIfNeeded: winner)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !isWithin24h {
                BracketLockedView(startsAt: tournament.startsAt)
            } else {
                if matches.isEmpty {
                    Text("Bracket not generated yet")
                        .font(ModernFontScheme.body)
                        .foregroundColor(ModernColorScheme.textSecondary)
                } else {
                    BracketCanvasView(rounds: rounds, teamNamesById: teamNamesById, onScoreUpdated: { reload() })
                        .padding(.vertical, 4)
                    if let champId = championTeamId, let champName = teamNamesById[champId] {
                        ChampionBanner(teamId: champId, teamName: champName)
                    }
                }
            }

            if let err = errorMessage {
                Text(err).foregroundColor(.red).font(ModernFontScheme.caption)
            }
        }
        .onAppear(perform: reload)
    }

    private func reload() {
        let group = DispatchGroup()
        group.enter()
        network.getBracket(tournamentId: tournament.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data): self.matches = data; self.errorMessage = nil
                case .failure(let err): self.errorMessage = err.localizedDescription
                }
                group.leave()
            }
        }
        group.enter()
        network.getTournamentRegistrationsExpanded(tournamentId: tournament.id) { result in
            DispatchQueue.main.async {
                if case .success(let regs) = result {
                    var map: [Int: String] = [:]
                    for r in regs { map[r.teamId] = r.teamName }
                    self.teamNamesById = map
                }
                group.leave()
            }
        }
    }

    // generation now happens automatically on GET within 24h window (server-side)
}

// Canvas-style bracket
private struct BracketCanvasView: View {
    let rounds: [[TournamentMatchModel]]
    let teamNamesById: [Int: String]
    var onScoreUpdated: () -> Void
    @State private var editingMatch: TournamentMatchModel? = nil
    @State private var scoreA: String = ""
    @State private var scoreB: String = ""

    private let cardWidth: CGFloat = 160
    private let cardHeight: CGFloat = 60
    private let hSpacing: CGFloat = 32
    private let vSpacing: CGFloat = 20

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    connectorsPath().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    cardsLayer
                }
                .frame(width: max(geo.size.width, contentWidth), height: contentHeight)
            }
            .frame(height: contentHeight)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ModernColorScheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
                .shadow(color: ModernColorScheme.primary.opacity(0.06), radius: 5, x: 0, y: 2)
        )
        .sheet(item: $editingMatch) { match in
            AdminEditScoreSheet(match: match,
                                teamNamesById: teamNamesById,
                                onDismiss: {
                                    editingMatch = nil
                                    onScoreUpdated()
                                })
        }
    }

    private var maxMatchesInFirstRound: Int { rounds.first?.count ?? 0 }
    private var contentWidth: CGFloat { CGFloat(rounds.count) * (cardWidth + hSpacing) - hSpacing + 24 }
    private var contentHeight: CGFloat {
        let rows = maxMatchesInFirstRound
        return CGFloat(rows) * (cardHeight + vSpacing) - vSpacing + 24
    }

    private func xForRound(_ idx: Int) -> CGFloat {
        12 + CGFloat(idx) * (cardWidth + hSpacing)
    }

    private func yForMatch(roundIndex: Int, matchIndex: Int) -> CGFloat {
        // Space doubles each subsequent round
        let block = Int(pow(2.0, Double(roundIndex)))
        let slotHeight = cardHeight + vSpacing
        let groupHeight = slotHeight * CGFloat(block)
        let topOffset = 12 + (groupHeight - slotHeight) / 2
        return topOffset + CGFloat(matchIndex) * groupHeight
    }

    private var isAdmin: Bool {
        (UserDefaults.standard.string(forKey: "userRole")?.uppercased() == "ADMIN")
    }

    private func connectorsPath() -> Path {
        var path = Path()
        guard rounds.count > 1 else { return path }
        for (roundIdx, round) in rounds.enumerated() where roundIdx < rounds.count - 1 {
            for (matchIdx, _) in round.enumerated() {
                let sourceY = yForMatch(roundIndex: roundIdx, matchIndex: matchIdx)
                let nextIndex = (matchIdx) / 2
                let destY = yForMatch(roundIndex: roundIdx + 1, matchIndex: nextIndex)
                let x1 = xForRound(roundIdx) + cardWidth
                let x2 = xForRound(roundIdx) + cardWidth + hSpacing / 2
                let x3 = xForRound(roundIdx + 1)
                path.move(to: CGPoint(x: x1, y: sourceY + cardHeight / 2))
                path.addLine(to: CGPoint(x: x2, y: sourceY + cardHeight / 2))
                path.addLine(to: CGPoint(x: x2, y: destY + cardHeight / 2))
                path.addLine(to: CGPoint(x: x3, y: destY + cardHeight / 2))
            }
        }
        return path
    }

    @ViewBuilder
    private var cardsLayer: some View {
        ForEach(Array(rounds.enumerated()), id: \.offset) { rIdx, round in
            ForEach(Array(round.enumerated()), id: \.offset) { mIdx, match in
                BracketMatchCard(
                    match: match,
                    teamNamesById: teamNamesById,
                    showEdit: isAdmin,
                    onEdit: { editingMatch = match }
                )
                    .frame(width: cardWidth, height: cardHeight)
                    .position(x: xForRound(rIdx) + cardWidth / 2,
                              y: yForMatch(roundIndex: rIdx, matchIndex: mIdx) + cardHeight / 2)
                    .zIndex(1)
            }
        }
    }

}

private struct BracketMatchCard: View {
    let match: TournamentMatchModel
    let teamNamesById: [Int: String]
    let showEdit: Bool
    var onEdit: () -> Void = {}

    private var showScores: Bool { match.status != "SCHEDULED" }

    var body: some View {
        VStack(spacing: 6) {
            teamRow(teamId: match.teamAId, score: match.scoreA)
            Divider().background(Color.black.opacity(0.06))
            teamRow(teamId: match.teamBId, score: match.scoreB)
        }
        .padding(10)
        .background(ModernColorScheme.surface)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.08), lineWidth: 1))
        .cornerRadius(12)
        .shadow(color: ModernColorScheme.primary.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(alignment: .topTrailing) {
            if showEdit {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(ModernColorScheme.accentMinimal)
                        .background(Circle().fill(Color.white))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
            }
        }
    }

    @ViewBuilder
    private func teamRow(teamId: Int?, score: Int?) -> some View {
        HStack(spacing: 8) {
            if let id = teamId, let name = teamNamesById[id] {
                NavigationLink(destination: LazyTeamDetailDestination(teamId: id, teamName: name)) {
                    HStack(spacing: 8) {
                        avatarView(for: name)
                        let isWinner = (match.winnerTeamId == id)
                        let isLoser = (match.winnerTeamId != nil && match.winnerTeamId != id)
                        Text(name)
                            .font(ModernFontScheme.caption)
                            .fontWeight(isWinner ? .semibold : .regular)
                            .foregroundColor(isLoser ? .gray : ModernColorScheme.text)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 8) {
                    placeholderAvatar()
                    Text("TBD")
                        .font(ModernFontScheme.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            if showScores, let s = score {
                Text("\(s)")
                    .font(ModernFontScheme.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.06))
                    .clipShape(Capsule())
                    .foregroundColor(ModernColorScheme.textSecondary)
            }
        }
    }

    private func avatarView(for name: String) -> some View {
        let initial = String(name.prefix(1)).uppercased()
        return ZStack {
            Circle()
                .fill(LinearGradient(colors: [ModernColorScheme.accentMinimal.opacity(0.25), ModernColorScheme.accentMinimal], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 18, height: 18)
            Text(initial)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private func placeholderAvatar() -> some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                .background(Circle().fill(Color.gray.opacity(0.15)))
                .frame(width: 18, height: 18)
            Image(systemName: "questionmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.gray)
        }
    }
}

private struct ChampionBanner: View {
    let teamId: Int
    let teamName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .foregroundColor(Color.yellow)
            Text("Champion:")
                .font(ModernFontScheme.body)
                .foregroundColor(ModernColorScheme.textSecondary)
            NavigationLink(destination: LazyTeamDetailDestination(teamId: teamId, teamName: teamName)) {
                Text(teamName)
                    .font(ModernFontScheme.body)
                    .fontWeight(.semibold)
                    .foregroundColor(ModernColorScheme.text)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ModernColorScheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.08), lineWidth: 1))
                .shadow(color: ModernColorScheme.primary.opacity(0.06), radius: 5, x: 0, y: 2)
        )
    }
}

// Admin score editor sheet
private struct AdminEditScoreSheet: View, Identifiable {
    let id = UUID()
    let match: TournamentMatchModel
    let teamNamesById: [Int: String]
    var onDismiss: () -> Void

    @State private var scoreA: String = ""
    @State private var scoreB: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    private let network = NetworkManager()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Match \(match.roundNumber)-\(match.matchNumber)")) {
                    HStack {
                        Text(teamNamesById[match.teamAId ?? -1] ?? "Team A")
                        Spacer()
                        TextField("0", text: $scoreA).keyboardType(.numberPad).frame(width: 60)
                    }
                    HStack {
                        Text(teamNamesById[match.teamBId ?? -1] ?? "Team B")
                        Spacer()
                        TextField("0", text: $scoreB).keyboardType(.numberPad).frame(width: 60)
                    }
                }
                if let err = errorMessage { Text(err).foregroundColor(.red) }
            }
            .navigationTitle("Edit Score")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onDismiss) }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save", action: save).disabled(isSaving)
                }
            }
            .onAppear {
                scoreA = String(match.scoreA ?? 0)
                scoreB = String(match.scoreB ?? 0)
            }
        }
    }

    private func save() {
        guard let sA = Int(scoreA), let sB = Int(scoreB) else { errorMessage = "Scores must be numbers"; return }
        isSaving = true
        let uid = UserDefaults.standard.integer(forKey: "loggedInUserId")
        network.updateMatchScore(tournamentId: match.tournamentId, matchId: match.id, scoreA: sA, scoreB: sB, requestingUserId: uid) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success:
                    self.errorMessage = nil
                    onDismiss()
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                }
            }
        }
    }
}

@ViewBuilder
private func bracketPlaceholder() -> some View {
    GeometryReader { geo in
        let w = geo.size.width
        let h = geo.size.height
        let lineColor = Color.white.opacity(0.2)

        ZStack {
            // Left rounds
            Path { p in
                let y1 = h * 0.25
                let y2 = h * 0.75
                let midY = h * 0.5
                p.move(to: CGPoint(x: 16, y: y1 - 20))
                p.addLine(to: CGPoint(x: w * 0.25, y: y1 - 20))
                p.move(to: CGPoint(x: 16, y: y1 + 20))
                p.addLine(to: CGPoint(x: w * 0.25, y: y1 + 20))
                p.move(to: CGPoint(x: 16, y: y2 - 20))
                p.addLine(to: CGPoint(x: w * 0.25, y: y2 - 20))
                p.move(to: CGPoint(x: 16, y: y2 + 20))
                p.addLine(to: CGPoint(x: w * 0.25, y: y2 + 20))
                // Connectors to semi-final
                p.move(to: CGPoint(x: w * 0.25, y: y1))
                p.addLine(to: CGPoint(x: w * 0.45, y: y1))
                p.move(to: CGPoint(x: w * 0.25, y: y2))
                p.addLine(to: CGPoint(x: w * 0.45, y: y2))
                // Semi-final to final
                p.move(to: CGPoint(x: w * 0.45, y: y1))
                p.addLine(to: CGPoint(x: w * 0.6, y: midY))
                p.move(to: CGPoint(x: w * 0.45, y: y2))
                p.addLine(to: CGPoint(x: w * 0.6, y: midY))
            }
            .stroke(lineColor, lineWidth: 2)

            // Right rounds (mirrored)
            Path { p in
                let y1 = h * 0.25
                let y2 = h * 0.75
                let midY = h * 0.5
                p.move(to: CGPoint(x: w - 16, y: y1 - 20))
                p.addLine(to: CGPoint(x: w * 0.75, y: y1 - 20))
                p.move(to: CGPoint(x: w - 16, y: y1 + 20))
                p.addLine(to: CGPoint(x: w * 0.75, y: y1 + 20))
                p.move(to: CGPoint(x: w - 16, y: y2 - 20))
                p.addLine(to: CGPoint(x: w * 0.75, y: y2 - 20))
                p.move(to: CGPoint(x: w - 16, y: y2 + 20))
                p.addLine(to: CGPoint(x: w * 0.75, y: y2 + 20))
                // Connectors to semi-final
                p.move(to: CGPoint(x: w * 0.75, y: y1))
                p.addLine(to: CGPoint(x: w * 0.55, y: y1))
                p.move(to: CGPoint(x: w * 0.75, y: y2))
                p.addLine(to: CGPoint(x: w * 0.55, y: y2))
                // Semi-final to final
                p.move(to: CGPoint(x: w * 0.55, y: y1))
                p.addLine(to: CGPoint(x: w * 0.4, y: midY))
                p.move(to: CGPoint(x: w * 0.55, y: y2))
                p.addLine(to: CGPoint(x: w * 0.4, y: midY))
            }
            .stroke(lineColor, lineWidth: 2)

            // Center trophy placeholder
            Image(systemName: "trophy.fill")
                .foregroundColor(Color.yellow.opacity(0.6))
                .font(.system(size: 28))
                .position(x: w * 0.5, y: h * 0.5)
        }
    }
}



