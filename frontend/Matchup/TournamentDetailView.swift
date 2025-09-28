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
                statusPill(status: tournament.status)
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
                if tournament.status == .signupsOpen {
                    NavigationLink(destination: registerDestination()) {
                        Text("Sign up")
                            .font(.caption)
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
    VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(ModernColorScheme.accentMinimal)
                .frame(width: 22, alignment: .leading)
            Text(title)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
        }
        Text(value)
            .font(ModernFontScheme.body)
            .foregroundColor(ModernColorScheme.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
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
                                TeamSlotCard(name: item.name, seed: item.seed, isEmpty: false, isUserTeam: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink(destination: LazyTeamDetailDestination(teamId: item.teamId, teamName: item.name)) {
                                TeamSlotCard(name: item.name, seed: item.seed, isEmpty: false, isUserTeam: userTeamIds.contains(item.teamId))
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



