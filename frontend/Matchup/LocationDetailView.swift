import SwiftUI
import CoreLocation

struct LocationDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let location: Location
    @State private var showChat = false
    @State private var hasJoinedChat = false
    @State private var averageRating: Double = 0.0
    @State private var reviewCount: Int = 0
    @State private var showingReviews = false
    @State private var showingReviewsSheet = false
    
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
                }
                .padding(.horizontal)
                
                // Location Name
                Text(location.locationName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ModernColorScheme.text)
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
                
                // Reviews Section
                Button(action: {
                    showingReviewsSheet = true
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Reviews")
                                .font(.title3)
                                .foregroundColor(ModernColorScheme.text)
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", averageRating))
                                    .foregroundColor(ModernColorScheme.text)
                                Text("•")
                                    .foregroundColor(ModernColorScheme.secondary)
                                Text("\(reviewCount) reviews")
                                    .foregroundColor(ModernColorScheme.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(ModernColorScheme.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 15) {
                    // Join/View Chat Button
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
        .sheet(isPresented: $showingReviewsSheet) {
            ReviewsView(locationId: location.locationId)
                .onDisappear {
                    loadReviewStats()
                }
        }
        .fullScreenCover(isPresented: $showChat) {
            NavigationView {
                ChatDetailedView(chat: locationChat)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showChat = false }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                            }
                        }
                    }
            }
        }
        .onAppear {
            checkIfJoinedChat()
            loadReviewStats()
        }
    }
    
    private func checkIfJoinedChat() {
        if let joinedLocations = UserDefaults.standard.array(forKey: "joinedLocations") as? [Int] {
            hasJoinedChat = joinedLocations.contains(location.locationId)
        }
    }
    
    private func loadReviewStats() {
        ReviewManager.shared.getLocationReviews(locationId: location.locationId) { reviews, error in
            if let reviews = reviews {
                DispatchQueue.main.async {
                    self.reviewCount = reviews.count
                }
            }
        }
        
        ReviewManager.shared.getAverageRating(locationId: location.locationId) { rating, error in
            if let rating = rating {
                DispatchQueue.main.async {
                    self.averageRating = rating
                }
            }
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
