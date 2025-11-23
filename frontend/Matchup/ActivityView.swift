private struct TeamRouterView: View {
    let teamId: Int
    @State private var team: TeamModel? = nil
    @State private var isLoading = true
    private let network = NetworkManager()

    var body: some View {
        Group {
            if isLoading {
                ProgressView().tint(ModernColorScheme.accentMinimal)
            } else if let team = team {
                TeamDetailedView(team: team, readonly: false)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text("Oops, this team was deleted")
                        .foregroundColor(ModernColorScheme.text)
                    Text("Team #\(teamId)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Team")
        .onAppear(perform: load)
    }

    private func load() {
        network.getTeamById(teamId: teamId) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let t): team = t
                case .failure: team = nil
                }
            }
        }
    }
}
private struct TournamentRouterView: View {
    let tournamentId: Int
    @State private var tournament: Tournament? = nil
    @State private var isLoading = true
    private let network = NetworkManager()

    var body: some View {
        Group {
            if isLoading {
                ProgressView().tint(ModernColorScheme.accentMinimal)
            } else if let tournament = tournament {
                TournamentDetailView(tournament: tournament)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text("Oops, this tournament was deleted")
                        .foregroundColor(ModernColorScheme.text)
                    Text("Tournament #\(tournamentId)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Tournament")
        .onAppear(perform: load)
    }

    private func load() {
        network.getTournamentById(tournamentId: tournamentId) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let t): tournament = t
                case .failure: tournament = nil
                }
            }
        }
    }
}
import SwiftUI

enum ActivityRoute: Hashable { case team(Int); case user(Int); case tournament(Int) }

struct ActivityView: View {
    @State private var invites: [TeamInviteModel] = []
    @State private var activities: [NetworkManager.ActivityItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var filter: ActivityFilter = .all
    @State private var respondingIds: Set<Int> = []
    @State private var navPath = NavigationPath()
    @State private var inviteErrorMessage: String? = nil
    @State private var showInviteErrorAlert: Bool = false
    private let network = NetworkManager()
    
    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                ModernColorScheme.background.ignoresSafeArea()
                Group {
                    if isLoading && invites.isEmpty {
                        ProgressView().tint(ModernColorScheme.primary)
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(ModernColorScheme.textSecondary)
                            .padding(.horizontal, 20)
                    } else if invites.isEmpty && activities.isEmpty {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle().fill(ModernColorScheme.accentMinimal.opacity(0.12)).frame(width: 88, height: 88)
                                Image(systemName: "bell.slash.fill")
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundColor(ModernColorScheme.accentMinimal)
                            }
                            Text("You're all caught up")
                                .font(.headline)
                                .foregroundColor(ModernColorScheme.text)
                            Text("Pull to refresh whenever you like.")
                                .font(.caption)
                                .foregroundColor(ModernColorScheme.textSecondary)
                        }
                        .padding(.horizontal, 20)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 14, pinnedViews: []) {
                                // Filter
                                VStack(alignment: .leading, spacing: 10) {
                                    Picker("Filter", selection: $filter) {
                                        Text("All").tag(ActivityFilter.all)
                                        Text("Updates").tag(ActivityFilter.teams)
                                        Text("Invites").tag(ActivityFilter.invites)
                                    }
                                    .pickerStyle(.segmented)
                                    .overlay(alignment: .topTrailing) {
                                        if invites.count > 0 {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.red)
                                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                                Text(String(min(invites.count, 99)))
                                                    .foregroundColor(.white)
                                                    .font(.caption2)
                                            }
                                            .frame(width: 16, height: 16)
                                            .offset(x: -10, y: 6)
                                            .accessibilityLabel("\(invites.count) pending invites")
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
                                .padding(.horizontal, 16)

                                // Activities
                                if !combinedFeed().isEmpty {
                                    ForEach(combinedFeedFilteredSorted()) { item in
                                        switch item {
                                        case .activity(let a):
                                            ActivityRow(
                                                message: a.message ?? "",
                                                typeCode: a.typeCode,
                                                createdAt: a.createdAt,
                                                teamId: a.teamId,
                                                teamName: a.teamName,
                                                actorUserId: a.actorUserId,
                                                actorUsername: a.actorUsername,
                                                tournamentId: a.tournamentId,
                                                tournamentName: a.tournamentName,
                                                onTeamTap: { id in navPath.append(ActivityRoute.team(id)) },
                                                onUserTap: { id in navPath.append(ActivityRoute.user(id)) },
                                                onTournamentTap: { id in navPath.append(ActivityRoute.tournament(id)) },
                                                payloadJSON: a.payload
                                            )
                                            .padding(.horizontal, 16)
                                        case .invite(let inv):
                                            InviteRow(
                                                invite: inv,
                                                isResponding: respondingIds.contains(inv.id),
                                                acceptAction: { respond(invite: inv, accept: true) },
                                                declineAction: { respond(invite: inv, accept: false) },
                                                onTeamTap: { _ in navPath.append(ActivityRoute.team(inv.teamId)) }
                                            )
                                            .padding(.horizontal, 16)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .tint(ModernColorScheme.accentMinimal)
                    }
                }
            }
            .navigationTitle("Activity")
            .navigationDestination(for: ActivityRoute.self) { route in
                switch route {
                case .team(let teamId): TeamRouterView(teamId: teamId)
                case .user(let userId): UserProfileView(userId: userId)
                case .tournament(let tournamentId): TournamentRouterView(tournamentId: tournamentId)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        loadInvites()
                        loadActivities()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh")
                }
            }
        }
        .alert("Cannot Join Team", isPresented: $showInviteErrorAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(inviteErrorMessage ?? "You cannot join this team since they are already registered for a tournament you're already in.")
        })
        .onAppear {
            loadInvites()
            loadActivities()
        }
        .refreshable {
            loadInvites()
            loadActivities()
        }
    }
    
    private func loadInvites() {
        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int else {
            errorMessage = "Not logged in"; return
        }
        isLoading = true
        network.getPendingTeamInvites(userId: userId) { res in
            DispatchQueue.main.async {
                isLoading = false
                switch res {
                case .success(let data): invites = data
                case .failure(let err): errorMessage = err.localizedDescription
                }
            }
        }
    }
    
    private func respond(invite: TeamInviteModel, accept: Bool) {
        respondingIds.insert(invite.id)
        network.respondToInvite(inviteId: invite.id, accept: accept) { res in
            DispatchQueue.main.async {
                respondingIds.remove(invite.id)
                switch res {
                case .success:
                    loadInvites()
                case .failure(let err):
                    // Show the server-provided error (e.g., team in live tournament or conflict)
                    inviteErrorMessage = err.localizedDescription
                    showInviteErrorAlert = true
                }
            }
        }
    }

    private func loadActivities() {
        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int else { return }
        network.getActivities(userId: userId) { res in
            DispatchQueue.main.async {
                switch res {
                case .success(let data): activities = data
                case .failure: break
                }
            }
        }
    }

    private func groupedActivities() -> [(String, [NetworkManager.ActivityItem])] {
        // Group by day label: Today, Yesterday, or date
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        let out = DateFormatter()
        out.dateStyle = .medium
        out.timeStyle = .none

        let calendar = Calendar.current
        var groups: [String: [NetworkManager.ActivityItem]] = [:]
        for item in activities {
            let label: String
            if let ts = item.createdAt, let date = ISO8601DateFormatter().date(from: ts) ?? df.date(from: ts) {
                if calendar.isDateInToday(date) {
                    label = "Today"
                } else if calendar.isDateInYesterday(date) {
                    label = "Yesterday"
                } else {
                    label = out.string(from: date)
                }
            } else {
                label = "Earlier"
            }
            groups[label, default: []].append(item)
        }
        // Sort by date recency for sections
        let ordered = groups.keys.sorted { lhs, rhs in
            func keyDate(_ s: String) -> Date {
                if s == "Today" { return Date() }
                if s == "Yesterday" { return Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date() }
                return out.date(from: s) ?? Date.distantPast
            }
            return keyDate(lhs) > keyDate(rhs)
        }
        return ordered.map { ($0, groups[$0] ?? []) }
    }

    private struct ActivitySection: Identifiable {
        let id = UUID()
        let title: String
        let items: [NetworkManager.ActivityItem]
    }

    private func groupedSections() -> [ActivitySection] {
        let tuples = groupedActivities()
        return tuples.map { ActivitySection(title: $0.0, items: $0.1) }
    }

    private func sectionHeader(_ text: String) -> some View {
        HStack(spacing: 8) {
            Text(text.uppercased())
                .font(.caption)
                .foregroundColor(.gray)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
    private func shouldShow(_ item: NetworkManager.ActivityItem) -> Bool {
        switch filter {
        case .all:
            return true
        case .teams:
            return isTeamEvent(item.typeCode)
        case .invites:
            return false
        }
    }

    // MARK: - Unified feed (activities + invites)
    private enum FeedItem: Identifiable {
        case activity(NetworkManager.ActivityItem)
        case invite(TeamInviteModel)
        var id: String {
            switch self {
            case .activity(let a): return "a_\(a.id)"
            case .invite(let i): return "i_\(i.id)"
            }
        }
        var createdAt: String? {
            switch self {
            case .activity(let a): return a.createdAt
            case .invite(let i): return i.createdAt
            }
        }
    }

    private func combinedFeed() -> [FeedItem] {
        switch filter {
        case .all:
            let a = activities.map { FeedItem.activity($0) }
            let inv = invites.map { FeedItem.invite($0) }
            return a + inv
        case .teams:
            return activities.filter { isTeamEvent($0.typeCode) }.map { FeedItem.activity($0) }
        case .invites:
            return invites.map { FeedItem.invite($0) }
        }
    }

    private func combinedFeedFilteredSorted() -> [FeedItem] {
        func parseDate(_ s: String) -> Date? {
            if s.isEmpty { return nil }
            // Try ISO8601 with/without fractional seconds
            let isoFrac = ISO8601DateFormatter(); isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = isoFrac.date(from: s) { return d }
            let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime]
            if let d = iso.date(from: s) { return d }
            // Common backend formats
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
                "yyyy-MM-dd'T'HH:mm:ssXXXXX",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                // 6-digit fractional seconds without timezone (observed in invites previously)
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd HH:mm:ss"
            ]
            let df = DateFormatter(); df.locale = Locale(identifier: "en_US_POSIX")
            for f in formats {
                df.dateFormat = f
                // Assume UTC for naive timestamps (no timezone info)
                if !s.contains("Z") && !s.contains("+") && !s.contains("-") {
                    df.timeZone = TimeZone(secondsFromGMT: 0)
                } else {
                    df.timeZone = TimeZone(secondsFromGMT: 0)
                }
                if let d = df.date(from: s) { return d }
            }
            return nil
        }
        func date(for item: FeedItem) -> Date {
            let s = item.createdAt ?? ""
            return parseDate(s) ?? Date.distantPast
        }
        return combinedFeed().sorted { date(for: $0) > date(for: $1) }
    }

    private struct FeedSection: Identifiable {
        let id = UUID()
        let title: String
        let items: [FeedItem]
    }

    private func groupedFeedSections() -> [FeedSection] {
        let df1 = ISO8601DateFormatter()
        let df2 = DateFormatter()
        df2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        let out = DateFormatter()
        out.dateStyle = .medium
        out.timeStyle = .none
        let cal = Calendar.current

        var groups: [String: [FeedItem]] = [:]
        for item in combinedFeed() {
            let label: String
            if let ts = item.createdAt, let date = df1.date(from: ts) ?? df2.date(from: ts) {
                if cal.isDateInToday(date) { label = "Today" }
                else if cal.isDateInYesterday(date) { label = "Yesterday" }
                else { label = out.string(from: date) }
            } else {
                label = "Earlier"
            }
            groups[label, default: []].append(item)
        }
        func keyDate(_ s: String) -> Date {
            if s == "Today" { return Date() }
            if s == "Yesterday" { return Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date() }
            return out.date(from: s) ?? Date.distantPast
        }
        let ordered = groups.keys.sorted { keyDate($0) > keyDate($1) }
        return ordered.map { FeedSection(title: $0, items: (groups[$0] ?? []).sorted(by: { (lhs, rhs) in
            let d1s = lhs.createdAt ?? ""
            let d2s = rhs.createdAt ?? ""
            let dfIso = ISO8601DateFormatter()
            let dfAlt = DateFormatter(); dfAlt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            let d1 = dfIso.date(from: d1s) ?? dfAlt.date(from: d1s) ?? Date.distantPast
            let d2 = dfIso.date(from: d2s) ?? dfAlt.date(from: d2s) ?? Date.distantPast
            return d1 > d2
        })) }
    }

    private func shouldShowFeed(_ item: FeedItem) -> Bool {
        switch filter {
        case .all:
            return true
        case .teams:
            if case .activity(let a) = item { return isTeamEvent(a.typeCode) } else { return false }
        case .invites:
            switch item { case .invite: return true; default: return false }
        }
    }
}

private enum ActivityFilter { case all, teams, invites }

private func isTeamEvent(_ typeCode: String) -> Bool {
    switch typeCode {
    case "TEAM_REGISTERED_TOURNAMENT", "TEAM_MEMBER_ADDED", "TEAM_MEMBER_LEFT", "TEAM_DELETED", "TOURNAMENT_BRACKET_AVAILABLE", "TOURNAMENT_STARTS_SOON", "MATCH_RESULT_WIN", "MATCH_RESULT_LOSS", "TOURNAMENT_COMPLETED", "TOURNAMENT_WINNER":
        return true
    default:
        return false
    }
}

    private struct ActivityRow: View {
    let message: String
    let typeCode: String
    let createdAt: String?
    let teamId: Int?
    let teamName: String?
    let actorUserId: Int?
    let actorUsername: String?
    let tournamentId: Int?
    let tournamentName: String?
    let onTeamTap: ((Int) -> Void)?
    let onUserTap: ((Int) -> Void)?
    let onTournamentTap: ((Int) -> Void)?
        var payloadJSON: String? = nil
    
    @State private var resolvedTeamName: String? = nil
    private static var teamNameCache: [Int: String] = [:]
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [ModernColorScheme.accentMinimal.opacity(0.18), ModernColorScheme.accentMinimal.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                Image(systemName: iconName(for: typeCode))
                    .foregroundColor(ModernColorScheme.accentMinimal)
            }
            VStack(alignment: .leading, spacing: 8) {
                // Tag row: team + tournament pills side by side
                HStack(spacing: 8) {
                    // Team pill
                    let pillText: String = {
                        if let name = teamName ?? resolvedTeamName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return name }
                        if let id = teamId { return "Team #\(id)" }
                        return "Deleted Team"
                    }()
                    Group {
                        if let id = teamId {
                            Button(action: { onTeamTap?(id) }) { teamPill(pillText) }
                                .buttonStyle(PlainButtonStyle())
                        } else {
                            teamPill(pillText)
                        }
                    }
                    // Tournament pill
                    if let tid = tournamentId {
                        Button(action: { onTournamentTap?(tid) }) { tournamentPill(tournamentName ?? "Tournament #\(tid)") }
                            .buttonStyle(PlainButtonStyle())
                    }
                }
                messageView
                    .foregroundColor(ModernColorScheme.text)
                if let createdAt = createdAt {
                    Text(relativeTime(createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ModernColorScheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ModernColorScheme.accentMinimal.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .onAppear {
            if let teamId = teamId { loadTeamNameIfNeeded(teamId: teamId) }
        }
    }
    
    private func loadTeamNameIfNeeded(teamId: Int) {
        if let cached = Self.teamNameCache[teamId] {
            resolvedTeamName = cached
            return
        }
        NetworkManager().getTeamById(teamId: teamId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let team):
                    Self.teamNameCache[teamId] = team.name
                    resolvedTeamName = team.name
                case .failure:
                    break
                }
            }
        }
    }

    @ViewBuilder
    private var messageView: some View {
        if typeCode == "TEAM_MEMBER_LEFT" || typeCode == "TEAM_MEMBER_ADDED" {
            if let actorUserId = actorUserId {
                HStack(spacing: 4) {
                    Button(action: { onUserTap?(actorUserId) }) {
                        Text(verbatim: "@" + (actorUsername ?? "user"))
                            .foregroundColor(ModernColorScheme.accentMinimal)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Text(cleanedMessage())
                }
            } else {
                Text(cleanedMessage())
            }
        } else if typeCode == "TEAM_REGISTERED_TOURNAMENT", let tid = tournamentId {
            HStack(spacing: 4) {
                Text("registered for")
                Button(action: { onTournamentTap?(tid) }) {
                    Text(tournamentName ?? "Tournament #\(tid)")
                        .foregroundColor(ModernColorScheme.accentMinimal)
                }
                .buttonStyle(PlainButtonStyle())
            }
        } else if (typeCode == "TOURNAMENT_BRACKET_AVAILABLE" || typeCode == "TOURNAMENT_STARTS_SOON"), let tid = tournamentId {
            HStack(spacing: 4) {
                if typeCode == "TOURNAMENT_BRACKET_AVAILABLE" { Text("bracket is now available for") } else { Text("tournament starts soon:") }
                Button(action: { onTournamentTap?(tid) }) {
                    Text(tournamentName ?? "Tournament #\(tid)")
                        .foregroundColor(ModernColorScheme.accentMinimal)
                }
                .buttonStyle(PlainButtonStyle())
            }
        } else if typeCode == "MATCH_RESULT_WIN" || typeCode == "MATCH_RESULT_LOSS" {
            let info = parseMatchPayload(payloadJSON)
            HStack(spacing: 4) {
                Text(typeCode == "MATCH_RESULT_WIN" ? "defeated" : "lost to")
                if let oppId = info.opponentTeamId {
                    Button(action: { onTeamTap?(oppId) }) {
                        Text(info.opponentTeamName ?? "Team #\(oppId)")
                            .foregroundColor(ModernColorScheme.accentMinimal)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Text("opponent")
                }
                Text("\(info.scoreFor)-\(info.scoreAgainst)")
            }
        } else if typeCode == "TOURNAMENT_COMPLETED", let tid = tournamentId {
            HStack(spacing: 4) {
                Text("tournament over. winner:")
                let winner = parseWinnerPayload(payloadJSON)
                if let winId = winner.id {
                    Button(action: { onTeamTap?(winId) }) {
                        Text(winner.name ?? "Team #\(winId)")
                            .foregroundColor(ModernColorScheme.accentMinimal)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Text("TBD")
                }
            }
        } else {
            Text(cleanedMessage())
        }
    }

    private func parseMatchPayload(_ json: String?) -> (opponentTeamId: Int?, opponentTeamName: String?, scoreFor: Int, scoreAgainst: Int) {
        guard let json = json, let data = json.data(using: .utf8) else {
            return (nil, nil, 0, 0)
        }
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let opp: Int? = {
                if let n = obj["opponent_team_id"] as? NSNumber { return n.intValue }
                return obj["opponent_team_id"] as? Int
            }()
            let oppName = obj["opponent_team_name"] as? String
            let sf: Int = {
                if let n = obj["score_for"] as? NSNumber { return n.intValue }
                return obj["score_for"] as? Int ?? 0
            }()
            let sa: Int = {
                if let n = obj["score_against"] as? NSNumber { return n.intValue }
                return obj["score_against"] as? Int ?? 0
            }()
            return (opp, oppName, sf, sa)
        }
        return (nil, nil, 0, 0)
    }

    private func parseWinnerPayload(_ json: String?) -> (id: Int?, name: String?) {
        guard let json = json, let data = json.data(using: .utf8) else { return (nil, nil) }
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let id: Int? = {
                if let n = obj["winner_team_id"] as? NSNumber { return n.intValue }
                return obj["winner_team_id"] as? Int
            }()
            let name = obj["winner_team_name"] as? String
            return (id, name)
        }
        return (nil, nil)
    }

    private func cleanedMessage() -> String {
        var text = message
        // Remove any leading ">" characters and whitespace that might slip in from server
        while text.hasPrefix(">") || text.hasPrefix("›") || text.hasPrefix("→") {
            text.removeFirst()
            text = text.trimmingCharacters(in: .whitespaces)
        }
        return text
    }

    // Removed complex splitting; message constructed inline for clarity.
    
    private func relativeTime(_ iso: String) -> String {
        let iso1 = ISO8601DateFormatter()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        let date = iso1.date(from: iso) ?? df.date(from: iso)
        guard let d = date else { return iso }
        let rel = RelativeDateTimeFormatter()
        rel.unitsStyle = .short
        return rel.localizedString(for: d, relativeTo: Date())
    }
    
    private func iconName(for typeCode: String) -> String {
        switch typeCode {
        case "TEAM_REGISTERED_TOURNAMENT": return "trophy"
        case "TEAM_MEMBER_ADDED": return "person.badge.plus"
        case "TEAM_MEMBER_LEFT": return "person.fill.xmark"
        case "TEAM_DELETED": return "trash"
        case "TOURNAMENT_BRACKET_AVAILABLE": return "square.grid.3x3"
        case "TOURNAMENT_STARTS_SOON": return "clock"
        case "MATCH_RESULT_WIN": return "checkmark.seal.fill"
        case "MATCH_RESULT_LOSS": return "xmark.seal.fill"
        case "TOURNAMENT_COMPLETED": return "flag.checkered"
        default: return "bell"
        }
    }
    
    private func isTeamEvent(_ typeCode: String) -> Bool {
        switch typeCode {
        case "TEAM_REGISTERED_TOURNAMENT", "TEAM_MEMBER_ADDED", "TEAM_MEMBER_LEFT", "TEAM_DELETED":
            return true
        default:
            return false
        }
    }
}

private struct InviteRow: View {
    let invite: TeamInviteModel
    let isResponding: Bool
    let acceptAction: () -> Void
    let declineAction: () -> Void
    let onTeamTap: ((Int) -> Void)?
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [ModernColorScheme.accentMinimal.opacity(0.18), ModernColorScheme.accentMinimal.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                Image(systemName: "envelope.fill")
                    .foregroundColor(ModernColorScheme.accentMinimal)
            }
            VStack(alignment: .leading, spacing: 6) {
                Button(action: { onTeamTap?(invite.teamId) }) {
                    teamPill(invite.teamName ?? "Team #\(invite.teamId)")
                }
                .buttonStyle(PlainButtonStyle())
                Text("invited you")
                    .foregroundColor(ModernColorScheme.text)
                Text(invite.status)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Button("Decline") { declineAction() }
                    .buttonStyle(.bordered)
                    .disabled(isResponding)
                Button("Accept") { acceptAction() }
                    .buttonStyle(.borderedProminent)
                    .disabled(isResponding)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ModernColorScheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ModernColorScheme.accentMinimal.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - UI helpers
private func teamPill(_ text: String) -> some View {
    HStack(spacing: 6) {
        Image(systemName: "person.3.fill")
        Text(text)
    }
    .font(ModernFontScheme.caption)
    .padding(.horizontal, 10)
    .padding(.vertical, 4)
    .background(ModernColorScheme.accentMinimal.opacity(0.15))
    .foregroundColor(ModernColorScheme.accentMinimal)
    .cornerRadius(10)
}

private func tournamentPill(_ text: String) -> some View {
    HStack(spacing: 6) {
        Image(systemName: "trophy")
        Text(text)
    }
    .font(ModernFontScheme.caption)
    .padding(.horizontal, 10)
    .padding(.vertical, 4)
    .background(ModernColorScheme.accentMinimal.opacity(0.15))
    .foregroundColor(ModernColorScheme.accentMinimal)
    .cornerRadius(10)
}


