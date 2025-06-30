import SwiftUI
import CoreLocation

struct LocationDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let location: Location
    @State private var showChat = false
    @State private var hasJoinedChat = false
    
    // Create a computed property for the chat object
    private var locationChat: Chat {
        Chat(
            id: location.locationId,
            name: location.locationName
//            isActive: location.locationActivePlayers > 0
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image
                ZStack(alignment: .topTrailing) {
                    Image("ballcourt")
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
                
                // Location Title and Description
//                VStack(alignment: .leading, spacing: 8) {
//                    Text(location.locationName)
//                        .font(ModernFontScheme.title)
//                        .foregroundColor(ModernColorScheme.text)
//                    
//                    Text(location.locationDescription)
//                        .font(ModernFontScheme.body)
//                        .foregroundColor(ModernColorScheme.textSecondary)
//                }
                .padding(.horizontal)
                
                // Location Details
                VStack(alignment: .leading, spacing: 15) {
                    DetailRowView(icon: "person.3.fill", text: "\(location.locationActivePlayers) active players")
                    DetailRowView(icon: "building.2.fill", text: location.locationType == .indoor ? "Indoor Court" : "Outdoor Court")
                    DetailRowView(icon: "mappin.and.ellipse", text: location.locationAddress)
                    if let isLit = location.isLitAtNight {
                        DetailRowView(icon: "lightbulb.fill", text: isLit ? "Lit at night" : "Not lit at night")
                    }
                }
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 15) {
                    // Join/View Chat Button (if there are active players)
                    Button(action: {
                        if !hasJoinedChat {
                            joinChat()
                        }
                        showChat = true
                    }) {
                        HStack {
                            Image(systemName: hasJoinedChat ? "bubble.left.fill" : "plus.circle.fill")
                            Text(hasJoinedChat ? "View Chat" : "Join Chat")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    
                    
                    // Navigate Button
                    Button(action: {
                        // Handle navigation to map
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Navigate")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ModernColorScheme.secondary)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                }
                .padding()
            }
        }
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        NavigationLink(isActive: $showChat) {
            ChatDetailedView(chat: locationChat)
        } label: {
            EmptyView()
        }
        .onAppear {
            checkIfJoinedChat()
        }
    }
    
    private func checkIfJoinedChat() {
        if let joinedLocations = UserDefaults.standard.array(forKey: "joinedLocations") as? [Int] {
            hasJoinedChat = joinedLocations.contains(location.locationId)
        }
    }
    
    private func joinChat() {   
        
        let networkManager = NetworkManager()
        networkManager.joinLocation( locationId: location.locationId) { success, error in
            if success {
                // Update local state
                var joinedLocations = UserDefaults.standard.array(forKey: "joinedLocations") as? [Int] ?? []
                joinedLocations.append(location.locationId)
                UserDefaults.standard.set(joinedLocations, forKey: "joinedLocations")
                hasJoinedChat = true
            } else {
                print("Error joining location: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

// Renamed to avoid conflict
struct DetailRowView: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ModernColorScheme.primary)
            Text(text)
                .font(ModernFontScheme.body)
                .foregroundColor(ModernColorScheme.text)
        }
    }
} 
