import SwiftUI

struct ActivityView: View {
    @State private var invites: [TeamInviteModel] = []
    @State private var activities: [NetworkManager.ActivityItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var filter: ActivityFilter = .all
    @State private var respondingIds: Set<Int> = []
    private let network = NetworkManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernColorScheme.background.ignoresSafeArea()
                Group {
                    if isLoading && invites.isEmpty {
                        ProgressView().tint(ModernColorScheme.primary)
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(ModernColorScheme.textSecondary)
                    } else if invites.isEmpty && activities.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "bell")
                                .font(.system(size: 36))
                                .foregroundColor(ModernColorScheme.accentMinimal)
                            Text("No activity right now")
                                .foregroundColor(ModernColorScheme.textSecondary)
                            Text("Pull to refresh")
                                .font(.caption)
                                .foregroundColor(ModernColorScheme.textSecondary)
                        }
                    } else {
                        List {
                            Section {
                                Picker("Filter", selection: $filter) {
                                    Text("All").tag(ActivityFilter.all)
                                    Text("Teams").tag(ActivityFilter.teams)
                                    Text("Invites").tag(ActivityFilter.invites)
                                }
                                .pickerStyle(.segmented)
                            }
                            .listRowBackground(ModernColorScheme.background)
                            .listRowSeparator(.hidden)
                            if !activities.isEmpty {
                                ForEach(groupedSections()) { section in
                                    Section(header: sectionHeader(section.title)) {
                                        ForEach(section.items.filter { shouldShow($0) }) { item in
                                            ActivityRow(message: item.message, type: item.type, createdAt: item.createdAt, teamId: item.teamId)
                                        }
                                    }
                                }
                            }
                            if !invites.isEmpty && (filter == .all || filter == .invites) {
                                Section(header: Text("Invites")) {
                                    ForEach(invites) { invite in
                                        InviteRow(invite: invite,
                                                  isResponding: respondingIds.contains(invite.id),
                                                  acceptAction: { respond(invite: invite, accept: true) },
                                                  declineAction: { respond(invite: invite, accept: false) })
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .listRowBackground(ModernColorScheme.surface)
                        .tint(ModernColorScheme.accentMinimal)
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .navigationTitle("Activity")
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
        Text(text.uppercased())
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.leading, -8)
    }
    private func shouldShow(_ item: NetworkManager.ActivityItem) -> Bool {
        switch filter {
        case .all:
            return true
        case .teams:
            return isTeamEvent(item.type)
        case .invites:
            return false
        }
    }
}

private enum ActivityFilter { case all, teams, invites }

private func isTeamEvent(_ type: String) -> Bool {
    switch type {
    case "TEAM_REGISTERED", "MEMBER_JOINED", "MEMBER_LEFT", "TEAM_DELETED":
        return true
    default:
        return false
    }
}

private struct ActivityRow: View {
    let message: String
    let type: String
    let createdAt: String?
    let teamId: Int?
    
    @State private var teamName: String? = nil
    private static var teamNameCache: [Int: String] = [:]
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(ModernColorScheme.accentMinimal.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: iconName(for: type)).foregroundColor(ModernColorScheme.accentMinimal)
            }
            VStack(alignment: .leading, spacing: 8) {
                if let teamId = teamId {
                    VStack(alignment: .leading, spacing: 8) {
                        teamPill(teamName ?? "Team #\(teamId)")
                        Divider()
                        Text(message)
                            .foregroundColor(ModernColorScheme.text)
                    }
                    .onAppear {
                        loadTeamNameIfNeeded(teamId: teamId)
                    }
                } else {
                    Text(message)
                        .foregroundColor(ModernColorScheme.text)
                }
                if let createdAt = createdAt {
                    Text(relativeTime(createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
        .listRowBackground(ModernColorScheme.surface)
    }
    
    private func loadTeamNameIfNeeded(teamId: Int) {
        if let cached = Self.teamNameCache[teamId] {
            teamName = cached
            return
        }
        NetworkManager().getTeamById(teamId: teamId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let team):
                    Self.teamNameCache[teamId] = team.name
                    teamName = team.name
                case .failure:
                    break
                }
            }
        }
    }
    
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
    
    private func iconName(for type: String) -> String {
        switch type {
        case "TEAM_REGISTERED": return "trophy"
        case "MEMBER_JOINED": return "person.badge.plus"
        case "MEMBER_LEFT": return "person.fill.xmark"
        case "TEAM_DELETED": return "trash"
        default: return "bell"
        }
    }
    
    private func isTeamEvent(_ type: String) -> Bool {
        switch type {
        case "TEAM_REGISTERED", "MEMBER_JOINED", "MEMBER_LEFT", "TEAM_DELETED":
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
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "envelope.fill").foregroundColor(ModernColorScheme.accentMinimal)
            VStack(alignment: .leading, spacing: 6) {
                teamPill(invite.teamName ?? "Team #\(invite.teamId)")
                Text("invited you")
                    .foregroundColor(ModernColorScheme.text)
                Text(invite.status)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            HStack(spacing: 8) {
                Button("Decline") { declineAction() }
                    .buttonStyle(.bordered)
                    .disabled(isResponding)
                Button("Accept") { acceptAction() }
                    .buttonStyle(.borderedProminent)
                    .disabled(isResponding)
            }
        }
        .listRowBackground(ModernColorScheme.surface)
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


