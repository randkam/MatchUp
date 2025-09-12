import SwiftUI

struct ActivityView: View {
    @State private var invites: [TeamInviteModel] = []
    @State private var activities: [NetworkManager.ActivityItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var respondingIds: Set<Int> = []
    @State private var refreshTimer: Timer? = nil
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
                        Text("No activity right now")
                            .foregroundColor(ModernColorScheme.textSecondary)
                    } else {
                        List {
                            if !activities.isEmpty {
                                Section(header: Text("Updates")) {
                                    ForEach(activities) { item in
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: iconName(for: item.type)).foregroundColor(ModernColorScheme.accentMinimal)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.message).foregroundColor(ModernColorScheme.text)
                                                Text(item.createdAt ?? "").font(.caption).foregroundColor(.gray)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            if !invites.isEmpty {
                                Section(header: Text("Invites")) {
                                    ForEach(invites) { invite in
                                        HStack {
                                            Image(systemName: "envelope.fill").foregroundColor(ModernColorScheme.accentMinimal)
                                            VStack(alignment: .leading) {
                                                HStack(spacing: 8) {
                                                    teamPill(invite.teamName ?? "Team #\(invite.teamId)")
                                                    Text("invited you")
                                                }
                                                Text(invite.status)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            HStack(spacing: 8) {
                                                Button("Decline") { respond(invite: invite, accept: false) }
                                                    .buttonStyle(.bordered)
                                                    .disabled(respondingIds.contains(invite.id))
                                                Button("Accept") { respond(invite: invite, accept: true) }
                                                    .buttonStyle(.borderedProminent)
                                                    .disabled(respondingIds.contains(invite.id))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("Activity")
        }
        .onAppear {
            loadInvites()
            loadActivities()
            refreshTimer?.invalidate()
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
                loadInvites()
                loadActivities()
            }
        }
        .onDisappear { refreshTimer?.invalidate(); refreshTimer = nil }
        .refreshable { loadInvites() }
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

    private func iconName(for type: String) -> String {
        switch type {
        case "TEAM_REGISTERED": return "trophy"
        case "MEMBER_JOINED": return "person.badge.plus"
        case "MEMBER_LEFT": return "person.fill.xmark"
        case "TEAM_DELETED": return "trash"
        default: return "bell"
        }
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


