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
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
            VStack(spacing: 12) {
                titleHeader
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
                        RegisteredTeamsView(totalSlots: tournament.maxTeams, teams: registeredTeams, userTeamIds: userTeamIds, userTeamsById: userTeamsById)
                    case .bracket:
                        BracketLockedView(startsAt: tournament.startsAt)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            }
            stickyRegisterButton
                .padding(.horizontal)
                .padding(.bottom, 12)
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

    private var titleHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tournament.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(ModernColorScheme.text)
                .lineLimit(2)
            // Removed badges per request
        }
    }

    // Overview-only detail content
    private var overviewDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary card
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    summaryTile(icon: "figure.basketball", title: "Type", value: "\(tournament.formatSize)v\(tournament.formatSize)")
                    summaryTile(icon: "person.3", title: "Teams", value: "\(tournament.maxTeams)")
                    if let fee = tournament.entryFeeCents, fee > 0 {
                        summaryTile(icon: "dollarsign.circle", title: "Entry", value: priceString(cents: fee, currency: tournament.currency ?? "CAD"))
                    } else {
                        summaryTile(icon: "gift", title: "Entry", value: "Free")
                    }
                    summaryTile(icon: "trophy", title: "Prize", value: (tournament.prizeCents.flatMap { priceString(cents: $0, currency: tournament.currency ?? "CAD") }) ?? "TBA")
                }
                Divider()
                infoRow(icon: "calendar", text: dateRange)
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
            .background(ModernColorScheme.surface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
            .shadow(color: ModernColorScheme.primary.opacity(0.06), radius: 5, x: 0, y: 2)

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
            .background(ModernColorScheme.surface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
            .shadow(color: ModernColorScheme.primary.opacity(0.06), radius: 5, x: 0, y: 2)
        }
    }

    private var stickyRegisterButton: some View {
        NavigationLink(destination: RegisterTournamentView(tournament: tournament)) {
            HStack {
                Image(systemName: "square.and.pencil")
                Text("Register for Tournament")
                    .font(ModernFontScheme.body)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(ModernColorScheme.accentMinimal)
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.black.opacity(0.08), lineWidth: 1))
            .foregroundColor(.white)
            .cornerRadius(15)
            .shadow(color: ModernColorScheme.primary.opacity(0.06), radius: 6, x: 0, y: 3)
        }
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
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
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
    VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(ModernColorScheme.accentMinimal)
            Text(title)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
        }
        Text(value)
            .font(ModernFontScheme.body)
            .foregroundColor(ModernColorScheme.text)
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

    private var registeredCount: Int { min(teams.count, totalSlots) }
    private var display: [DisplayItem] {
        let filled = teams.prefix(totalSlots).map { reg in
            DisplayItem(teamId: reg.teamId, name: reg.teamName, isEmpty: false)
        }
        let placeholdersCount = max(0, totalSlots - filled.count)
        let empties: [DisplayItem] = (0..<placeholdersCount).map { _ in
            DisplayItem(teamId: -1, name: "Empty Spot", isEmpty: true)
        }
        return filled + empties
    }

    private struct DisplayItem: Identifiable { let id = UUID(); let teamId: Int; let name: String; let isEmpty: Bool }
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Registered")
                    .font(ModernFontScheme.caption)
                    .foregroundColor(ModernColorScheme.textSecondary)
                Spacer()
                Text("\(registeredCount) / \(totalSlots)")
                    .font(ModernFontScheme.caption)
                    .foregroundColor(.gray)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(display) { item in
                    if item.isEmpty {
                        TeamSlotCard(name: item.name, isEmpty: true, isUserTeam: false)
                    } else {
                        if let myTeam = userTeamsById[item.teamId] {
                            NavigationLink(destination: TeamDetailedView(team: myTeam)) {
                                TeamSlotCard(name: item.name, isEmpty: false, isUserTeam: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink(destination: LazyTeamDetailDestination(teamId: item.teamId, teamName: item.name)) {
                                TeamSlotCard(name: item.name, isEmpty: false, isUserTeam: userTeamIds.contains(item.teamId))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
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
    let isEmpty: Bool
    let isUserTeam: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill((isEmpty ? Color.gray : ModernColorScheme.accentMinimal).opacity(0.15)).frame(width: 28, height: 28)
                Image(systemName: isEmpty ? "plus" : "person.3.fill").foregroundColor(isEmpty ? .gray : ModernColorScheme.accentMinimal)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(isEmpty ? .gray : ModernColorScheme.text)
                    .lineLimit(1)
                if isUserTeam && !isEmpty {
                    Text("Your team")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .padding(12)
        .background(ModernColorScheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isUserTeam && !isEmpty ? Color.red : Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: ModernColorScheme.primary.opacity(0.04), radius: 3, x: 0, y: 1)
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



