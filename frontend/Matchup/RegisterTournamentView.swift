import SwiftUI

struct RegisterTournamentView: View {
    let tournament: Tournament
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Register for \(tournament.name)")
                .font(ModernFontScheme.heading)
                .foregroundColor(ModernColorScheme.text)
            Text("Registration page coming soon.")
                .font(ModernFontScheme.body)
                .foregroundColor(ModernColorScheme.textSecondary)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RegisterTournamentView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterTournamentView(tournament: Tournament(id: 1, name: "Sample", formatSize: 3, maxTeams: 16, entryFeeCents: nil, depositHoldCents: nil, currency: "CAD", prizeCents: nil, signupDeadline: Date(), startsAt: Date(), endsAt: nil, location: "Some Gym", status: .signupsOpen))
    }
}


