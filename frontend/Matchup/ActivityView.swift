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
                                        Text("Teams").tag(ActivityFilter.teams)
                                        Text("Invites").tag(ActivityFilter.invites)
                                    }
                                    .pickerStyle(.segmented)
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
                                if !activities.isEmpty {
                                    ForEach(groupedSections()) { section in
                                        VStack(alignment: .leading, spacing: 8) {
                                            sectionHeader(section.title)
                                                .padding(.horizontal, 16)
                                            ForEach(section.items.filter { shouldShow($0) }) { item in
                                                ActivityRow(
                                                    message: item.message ?? "",
                                                    typeCode: item.typeCode,
                                                    createdAt: item.createdAt,
                                                    teamId: item.teamId,
                                                    teamName: item.teamName,
                                                    actorUserId: item.actorUserId,
                                                    actorUsername: item.actorUsername,
                                                    tournamentId: item.tournamentId,
                                                    tournamentName: item.tournamentName,
                                                    onTeamTap: { id in navPath.append(ActivityRoute.team(id)) },
                                                    onUserTap: { id in navPath.append(ActivityRoute.user(id)) },
                                                    onTournamentTap: { id in navPath.append(ActivityRoute.tournament(id)) }
                                                )
                                                .padding(.horizontal, 16)
                                            }
                                        }
                                    }
                                }

                                // Invites
                                if !invites.isEmpty && (filter == .all || filter == .invites) {
                                    Text("Invites")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16)
                                    ForEach(invites) { invite in
                                        InviteRow(
                                            invite: invite,
                                            isResponding: respondingIds.contains(invite.id),
                                            acceptAction: { respond(invite: invite, accept: true) },
                                            declineAction: { respond(invite: invite, accept: false) }
                                        )
                                        .padding(.horizontal, 16)
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
        network.respondToInvite(inviteId: invite.id, accept: accept) { _ in
            DispatchQueue.main.async {
                respondingIds.remove(invite.id)
                loadInvites()
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
}

private enum ActivityFilter { case all, teams, invites }

private func isTeamEvent(_ typeCode: String) -> Bool {
    switch typeCode {
    case "TEAM_REGISTERED_TOURNAMENT", "TEAM_MEMBER_ADDED", "TEAM_MEMBER_LEFT", "TEAM_DELETED":
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
                // Always show team pill: clickable if teamId exists, otherwise static (e.g., deleted team)
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
        } else {
            Text(cleanedMessage())
        }
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
                teamPill(invite.teamName ?? "Team #\(invite.teamId)")
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


