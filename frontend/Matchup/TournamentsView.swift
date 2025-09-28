import SwiftUI

struct TournamentsView: View {
    @State private var tournaments: [Tournament] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var page: Int = 0
    @State private var hasMorePages: Bool = true
    @State private var query: String = ""
    @State private var selectedFilter: TournamentFilter = .all
    @State private var sortOption: TournamentSortOption = .soonest
    private let pageSize: Int = 20
    private let network = NetworkManager()

    // Single-column list layout
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernColorScheme.background
                    .ignoresSafeArea()
                Group {
                    if let errorMessage = errorMessage {
                        errorState(errorMessage)
                    } else if isLoading && tournaments.isEmpty {
                        loadingSkeleton
                    } else if tournaments.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                filterBar
                                    .padding(.horizontal)
                                LazyVStack(spacing: 16) {
                                    ForEach(displayedTournaments) { t in
                                        NavigationLink(destination: TournamentDetailView(tournament: t)) {
                                            TournamentRowCard(tournament: t)
                                                .onAppear { loadMoreIfNeeded(current: t) }
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.horizontal)
                                    }
                                }
                                if isLoading && hasMorePages {
                                    ProgressView().tint(ModernColorScheme.brandBlue)
                                }
                            }
                            .padding(.bottom, 24)
                        }
                        .refreshable { reload() }
                    }
                }
            }
            .navigationTitle("Tournaments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { sortMenu }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name or location")
        }
        .onAppear {
            if tournaments.isEmpty { fetchPage(reset: true) }
        }
        .animation(.easeInOut(duration: 0.25), value: displayedTournaments.map { $0.id })
        .animation(.easeInOut(duration: 0.25), value: selectedFilter)
        .animation(.easeInOut(duration: 0.25), value: sortOption)
    }
    
    private var displayedTournaments: [Tournament] {
        var list = tournaments
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let q = trimmed.lowercased()
            list = list.filter { t in
                t.name.lowercased().contains(q) || (t.location ?? "").lowercased().contains(q)
            }
        }
        switch selectedFilter {
        case .all: break
        case .open:
            list = list.filter { $0.status == .signupsOpen }
        case .free:
            list = list.filter { ($0.entryFeeCents ?? 0) <= 0 }
        case .live:
            list = list.filter { $0.status == .live }
        case .complete:
            list = list.filter { $0.status == .complete }
        }
        switch sortOption {
        case .soonest:
            list = list.sorted { $0.startsAt < $1.startsAt }
        case .prize:
            list = list.sorted { ($0.prizeCents ?? 0) > ($1.prizeCents ?? 0) }
        case .entryFee:
            list = list.sorted { ($0.entryFeeCents ?? 0) < ($1.entryFeeCents ?? 0) }
        case .teamSlots:
            list = list.sorted { $0.maxTeams > $1.maxTeams }
        }
        return list
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

    // MARK: - UI Pieces

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", filter: .all)
                filterChip(title: "Open", filter: .open)
                filterChip(title: "Free", filter: .free)
                filterChip(title: "Live", filter: .live)
                filterChip(title: "Complete", filter: .complete)
            }
            .padding(.vertical, 4)
        }
    }

    private func filterChip(title: String, filter: TournamentFilter) -> some View {
        Button(action: { selectedFilter = filter }) {
            Text(title)
                .font(ModernFontScheme.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    (selectedFilter == filter ? ModernColorScheme.accentMinimal.opacity(0.9) : ModernColorScheme.surface)
                )
                .foregroundColor(selectedFilter == filter ? .white : ModernColorScheme.text)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selectedFilter == filter ? Color.white.opacity(0.18) : Color.black.opacity(0.08), lineWidth: 1)
                )
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort by", selection: $sortOption) {
                ForEach(TournamentSortOption.allCases, id: \.self) { option in
                    Text(option.title).tag(option)
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: 16) {
                LazyVStack(spacing: 16) {
                    ForEach(0..<6, id: \.self) { _ in
                        SkeletonTournamentRow()
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy")
                .font(.system(size: 40))
                .foregroundColor(ModernColorScheme.accentMinimal)
            Text("No upcoming tournaments yet")
                .font(ModernFontScheme.body)
                .foregroundColor(ModernColorScheme.textSecondary)
            Button("Reload") { reload() }
                .buttonStyle(.bordered)
        }
        .padding()
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            Text("Failed to load tournaments")
                .font(ModernFontScheme.heading)
                .foregroundColor(ModernColorScheme.text)
            Text(message)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") { reload() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

private enum TournamentFilter { case all, open, free, live, complete }

private enum TournamentSortOption: CaseIterable { case soonest, prize, entryFee, teamSlots
    var title: String {
        switch self {
        case .soonest: return "Soonest"
        case .prize: return "Top Prize"
        case .entryFee: return "Lowest Entry Fee"
        case .teamSlots: return "Max Teams"
        }
    }
}

private struct TournamentRowCard: View {
    let tournament: Tournament

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(ModernColorScheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
                .shadow(color: ModernColorScheme.primary.opacity(0.08), radius: 8, x: 0, y: 4)
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(tournament.name)
                        .font(ModernFontScheme.heading)
                        .foregroundColor(ModernColorScheme.text)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(ModernColorScheme.accentMinimal)
                        Text(tournament.location ?? "TBA")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                            .lineLimit(1)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(ModernColorScheme.accentMinimal)
                        Text(shortDate(tournament.startsAt))
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                    }
                    HStack(spacing: 8) {
                        pill(icon: "figure.basketball", text: "\(tournament.formatSize)v\(tournament.formatSize)", color: Color.blue.opacity(0.9))
                        pill(icon: "person.3", text: "\(tournament.maxTeams)", color: Color.purple.opacity(0.9))
                        if let fee = tournament.entryFeeCents, fee > 0 {
                            pill(icon: "dollarsign.circle", text: priceString(cents: fee, currency: tournament.currency ?? "CAD"), color: Color.orange.opacity(0.95))
                        } else {
                            pill(icon: "gift", text: "Free", color: Color.green.opacity(0.95))
                        }
                        if let prize = tournament.prizeCents, prize > 0 {
                            pill(icon: "trophy", text: priceString(cents: prize, currency: tournament.currency ?? "CAD"), color: Color.yellow.opacity(0.95))
                        }
                    }
                }
                .padding([.horizontal, .bottom])
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity)
    }


    private func pill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(ModernFontScheme.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.14))
        .foregroundColor(color)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        case .signupsOpen: return "Open"
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

    private func shortDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df.string(from: date)
    }
}

private struct SkeletonTournamentRow: View {
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 16)
                .fill(ModernColorScheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
                .overlay(
                    VStack(alignment: .leading, spacing: 12) {
                        // Title
                        RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.25)).frame(height: 16)
                        // Location line
                        RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.22)).frame(width: 140, height: 12)
                        // Date line
                        RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.22)).frame(width: 90, height: 12)
                        // Pills rows
                        HStack { RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.2)).frame(width: 48, height: 20); RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.2)).frame(width: 48, height: 20); RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.2)).frame(width: 72, height: 20) }
                    }
                    .padding([.horizontal, .vertical])
                )
        }
        .frame(height: 160)
        .redacted(reason: .placeholder)
        .shimmer()
    }
}

// MARK: - Shimmer Modifier
private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -0.6
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let gradient = LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.25), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Rectangle()
                        .fill(gradient)
                        .rotationEffect(.degrees(20))
                        .offset(x: geo.size.width * phase)
                        .frame(width: geo.size.width * 0.8)
                        .blendMode(.plusLighter)
                        .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: phase)
                        .onAppear { phase = 1.6 }
                }
            )
    }
}

private extension View {
    func shimmer() -> some View { self.modifier(ShimmerModifier()) }
}

