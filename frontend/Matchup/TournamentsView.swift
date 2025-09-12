import SwiftUI

struct TournamentsView: View {
    @State private var tournaments: [Tournament] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var page: Int = 0
    @State private var hasMorePages: Bool = true
    @State private var query: String = ""
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
                            .tint(ModernColorScheme.brandBlue)
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
                        VStack(spacing: 10) {
                            Image(systemName: "trophy")
                                .font(.system(size: 36))
                                .foregroundColor(ModernColorScheme.accentMinimal)
                            Text("No upcoming tournaments yet")
                                .font(ModernFontScheme.body)
                                .foregroundColor(ModernColorScheme.textSecondary)
                            Text("Pull to refresh later")
                                .font(ModernFontScheme.caption)
                                .foregroundColor(ModernColorScheme.textSecondary)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredTournaments) { t in
                                    NavigationLink(destination: TournamentDetailView(tournament: t)) {
                                        TournamentCard(tournament: t)
                                            .padding(.horizontal)
                                            .onAppear { loadMoreIfNeeded(current: t) }
                                    }
                                }
                                if isLoading && hasMorePages {
                                    ProgressView().tint(ModernColorScheme.brandBlue)
                                }
                            }
                            .padding(.vertical)
                        }
                        .refreshable { reload() }
                    }
                }
            }
            .navigationTitle("Tournaments")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name or location")
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
    
    private var filteredTournaments: [Tournament] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return tournaments }
        let q = query.lowercased()
        return tournaments.filter { t in
            let inName = t.name.lowercased().contains(q)
            let inLocation = (t.location ?? "").lowercased().contains(q)
            return inName || inLocation
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
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(tournament.name)
                    .font(ModernFontScheme.heading)
                    .foregroundColor(ModernColorScheme.text)
                    .lineLimit(1)
                Spacer()
                statusPill
            }
            HStack(spacing: 12) {
                label(icon: "mappin.and.ellipse", text: tournament.location ?? "TBA")
            }
            Divider().opacity(0.08)
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
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
        .shadow(color: ModernColorScheme.primary.opacity(0.06), radius: 5, x: 0, y: 2)
    }
    
    private func label(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(ModernColorScheme.accentMinimal)
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
    
    private var statusPill: some View {
        Text(statusText)
            .font(ModernFontScheme.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.12))
            .foregroundColor(statusColor)
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
    
    private var statusText: String {
        switch tournament.status {
        case .signupsOpen: return "Signups Open"
        case .locked: return "Locked"
        case .live: return "Live"
        case .complete: return "Complete"
        case .draft: return "Draft"
        }
    }
    
    private var statusColor: Color {
        switch tournament.status {
        case .signupsOpen: return .green
        case .locked: return .orange
        case .live: return .blue
        case .complete: return .gray
        case .draft: return .gray
        }
    }
}

