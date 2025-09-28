import SwiftUI

struct RegisterTournamentView: View {
    let tournament: Tournament
    let onRegistered: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var teams: [TeamModel] = []
    @State private var selectedTeamId: Int?
    @State private var registeredTeamIds: Set<Int> = []
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var searchText: String = ""
    private let network = NetworkManager()
    @State private var showTeamDetail: Bool = false
    @State private var teamForDetail: TeamModel? = nil
    
    private var captainTeams: [TeamModel] {
        let userId = UserDefaults.standard.integer(forKey: "loggedInUserId")
        return teams.filter { $0.ownerUserId == userId }
    }

    private var filteredTeams: [TeamModel] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return captainTeams }
        return captainTeams.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header card aligned with app style (surface + subtle shadow)
            VStack(alignment: .leading, spacing: 12) {
                Text("Register for")
                    .font(ModernFontScheme.caption)
                    .foregroundColor(ModernColorScheme.textSecondary)
                Text(tournament.name)
                    .font(ModernFontScheme.heading)
                    .foregroundColor(ModernColorScheme.text)
                HStack(spacing: 8) {
                    InfoPill(text: "\(tournament.formatSize)v\(tournament.formatSize)", systemImage: "circle.grid.2x2", color: ModernColorScheme.accentMinimal)
                    InfoPill(text: "Max \(tournament.maxTeams)", systemImage: "person.3", color: ModernColorScheme.accentMinimal)
                    InfoPill(text: deadlineShort(tournament.signupDeadline), systemImage: "calendar", color: ModernColorScheme.accentMinimal)
                }
                .padding(.top, 2)
                if let success = successMessage {
                    Text(success)
                        .font(ModernFontScheme.caption)
                        .foregroundColor(.green)
                }
                if let err = errorMessage {
                    Text(err)
                        .font(ModernFontScheme.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ModernColorScheme.surface)
            .cornerRadius(18)
            .shadow(color: ModernColorScheme.primary.opacity(0.1), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
            .padding(.top)

            // Search field under header
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ModernColorScheme.textSecondary)
                TextField("Search your teams", text: $searchText)
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.text)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ModernColorScheme.textSecondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(ModernColorScheme.surface)
            .cornerRadius(14)
            .padding(.horizontal)
            .padding(.top, 8)

            List {
                Section(header: Text("Your Teams")) {
                    if captainTeams.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 28))
                                .foregroundColor(ModernColorScheme.accentMinimal)
                                .padding(8)
                                .background(ModernColorScheme.primary.opacity(0.12))
                                .clipShape(Circle())
                            Text("You’re not the captain of any teams")
                                .font(ModernFontScheme.body)
                                .foregroundColor(ModernColorScheme.text)
                            Text("Create a team to register for this tournament")
                                .font(ModernFontScheme.caption)
                                .foregroundColor(ModernColorScheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .listRowBackground(ModernColorScheme.surface)
                    } else {
                        ForEach(filteredTeams) { team in
                            let isAlreadyRegistered = registeredTeamIds.contains(team.id)
                            ZStack {
                                let isSelected = selectedTeamId == team.id
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(ModernColorScheme.surface)
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? ModernColorScheme.accentMinimal : Color.clear, lineWidth: isSelected ? 2 : 0)
                                HStack(spacing: 12) {
                                    // Left selectable area
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle().fill(ModernColorScheme.primary.opacity(0.15)).frame(width: 40, height: 40)
                                            Image(systemName: "person.3.fill").foregroundColor(ModernColorScheme.accentMinimal)
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(team.name)
                                                .font(ModernFontScheme.body)
                                                .foregroundColor(ModernColorScheme.text)
                                            if isAlreadyRegistered {
                                                Text("Already registered")
                                                    .font(ModernFontScheme.caption)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        Spacer()
                                        if isAlreadyRegistered {
                                            Text("Registered")
                                                .font(ModernFontScheme.caption)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.blue.opacity(0.7))
                                                .clipShape(Capsule())
                                        } else if selectedTeamId == team.id {
                                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if !isAlreadyRegistered {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                                selectedTeamId = team.id
                                            }
                                        }
                                    }

                                    // Trailing navigation-only button
                                    Button(action: {
                                        teamForDetail = team
                                        showTeamDetail = true
                                    }) {
                                        Text("View Team")
                                            .font(ModernFontScheme.caption)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(ModernColorScheme.accentMinimal)
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(10)
                            }
                            .listRowInsets(EdgeInsets())
                            .padding(.vertical, 6)
                            .listRowBackground(Color.clear)
                            .shadow(color: ModernColorScheme.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)

            VStack(spacing: 10) {
                Button(action: register) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Register Selected Team")
                            .font(ModernFontScheme.body)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedTeamId == nil ? ModernColorScheme.accentMinimal.opacity(0.4) : ModernColorScheme.accentMinimal)
                    .shadow(color: ModernColorScheme.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(selectedTeamId == nil)
                .animation(.easeInOut(duration: 0.2), value: selectedTeamId)
            }
            .padding()
            .background(ModernColorScheme.background.opacity(0.95))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadData)
        .sheet(isPresented: $showTeamDetail, onDismiss: { teamForDetail = nil }) {
            if let team = teamForDetail {
                NavigationStack {
                    TeamDetailedView(team: team)
                        .navigationTitle("Team")
                        .navigationBarTitleDisplayMode(.inline)
                }
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Formatting helpers
    private func deadlineShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    init(tournament: Tournament, onRegistered: (() -> Void)? = nil) {
        self.tournament = tournament
        self.onRegistered = onRegistered
    }

    // Small pill used in the header to show quick facts
    private struct InfoPill: View {
        let text: String
        let systemImage: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(text)
                    .font(ModernFontScheme.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.15))
            .clipShape(Capsule())
        }
    }

    private func loadData() {
        let userId = UserDefaults.standard.integer(forKey: "loggedInUserId")
        NetworkManager().getTeamsForUser(userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let allTeams):
                    // Show all teams, but only captains are selectable
                    self.teams = allTeams
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                }
            }
        }
        network.getTournamentEligibility(tournamentId: tournament.id, userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.registeredTeamIds = Set(data.registeredTeamIds)
                case .failure:
                    break
                }
            }
        }
    }

    private func register() {
        guard let teamId = selectedTeamId else { return }
        let userId = UserDefaults.standard.integer(forKey: "loggedInUserId")
        network.registerTeamForTournament(tournamentId: tournament.id, teamId: teamId, requestingUserId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.successMessage = "Team registered!"
                    self.errorMessage = nil
                    self.registeredTeamIds.insert(teamId)
                    self.onRegistered?()
                    self.dismiss()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.successMessage = nil
                }
            }
        }
    }
}

struct RegisterTournamentView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterTournamentView(tournament: Tournament(id: 1, name: "Sample", formatSize: 3, maxTeams: 16, entryFeeCents: nil, depositHoldCents: nil, currency: "CAD", prizeCents: nil, signupDeadline: Date(), startsAt: Date(), endsAt: nil, location: "Some Gym", status: .signupsOpen))
    }
}


