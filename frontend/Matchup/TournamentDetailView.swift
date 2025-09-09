import SwiftUI

struct TournamentDetailView: View {
    let tournament: Tournament
    
    @State private var selectedTab: DetailTab = .overview
    @State private var registeredTeams: [String] = [] // Placeholder until API is wired
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                titleHeader
                    .padding(.horizontal)
                    .padding(.top)
                
                Picker("View", selection: $selectedTab) {
                    Text("Overview").tag(DetailTab.overview)
                    Text("Registered Teams").tag(DetailTab.registered)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                Group {
                    switch selectedTab {
                    case .overview:
                        overviewDetails
                    case .registered:
                        RegisteredTeamsView(totalSlots: tournament.maxTeams, teams: registeredTeams)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                EmptyView() // hide default title; we use our own large title
            }
        }
        .onAppear {
            // Placeholder: when API available, load registered team names here
            // registeredTeams = fetchedTeamNames
        }
    }
    
    private var titleHeader: some View {
        HStack {
            Image(systemName: "basketball.fill")
                .foregroundColor(ModernColorScheme.primary)
            Text(tournament.name)
                .font(ModernFontScheme.heading)
                .foregroundColor(ModernColorScheme.text)
            Spacer()
        }
    }

    // Overview-only detail content
    private var overviewDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Meta
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    label(icon: "figure.basketball", text: "Basketball  Type: \(tournament.formatSize)v\(tournament.formatSize)")
                }
                HStack(spacing: 16) {
                    label(icon: "person.3", text: "Teams: \(tournament.maxTeams)")
                    label(icon: "calendar", text: dateRange)
                }
                if let venue = tournament.location, !venue.isEmpty {
                    label(icon: "mappin.and.ellipse", text: venue)
                }
            }
            
            // Pricing
            HStack(spacing: 16) {
                if let fee = tournament.entryFeeCents, fee > 0 {
                    Badge(icon: "dollarsign.circle", text: priceString(cents: fee, currency: tournament.currency ?? "CAD"), tint: .orange)
                } else {
                    Badge(icon: "gift", text: "Free Entry", tint: .green)
                }
                if let prize = tournament.prizeCents, prize > 0 {
                    Badge(icon: "trophy", text: "Prize: \(priceString(cents: prize, currency: tournament.currency ?? "CAD"))", tint: .yellow)
                } else {
                    Badge(icon: "trophy", text: "Prize: TBA", tint: .yellow)
                }
            }
            
            Divider()
            
            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("What to expect")
                    .font(ModernFontScheme.heading)
                VStack(alignment: .leading, spacing: 6) {
                    label(icon: "checkmark.seal", text: "Official referees on-site")
                    label(icon: "video", text: "Videographer capturing highlights")
                    label(icon: "square.grid.2x2", text: "Competitive bracket play")
                }
                .foregroundColor(ModernColorScheme.textSecondary)
            }
        }
    }
    
    private var startDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: tournament.startsAt)
    }
    
    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let start = formatter.string(from: tournament.startsAt)
        if let end = tournament.endsAt {
            let endStr = formatter.string(from: end)
            return "\(start) – \(endStr)"
        }
        return start
    }
    
    private func priceString(cents: Int, currency: String) -> String {
        let amount = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }
}

private struct Badge: View {
    let icon: String
    let text: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.12))
        .foregroundColor(tint)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private func label(icon: String, text: String) -> some View {
    HStack(spacing: 8) {
        Image(systemName: icon)
            .foregroundColor(ModernColorScheme.primary)
        Text(text)
            .font(ModernFontScheme.body)
            .foregroundColor(ModernColorScheme.text)
    }
}

private enum DetailTab { case overview, registered }

private struct OverviewPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview coming soon")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RegisteredTeamsView: View {
    let totalSlots: Int
    let teams: [String]
    
    private var registeredCount: Int { min(teams.count, totalSlots) }
    private var displayNames: [String] {
        let filled = teams.prefix(totalSlots)
        let placeholdersCount = max(0, totalSlots - filled.count)
        return Array(filled) + Array(repeating: "Empty Spot", count: placeholdersCount)
    }
    
    private let columns = [GridItem(.flexible(minimum: 120)), GridItem(.flexible(minimum: 120))]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Registered \(registeredCount) / \(totalSlots)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(displayNames.indices, id: \.self) { idx in
                    TeamSlotCard(index: idx + 1, name: displayNames[idx], isEmpty: displayNames[idx] == "Empty Spot")
                }
            }
        }
    }
}

private struct TeamSlotCard: View {
    let index: Int
    let name: String
    let isEmpty: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Text("#\(index)")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 28)
            Text(name)
                .font(.subheadline)
                .foregroundColor(isEmpty ? .gray : .primary)
                .lineLimit(1)
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}



