import SwiftUI

struct TournamentsView: View {
    @State private var tournaments: [Tournament] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var page: Int = 0
    @State private var hasMorePages: Bool = true
    private let pageSize: Int = 20
    private let network = NetworkManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernColorScheme.background
                    .ignoresSafeArea()
                Group {
                    if isLoading && tournaments.isEmpty {
                        ProgressView()
                            .tint(ModernColorScheme.primary)
                    } else if let errorMessage = errorMessage {
                        VStack(spacing: 12) {
                            Text("Failed to load tournaments")
                                .font(ModernFontScheme.heading)
                                .foregroundColor(ModernColorScheme.text)
                            Text(errorMessage)
                                .font(ModernFontScheme.body)
                                .foregroundColor(ModernColorScheme.textSecondary)
                            Button("Retry") { reload() }
                                .buttonStyle(.bordered)
                        }
                        .padding()
                    } else if tournaments.isEmpty {
                        Text("No upcoming tournaments yet")
                            .font(ModernFontScheme.body)
                            .foregroundColor(ModernColorScheme.textSecondary)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(tournaments) { t in
                                    NavigationLink(destination: TournamentDetailView(tournament: t)) {
                                        TournamentCard(tournament: t)
                                            .padding(.horizontal)
                                            .onAppear { loadMoreIfNeeded(current: t) }
                                    }
                                }
                                if isLoading && hasMorePages {
                                    ProgressView().tint(ModernColorScheme.primary)
                                }
                            }
                            .padding(.vertical)
                        }
                        .refreshable { reload() }
                    }
                }
            }
            .navigationTitle("Tournaments")
        }
        .onAppear {
            if tournaments.isEmpty { fetchPage(reset: true) }
        }
    }
    
    private func reload() {
        fetchPage(reset: true)
    }
    
    private func fetchPage(reset: Bool) {
        if reset {
            page = 0
            tournaments = []
            hasMorePages = true
        }
        guard hasMorePages, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        network.getUpcomingTournaments(page: page, size: pageSize) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    if page == 0 { tournaments = response.content } else { tournaments.append(contentsOf: response.content) }
                    hasMorePages = !response.last
                    page += 1
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadMoreIfNeeded(current: Tournament) {
        guard let idx = tournaments.firstIndex(where: { $0.id == current.id }) else { return }
        let threshold = tournaments.index(tournaments.endIndex, offsetBy: -5)
        if idx == threshold { fetchPage(reset: false) }
    }
}

private struct TournamentCard: View {
    let tournament: Tournament
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(tournament.name)
                    .font(ModernFontScheme.heading)
                    .foregroundColor(ModernColorScheme.text)
                Spacer()
                Text(startDate)
                    .font(ModernFontScheme.caption)
                    .foregroundColor(ModernColorScheme.textSecondary)
            }
            HStack(spacing: 12) {
                label(icon: "figure.basketball", text: "\(tournament.formatSize)v\(tournament.formatSize)")
                label(icon: "person.3", text: "Max \(tournament.maxTeams) teams")
            }
            HStack(spacing: 12) {
                if let fee = tournament.entryFeeCents, fee > 0 {
                    pill(icon: "dollarsign.circle", text: priceString(cents: fee, currency: tournament.currency ?? "CAD"), color: .orange)
                } else {
                    pill(icon: "gift", text: "Free Entry", color: .green)
                }
                if let prize = tournament.prizeCents, prize > 0 {
                    pill(icon: "trophy", text: priceString(cents: prize, currency: tournament.currency ?? "CAD"), color: .yellow)
                }
            }
        }
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(16)
        .shadow(color: ModernColorScheme.primary.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func label(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(ModernColorScheme.primary)
            Text(text)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
        }
    }
    
    private func pill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(ModernFontScheme.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .cornerRadius(10)
    }
    
    private var startDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: tournament.startsAt)
    }
    
    private func priceString(cents: Int, currency: String) -> String {
        let amount = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }
}

