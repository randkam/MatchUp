import SwiftUI

struct ActivityView: View {
    @State private var invites: [TeamInviteModel] = []
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
                    } else if invites.isEmpty {
                        Text("No activity right now")
                            .foregroundColor(ModernColorScheme.textSecondary)
                    } else {
                        List(invites) { invite in
                            HStack {
                                Image(systemName: "envelope.fill").foregroundColor(ModernColorScheme.primary)
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
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("Activity")
        }
        .onAppear {
            loadInvites()
            refreshTimer?.invalidate()
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
                loadInvites()
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
    .background(ModernColorScheme.primary.opacity(0.12))
    .foregroundColor(ModernColorScheme.primary)
    .cornerRadius(10)
}


