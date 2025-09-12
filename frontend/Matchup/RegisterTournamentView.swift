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
        VStack(spacing: 16) {
            Text("Register for \(tournament.name)")
                .font(ModernFontScheme.heading)
                .foregroundColor(ModernColorScheme.text)
            if let success = successMessage {
                Text(success).foregroundColor(.green)
            }
            if let err = errorMessage {
                Text(err).foregroundColor(.red)
            }

            List {
                ForEach(teams) { team in
                    let isCaptain = team.ownerUserId == (UserDefaults.standard.integer(forKey: "loggedInUserId"))
                    let isIneligible = !isCaptain
                    let isAlreadyRegistered = registeredTeamIds.contains(team.id)
                    HStack {
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
                }
            }

            Button(action: register) {
                Text("Register Selected Team")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedTeamId == nil)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
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


