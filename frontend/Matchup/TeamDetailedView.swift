import SwiftUI

struct TeamDetailedView: View {
    let team: TeamModel
    @State private var members: [TeamMemberModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var userNames: [Int: String] = [:]
    @State private var actionError: String? = nil
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
                    .background(ModernColorScheme.accentMinimal.opacity(0.15))
                    .foregroundColor(ModernColorScheme.accentMinimal)
                    .cornerRadius(10)
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
                            HStack {
                                Image(systemName: member.role == "CAPTAIN" ? "crown.fill" : "person.fill")
                                    .foregroundColor(member.role == "CAPTAIN" ? .yellow : ModernColorScheme.accentMinimal)
                                Text(member.username ?? userNames[member.userId] ?? "User #\(member.userId)")
                                Spacer()
                                Text(member.role.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    Section {
                        if let actionError = actionError {
                            Text(actionError).foregroundColor(.red)
                        }
                        actionButtons
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

    private var actionButtons: some View {
        let loggedInUserId = UserDefaults.standard.integer(forKey: "loggedInUserId")
        let isCaptain = team.ownerUserId == loggedInUserId
        return HStack {
            if isCaptain {
                Button(role: .destructive) {
                    network.delete("\(APIConfig.teamsEndpoint)/\(team.id)?requesting_user_id=\(loggedInUserId)") { err in
                        DispatchQueue.main.async {
                            if let err = err { actionError = err.localizedDescription } else { actionError = "Team deleted" }
                        }
                    }
                } label: {
                    Label("Delete Team", systemImage: "trash")
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
}


