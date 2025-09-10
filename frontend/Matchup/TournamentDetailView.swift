import SwiftUI
import MapKit

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
                    Text("Bracket").tag(DetailTab.bracket)
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
                    case .bracket:
                        BracketLockedView(startsAt: tournament.startsAt)
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
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        .onAppear {
            // Placeholder: when API available, load registered team names here
            // registeredTeams = fetchedTeamNames
        }
    }
    
    private var titleHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(tournament.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(ModernColorScheme.text)
            Spacer()
        }
    }

    // Overview-only detail content
    private var overviewDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary card
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    summaryTile(icon: "figure.basketball", title: "Type", value: "\(tournament.formatSize)v\(tournament.formatSize)")
                    summaryTile(icon: "person.3", title: "Teams", value: "\(tournament.maxTeams)")
                    if let fee = tournament.entryFeeCents, fee > 0 {
                        summaryTile(icon: "dollarsign.circle", title: "Entry", value: priceString(cents: fee, currency: tournament.currency ?? "CAD"))
                    } else {
                        summaryTile(icon: "gift", title: "Entry", value: "Free")
                    }
                    summaryTile(icon: "trophy", title: "Prize", value: (tournament.prizeCents.flatMap { priceString(cents: $0, currency: tournament.currency ?? "CAD") }) ?? "TBA")
                }
                Divider()
                infoRow(icon: "calendar", text: dateRange)
                if let venue = tournament.location, !venue.isEmpty {
                    Button(action: { openInAppleMaps(address: venue) }) {
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.and.ellipse").foregroundColor(ModernColorScheme.primary)
                            Text(venue)
                                .font(ModernFontScheme.body)
                                .foregroundColor(ModernColorScheme.text)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(ModernFontScheme.caption)
                                .foregroundColor(ModernColorScheme.textSecondary)
                        }
                    }
                }
            }
            .padding()
            .background(ModernColorScheme.surface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
            .shadow(color: ModernColorScheme.primary.opacity(0.06), radius: 5, x: 0, y: 2)

            // Register button
            NavigationLink(destination: RegisterTournamentView(tournament: tournament)) {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("Register for Tournament")
                        .font(ModernFontScheme.body)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(ModernColorScheme.primary)
                .foregroundColor(.white)
                .cornerRadius(15)
            }

            // Notes card
            VStack(alignment: .leading, spacing: 8) {
                Text("What to expect")
                    .font(ModernFontScheme.heading)
                VStack(alignment: .leading, spacing: 8) {
                    infoRow(icon: "checkmark.seal", text: "Official referees on-site")
                    infoRow(icon: "video", text: "Videographer capturing highlights")
                    infoRow(icon: "square.grid.2x2", text: "Competitive bracket play")
                }
            }
            .padding()
            .background(ModernColorScheme.surface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
            .shadow(color: ModernColorScheme.primary.opacity(0.06), radius: 5, x: 0, y: 2)
        }
    }
    
    private var startDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: tournament.startsAt)
    }
    
    private var dateRange: String {
        let calendar = Calendar.current
        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .medium
        dateFmt.timeStyle = .none
        let timeFmt = DateFormatter()
        timeFmt.dateStyle = .none
        timeFmt.timeStyle = .short
        let startDate = dateFmt.string(from: tournament.startsAt)
        let startTime = timeFmt.string(from: tournament.startsAt)
        if let end = tournament.endsAt {
            if calendar.isDate(tournament.startsAt, inSameDayAs: end) {
                let endTime = timeFmt.string(from: end)
                return "\(startDate), \(startTime) – \(endTime)"
            } else {
                let endDate = dateFmt.string(from: end)
                let endTime = timeFmt.string(from: end)
                return "\(startDate), \(startTime) – \(endDate), \(endTime)"
            }
        }
        return "\(startDate), \(startTime)"
    }
    
    private func priceString(cents: Int, currency: String) -> String {
        let amount = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }

    private func openInAppleMaps(address: String) {
        let query = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
            UIApplication.shared.open(url)
        }
    }
}

private func heroPill(text: String) -> some View {
    Text(text)
        .font(ModernFontScheme.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.2))
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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

private func infoRow(icon: String, text: String) -> some View {
    HStack(spacing: 10) {
        Image(systemName: icon)
            .foregroundColor(ModernColorScheme.primary)
        Text(text)
            .font(ModernFontScheme.body)
            .foregroundColor(ModernColorScheme.text)
        Spacer()
    }
}

private func summaryTile(icon: String, title: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(ModernColorScheme.primary)
            Text(title)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
        }
        Text(value)
            .font(ModernFontScheme.body)
            .foregroundColor(ModernColorScheme.text)
    }
    .padding()
    .background(ModernColorScheme.surface.opacity(0.6))
    .cornerRadius(12)
}

private enum DetailTab { case overview, registered, bracket }

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

private struct BracketLockedView: View {
    let startsAt: Date
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(ModernColorScheme.surface)
                    .frame(height: 220)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
                    .shadow(color: ModernColorScheme.primary.opacity(0.06), radius: 5, x: 0, y: 2)
                    .blur(radius: 2)
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(ModernColorScheme.textSecondary)
                    Text("Bracket will be available 24 hours before start")
                        .font(ModernFontScheme.body)
                        .foregroundColor(ModernColorScheme.textSecondary)
                    Text(availabilityText)
                        .font(ModernFontScheme.caption)
                        .foregroundColor(ModernColorScheme.textSecondary)
                }
            }
        }
    }
    
    private var availabilityText: String {
        let date = Calendar.current.date(byAdding: .hour, value: -24, to: startsAt) ?? startsAt
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return "Available after \(df.string(from: date))"
    }
}



