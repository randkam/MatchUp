import SwiftUI

struct TeamsView: View {
    @State private var teams: [TeamModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showingCreate = false
    private let network = NetworkManager()
    @State private var searchText: String = ""
    
    private var filteredTeams: [TeamModel] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty { return teams }
        return teams.filter { team in
            team.name.range(of: query, options: .caseInsensitive) != nil
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernColorScheme.background.ignoresSafeArea()
                Group {
                    if isLoading && teams.isEmpty {
                        ProgressView().tint(ModernColorScheme.primary)
                    } else if let errorMessage = errorMessage {
                        VStack(spacing: 10) {
                            Text("Failed to load teams")
                                .font(ModernFontScheme.heading)
                                .foregroundColor(ModernColorScheme.text)
                            Text(errorMessage)
                                .font(ModernFontScheme.body)
                                .foregroundColor(ModernColorScheme.textSecondary)
                            Button("Retry") { loadTeams() }
                                .buttonStyle(.bordered)
                        }
                        .padding()
                    } else if teams.isEmpty {
                        Text("No teams yet. Create one!")
                            .font(ModernFontScheme.body)
                            .foregroundColor(ModernColorScheme.textSecondary)
                    } else {
                        if filteredTeams.isEmpty && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("No matching teams")
                                .font(ModernFontScheme.body)
                                .foregroundColor(ModernColorScheme.textSecondary)
                                .padding()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(filteredTeams) { team in
                                        NavigationLink(destination: TeamDetailedView(team: team)) {
                                            TeamCard(team: team)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Teams")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search teams")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreate = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateTeamSheet { name in
                    createTeam(name: name)
                }
            }
        }
        .onAppear { loadTeams() }
    }
    
    private func loadTeams() {
        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int else {
            errorMessage = "Not logged in"
            return
        }
        isLoading = true
        errorMessage = nil
        network.getTeamsForUser(userId: userId) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let teamsResp):
                    teams = teamsResp
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        }
    }
    
    private func createTeam(name: String) {
        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int else { return }
        network.createTeam(name: name, ownerUserId: userId, logoUrl: nil) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let team):
                    teams.insert(team, at: 0)
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        }
    }
}

private struct TeamCard: View {
    let team: TeamModel
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(ModernColorScheme.primary.opacity(0.15)).frame(width: 46, height: 46)
                Image(systemName: "person.3.fill").foregroundColor(ModernColorScheme.accentMinimal)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.text)
                Text("Basketball")
                    .font(ModernFontScheme.caption)
                    .foregroundColor(ModernColorScheme.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(16)
        .shadow(color: ModernColorScheme.primary.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

private struct CreateTeamSheet: View {
    @Environment(\ .dismiss) private var dismiss
    @State private var name: String = ""
    let onCreate: (String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Team Info")) {
                    TextField("Team name", text: $name)
                }
                Section(footer: Text("Sport set to Basketball; logo can be added later.")) {
                    EmptyView()
                }
            }
            .navigationTitle("New Team")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onCreate(name)
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}


