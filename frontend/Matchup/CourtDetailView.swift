import SwiftUI
import CoreLocation

struct CourtDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let title: String
    let activePlayers: Int
    let usernames: [String]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image
                ZStack(alignment: .topTrailing) {
                    Image("basketball_court")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(20)
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(ModernColorScheme.text)
                            .padding(10)
                            .background(ModernColorScheme.surface.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                
                // Court Title
                Text(title)
                    .font(ModernFontScheme.title)
                    .foregroundColor(ModernColorScheme.text)
                    .padding(.horizontal)
                
                // Court Details
                VStack(alignment: .leading, spacing: 15) {
                    DetailRow(icon: "person.3.fill", text: "\(activePlayers) active players")
                    DetailRow(icon: "star.fill", text: "4.8 (125 ratings)")
                    DetailRow(icon: "clock.fill", text: "Open 6:00 AM - 10:00 PM")
                    DetailRow(icon: "basketball.fill", text: "Full court available")
                }
                .padding(.horizontal)
                
                // Active Players
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active Players")
                        .font(ModernFontScheme.heading)
                        .foregroundColor(ModernColorScheme.text)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(usernames, id: \.self) { username in
                                CourtPlayerView(username: username)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Buttons
                HStack(spacing: 15) {
                    Button(action: {
                        // Navigate to this court on the map
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Navigate")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ModernColorScheme.primary)
                        .foregroundColor(ModernColorScheme.text)
                        .cornerRadius(15)
                    }
                    
                    Button(action: {
                        // Create a game at this court
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Create Game")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ModernColorScheme.secondary)
                        .foregroundColor(ModernColorScheme.text)
                        .cornerRadius(15)
                    }
                }
                .padding()
            }
        }
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
    }
}

struct CourtPlayerView: View {
    let username: String
    
    var body: some View {
        VStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(ModernColorScheme.primary)
                .background(ModernColorScheme.surface)
                .clipShape(Circle())
            
            Text(username)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 70)
    }
}
