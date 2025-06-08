import SwiftUI

struct FeaturedGameDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isJoining = false
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image with Live Badge
                ZStack(alignment: .topTrailing) {
                    Image("basketball_court")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                        .cornerRadius(20)
                    
                    HStack {
                        // Close Button
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(ModernColorScheme.text)
                                .padding(10)
                                .background(ModernColorScheme.surface.opacity(0.8))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Live Badge
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("LIVE")
                                .font(ModernFontScheme.caption)
                                .foregroundColor(ModernColorScheme.text)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ModernColorScheme.surface.opacity(0.8))
                        .cornerRadius(20)
                    }
                    .padding()
                }
                
                // Game Title
                Text("3v3 Tournament")
                    .font(ModernFontScheme.title)
                    .foregroundColor(ModernColorScheme.text)
                    .padding(.horizontal)
                
                // Game Details
                VStack(alignment: .leading, spacing: 15) {
                    DetailRow(icon: "location.fill", text: "Central Park")
                    DetailRow(icon: "calendar", text: "Today, March 27, 2025")
                    DetailRow(icon: "clock.fill", text: "2:00 PM - 6:00 PM")
                    DetailRow(icon: "person.3.fill", text: "12/24 Players")
                    DetailRow(icon: "trophy.fill", text: "Tournament Style")
                }
                .padding(.horizontal)
                
                // Tab Selection
                HStack {
                    TabButton(title: "Details", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    
                    TabButton(title: "Teams", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    
                    TabButton(title: "Schedule", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                }
                .padding(.horizontal)
                
                // Tab Content
                if selectedTab == 0 {
                    // Description
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Description")
                            .font(ModernFontScheme.heading)
                            .foregroundColor(ModernColorScheme.text)
                        
                        Text("Join our exciting 3v3 basketball tournament at Central Park! This tournament features 8 teams competing in a single-elimination bracket. Prizes for the top 3 teams! Registration is $10 per player with all proceeds going to local youth basketball programs.")
                            .font(ModernFontScheme.body)
                            .foregroundColor(ModernColorScheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Rules")
                            .font(ModernFontScheme.heading)
                            .foregroundColor(ModernColorScheme.text)
                            .padding(.top, 10)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            BulletPoint(text: "Games to 15 points, win by 2")
                            BulletPoint(text: "1 point per basket, 2 points beyond the arc")
                            BulletPoint(text: "Call your own fouls")
                            BulletPoint(text: "Winner stays on court")
                            BulletPoint(text: "12-minute time limit per game")
                        }
                    }
                    .padding(.horizontal)
                } else if selectedTab == 1 {
                    // Teams
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(1..<5, id: \.self) { team in
                            TeamRow(teamName: "Team \(team)", playerCount: 3, isRegistered: team < 3)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Schedule
                    VStack(alignment: .leading, spacing: 15) {
                        ScheduleRow(time: "2:00 PM", matchup: "Team 1 vs Team 2", court: "Court A")
                        ScheduleRow(time: "2:30 PM", matchup: "Team 3 vs Team 4", court: "Court A")
                        ScheduleRow(time: "3:00 PM", matchup: "Team 5 vs Team 6", court: "Court A")
                        ScheduleRow(time: "3:30 PM", matchup: "Team 7 vs Team 8", court: "Court A")
                        ScheduleRow(time: "4:15 PM", matchup: "Semifinals", court: "Court A")
                        ScheduleRow(time: "5:00 PM", matchup: "Finals", court: "Court A")
                    }
                    .padding(.horizontal)
                }
                
                // Join Button
                Button(action: {
                    isJoining = true
                    // Add join tournament logic here
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isJoining = false
                        // Show success message or navigate
                    }
                }) {
                    HStack {
                        if isJoining {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: ModernColorScheme.text))
                                .padding(.trailing, 5)
                        }
                        Text(isJoining ? "Registering..." : "Register for Tournament")
                            .font(ModernFontScheme.body)
                            .foregroundColor(ModernColorScheme.text)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ModernColorScheme.primary)
                    .cornerRadius(15)
                    .shadow(color: ModernColorScheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(isJoining)
                .padding()
            }
        }
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ModernFontScheme.body)
                .foregroundColor(isSelected ? ModernColorScheme.primary : ModernColorScheme.textSecondary)
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background(isSelected ? ModernColorScheme.surface : Color.clear)
                .cornerRadius(10)
                .overlay(
                    VStack {
                        Spacer()
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(isSelected ? ModernColorScheme.primary : Color.clear)
                    }
                )
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .foregroundColor(ModernColorScheme.primary)
            
            Text(text)
                .font(ModernFontScheme.body)
                .foregroundColor(ModernColorScheme.textSecondary)
            
            Spacer()
        }
    }
}

struct TeamRow: View {
    let teamName: String
    let playerCount: Int
    let isRegistered: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(teamName)
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.text)
                
                Text("\(playerCount) players")
                    .font(ModernFontScheme.caption)
                    .foregroundColor(ModernColorScheme.textSecondary)
            }
            
            Spacer()
            
            if isRegistered {
                Text("Registered")
                    .font(ModernFontScheme.caption)
                    .foregroundColor(ModernColorScheme.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(ModernColorScheme.secondary.opacity(0.2))
                    .cornerRadius(10)
            } else {
                Button(action: {}) {
                    Text("Join")
                        .font(ModernFontScheme.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .background(ModernColorScheme.primary)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(10)
    }
}

struct ScheduleRow: View {
    let time: String
    let matchup: String
    let court: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(time)
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.text)
                
                Text(matchup)
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.textSecondary)
                
                Text(court)
                    .font(ModernFontScheme.caption)
                    .foregroundColor(ModernColorScheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(ModernColorScheme.textSecondary)
        }
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(10)
    }
}
