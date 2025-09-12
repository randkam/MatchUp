import SwiftUI

struct RegisterTournamentView: View {
    let tournament: Tournament
    @State private var teams: [TeamModel] = []
    @State private var selectedTeamId: Int?
    @State private var ineligibleTeamIds: Set<Int> = []
    @State private var registeredTeamIds: Set<Int> = []
    @State private var errorMessage: String?
    @State private var successMessage: String?
    private let network = NetworkManager()
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Register for")
                    .font(ModernFontScheme.caption)
                    .foregroundColor(ModernColorScheme.textSecondary)
                Text(tournament.name)
                    .font(ModernFontScheme.heading)
                    .foregroundColor(ModernColorScheme.text)
                if let success = successMessage {
                    Text(success).foregroundColor(.green)
                }
                if let err = errorMessage {
                    Text(err).foregroundColor(.red)
                }
            }
            .padding()

            List {
                Section(header: Text("Your Teams")) {
                    ForEach(teams) { team in
                        let isCaptain = team.ownerUserId == (UserDefaults.standard.integer(forKey: "loggedInUserId"))
                        let isIneligible = !isCaptain
                        let isAlreadyRegistered = registeredTeamIds.contains(team.id)
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(ModernColorScheme.primary.opacity(0.15)).frame(width: 36, height: 36)
                                Image(systemName: "person.3.fill").foregroundColor(ModernColorScheme.accentMinimal)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(team.name)
                                    .font(ModernFontScheme.body)
                                    .foregroundColor(ModernColorScheme.text)
                                if isIneligible {
                                    Text("You are not the captain of this team")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                if isAlreadyRegistered {
                                    Text("Team already registered for this tournament")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            Spacer()
                            if selectedTeamId == team.id {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !isIneligible && !isAlreadyRegistered {
                                selectedTeamId = team.id
                            }
                        }
                        .padding(6)
                        .listRowBackground(ModernColorScheme.surface)
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
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red, lineWidth: 2))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(selectedTeamId == nil)
            }
            .padding()
            .background(ModernColorScheme.background.opacity(0.95))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadData)
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


