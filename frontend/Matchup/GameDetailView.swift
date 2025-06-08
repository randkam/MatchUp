import SwiftUI

struct GameDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isJoining = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image
                ZStack(alignment: .topTrailing) {
                    Image("basketball_court")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
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
                
                // Game Title
                Text("Pickup Game")
                    .font(ModernFontScheme.title)
                    .foregroundColor(ModernColorScheme.text)
                    .padding(.horizontal)
                
                // Game Details
                VStack(alignment: .leading, spacing: 15) {
                    DetailRow(icon: "location.fill", text: "Local Court")
                    DetailRow(icon: "calendar", text: "Today, March 27, 2025")
                    DetailRow(icon: "clock.fill", text: "2:00 PM - 4:00 PM")
                    DetailRow(icon: "person.3.fill", text: "6/10 Players")
                    DetailRow(icon: "basketball.fill", text: "Casual Play")
                }
                .padding(.horizontal)
                
                // Description
                VStack(alignment: .leading, spacing: 10) {
                    Text("Description")
                        .font(ModernFontScheme.heading)
                        .foregroundColor(ModernColorScheme.text)
                    
                    Text("Join us for a friendly pickup game at the local court. All skill levels welcome! We'll play 5v5 full court games with rotating teams. Bring water and good vibes!")
                        .font(ModernFontScheme.body)
                        .foregroundColor(ModernColorScheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                
                // Players
                VStack(alignment: .leading, spacing: 10) {
                    Text("Players")
                        .font(ModernFontScheme.heading)
                        .foregroundColor(ModernColorScheme.text)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(1..<7, id: \.self) { index in
                                GamePlayerView(username: "Player \(index)")
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Join Button
                Button(action: {
                    isJoining = true
                    // Add join game logic here
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
                        Text(isJoining ? "Joining..." : "Join Game")
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

struct DetailRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(ModernColorScheme.primary)
                .frame(width: 25)
            
            Text(text)
                .font(ModernFontScheme.body)
                .foregroundColor(ModernColorScheme.textSecondary)
            
            Spacer()
        }
    }
}

struct GamePlayerView: View {
    let username: String
    
    var body: some View {
        VStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(ModernColorScheme.primary)
                .background(ModernColorScheme.surface)
                .clipShape(Circle())
            
            Text(username)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
        }
    }
}

struct GameDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GameDetailView()
    }
}
