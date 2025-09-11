import SwiftUI

struct TeamDetailedView: View {
    let team: TeamModel
    @State private var members: [TeamMemberModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var userNames: [Int: String] = [:]
    private let network = NetworkManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
                .padding(.horizontal)
                .padding(.top)
            
            HStack {
                NavigationLink(destination: InviteUsersView(team: team)) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Invite Users")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(ModernColorScheme.primary.opacity(0.15))
                    .foregroundColor(ModernColorScheme.primary)
                    .cornerRadius(10)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            if isLoading && members.isEmpty {
                ProgressView().tint(ModernColorScheme.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(ModernColorScheme.textSecondary)
                    .padding()
            } else {
                List {
                    Section(header: Text("Roster")) {
                        ForEach(members) { member in
                            HStack {
                                Image(systemName: member.role == "CAPTAIN" ? "crown.fill" : "person.fill")
                                    .foregroundColor(member.role == "CAPTAIN" ? .yellow : ModernColorScheme.primary)
                                Text(member.username ?? userNames[member.userId] ?? "User #\(member.userId)")
                                Spacer()
                                Text(member.role.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            Spacer(minLength: 0)
        }
        .background(ModernColorScheme.background.ignoresSafeArea())
        .navigationTitle("Team")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadMembers() }
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
}


