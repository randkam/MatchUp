import SwiftUI
import CoreLocation

// Filter options for sorting the courts
enum FilterOption: String, CaseIterable {
    case all = "All"
    case nearby = "Nearby"
    case active = "Active"
    case inactive = "Inactive"
}

struct HomeView: View {
    @State private var userLocation = CLLocationCoordinate2D(latitude: 43.7800, longitude: -79.3350)
    @State private var showNavbar = true
    @StateObject private var authCoordinator = AuthenticationCoordinator.shared
    
    // Timer to auto-hide navbar after inactivity
    let navbarHideTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    // Use the shared data store for court data
    @ObservedObject private var dataStore = SharedDataStore.shared
    
    @State private var playersVisitedToday = 15
    @State private var totalPlayersToday = 20
    @Binding var selectedCoordinate: IdentifiableCoordinate?
    @State private var selectedFilter: FilterOption = .all
    @State private var searchText = ""
    @State private var showCreateGame = false
    @State private var showProfile = false
    @State private var showNotifications = false
    @State private var isAnimating = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {                    
                    // Search Bar Section
                    HStack {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(ModernColorScheme.textSecondary)
                            TextField("Search games, players, or courts", text: $searchText)
                                .font(ModernFontScheme.body)
                                .foregroundColor(ModernColorScheme.text)
                                .onTapGesture {
                                    // Show navbar when user interacts with the search field
                                    withAnimation(.easeInOut) {
                                        showNavbar = true
                                    }
                                }
                        }
                        .padding()
                        .background(ModernColorScheme.surface)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .opacity(1)
                    .animation(.easeOut(duration: 0.8), value: isAnimating)
                    
                    // Filter Options
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(FilterOption.allCases, id: \.self) { option in
                                FilterButton(
                                    title: option.rawValue,
                                    isSelected: selectedFilter == option,
                                    action: { 
                                        selectedFilter = option 
                                        // Show navbar when user interacts with filters
                                        withAnimation(.easeInOut) {
                                            showNavbar = true
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    // Filter options should always be visible - no fading
                    .opacity(1)
                    
                    // Featured Game Card
                    FeaturedGameCard()
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 50)
                        .animation(.easeOut(duration: 0.8).delay(0.4), value: isAnimating)
                        .onTapGesture {
                            // Show navbar when user interacts with this section
                            withAnimation(.easeInOut) {
                                showNavbar = true
                            }
                        }
                    

                    
                    // Active Courts - Show right after the big tile
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Active Courts")
                            .font(ModernFontScheme.heading)
                            .foregroundColor(ModernColorScheme.text)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                // Make sure some courts are active and others are not
                                let activeCourts = dataStore.basketballCourts.filter { $0.activePlayers > 0 }
                                if activeCourts.isEmpty {
                                    Text("No active courts right now")
                                        .font(ModernFontScheme.body)
                                        .foregroundColor(ModernColorScheme.textSecondary)
                                        .padding()
                                } else {
                                    ForEach(activeCourts) { school in
                                        let distance = calculateDistance(to: school.coordinate)
                                        CourtCardView(
                                            title: school.name,
                                            distance: "\(String(format: "%.1f", distance)) km",
                                            activePlayers: school.activePlayers,
                                            usernames: school.usernames,
                                            navigateToLocation: { location in
                                                selectedCoordinate = IdentifiableCoordinate(coordinate: location)
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 50)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: isAnimating)
                    .onTapGesture {
                        // Show navbar when user interacts with this section
                        withAnimation(.easeInOut) {
                            showNavbar = true
                        }
                    }
                    
                    // Inactive Courts - Show below active courts
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Inactive Courts")
                            .font(ModernFontScheme.heading)
                            .foregroundColor(ModernColorScheme.text)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                let inactiveCourts = dataStore.basketballCourts.filter { $0.activePlayers == 0 }
                                if inactiveCourts.isEmpty {
                                    Text("No inactive courts available")
                                        .font(ModernFontScheme.body)
                                        .foregroundColor(ModernColorScheme.textSecondary)
                                        .padding()
                                } else {
                                    ForEach(inactiveCourts) { school in
                                        let distance = calculateDistance(to: school.coordinate)
                                        CourtCardView(
                                            title: school.name,
                                            distance: "\(String(format: "%.1f", distance)) km",
                                            activePlayers: school.activePlayers,
                                            usernames: school.usernames,
                                            navigateToLocation: { location in
                                                selectedCoordinate = IdentifiableCoordinate(coordinate: location)
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 50)
                    .animation(.easeOut(duration: 0.8).delay(1.0), value: isAnimating)
                    .onTapGesture {
                        // Show navbar when user interacts with this section
                        withAnimation(.easeInOut) {
                            showNavbar = true
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .overlay(
                // Create Game Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { 
                            showCreateGame = true 
                            // Show navbar when user interacts with the create button
                            withAnimation(.easeInOut) {
                                showNavbar = true
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(ModernColorScheme.text)
                                .padding()
                                .background(ModernColorScheme.primary)
                                .clipShape(Circle())
                                .shadow(color: ModernColorScheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding()
                    }
                }
            )
            .sheet(isPresented: $showCreateGame) {
                CreateGameView()
            }
            .onAppear {
                isAnimating = true
                showNavbar = true
            }
            .onReceive(navbarHideTimer) { _ in
                // Auto-hide navbar after timer fires if no interaction
                if showNavbar {
                    withAnimation(.easeInOut) {
                        showNavbar = false
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }

    // Filtered schools based on the selected filter option
    var filteredSchools: [BasketballSchool] {
        switch selectedFilter {
        case .all:
            return dataStore.basketballCourts
        case .nearby:
            return dataStore.basketballCourts.sorted {
                calculateDistance(to: $0.coordinate) < calculateDistance(to: $1.coordinate)
            }
        case .active:
            return dataStore.basketballCourts.filter { $0.activePlayers > 0 }.sorted {
                $0.activePlayers > $1.activePlayers
            }
        case .inactive:
            return dataStore.basketballCourts.filter { $0.activePlayers == 0 }
        }
    }
    
    // Calculate distance from user location to a given coordinate
    func calculateDistance(to coordinate: CLLocationCoordinate2D) -> Double {
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let targetCLLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        let distanceInMeters = userCLLocation.distance(from: targetCLLocation)
        return distanceInMeters / 1000 // Convert to kilometers
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ModernFontScheme.body)
                .foregroundColor(isSelected ? ModernColorScheme.text : ModernColorScheme.textSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? ModernColorScheme.primary : (isHovered ? ModernColorScheme.surface.opacity(0.7) : ModernColorScheme.surface))
                .cornerRadius(20)
                .shadow(color: isHovered ? ModernColorScheme.primary.opacity(0.3) : Color.clear, radius: 5)
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct FeaturedGameCard: View {
    @State private var isHovered = false
    @State private var showDetails = false
    @State private var showChat = false
    
    // Use one of the actual schools from our data
    let featuredSchool = BasketballSchool(
        name: "Earl Haig Secondary School", 
        coordinate: CLLocationCoordinate2D(latitude: 43.7663, longitude: -79.4018), 
        activePlayers: 7, 
        usernames: ["playerL", "playerM", "playerN", "playerO", "playerP", "playerQ", "playerR"],
        description: "Popular spot for competitive players, with regular weekend tournaments.",
        rating: 4.9,
        openHours: "7:00 AM - 11:00 PM",
        courtType: "Professional full court"
    )
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Game Image
            ZStack(alignment: .topTrailing) {
                Image("basketball_court") // Add this image to assets
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(20)
                
                // Live Badge
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("ACTIVE")
                        .font(ModernFontScheme.caption)
                        .foregroundColor(ModernColorScheme.text)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ModernColorScheme.surface)
                .cornerRadius(20)
                .padding()
            }
            
            // Game Info
            VStack(alignment: .leading, spacing: 10) {
                Text(featuredSchool.name)
                    .font(ModernFontScheme.heading)
                    .foregroundColor(ModernColorScheme.text)
                
                Text(featuredSchool.description)
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.textSecondary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(ModernColorScheme.primary)
                    Text("\(String(format: "%.1f", featuredSchool.rating)) Rating")
                        .font(ModernFontScheme.body)
                        .foregroundColor(ModernColorScheme.textSecondary)
                }
                
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(ModernColorScheme.primary)
                    Text("\(featuredSchool.activePlayers) Active Players")
                        .font(ModernFontScheme.body)
                        .foregroundColor(ModernColorScheme.textSecondary)
                }
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(ModernColorScheme.primary)
                    Text(featuredSchool.openHours)
                        .font(ModernFontScheme.body)
                        .foregroundColor(ModernColorScheme.textSecondary)
                }
                
                HStack(spacing: 10) {
                    Button(action: { showChat = true }) {
                        Text("Join Chat")
                            .font(ModernFontScheme.body)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    
                    Button(action: { showDetails = true }) {
                        Text("View Details")
                            .font(ModernFontScheme.body)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(ModernColorScheme.primary)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 5)
            }
            .padding()
        }
        .background(isHovered ? ModernColorScheme.surface.opacity(0.8) : ModernColorScheme.surface)
        .cornerRadius(20)
        .shadow(color: isHovered ? ModernColorScheme.primary.opacity(0.3) : ModernColorScheme.primary.opacity(0.1), radius: isHovered ? 8 : 5, x: 0, y: isHovered ? 4 : 2)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            showDetails = true
        }
        .sheet(isPresented: $showDetails) {
            BasketballCourtDetailView(school: featuredSchool)
        }
        .sheet(isPresented: $showChat) {
            ChatDetailedView(chat: Chat(
                id: abs(featuredSchool.id.hashValue), // Convert UUID to a positive Int using hashValue
                name: featuredSchool.name
            ))
        }
    }
}

struct GameCard: View {
    let school: BasketballSchool
    @State private var isHovered = false
    @State private var showDetails = false
    @State private var showChat = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Game Image
            Image("basketball_court") // Add this image to assets
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 160, height: 120)
                .clipped()
                .cornerRadius(15)
            
            // Game Info
            VStack(alignment: .leading, spacing: 5) {
                Text(school.name)
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.text)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(ModernColorScheme.primary)
                    Text(String(format: "%.1f", school.rating))
                        .font(ModernFontScheme.caption)
                        .foregroundColor(ModernColorScheme.textSecondary)
                }
                
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(ModernColorScheme.primary)
                    Text("\(school.activePlayers) active")
                        .font(ModernFontScheme.caption)
                        .foregroundColor(ModernColorScheme.textSecondary)
                }
            }
            .padding(.horizontal, 5)
        }
        .frame(width: 160)
        .background(isHovered ? ModernColorScheme.surface.opacity(0.8) : ModernColorScheme.surface)
        .cornerRadius(15)
        .shadow(color: isHovered ? ModernColorScheme.primary.opacity(0.3) : Color.clear, radius: 5)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            showDetails = true
        }
        .sheet(isPresented: $showDetails) {
            BasketballCourtDetailView(school: school)
        }
        .sheet(isPresented: $showChat) {
            ChatDetailedView(chat: Chat(
                id: abs(school.id.hashValue), // Convert UUID to a positive Int using hashValue
                name: school.name
            ))
        }
    }
}

struct CourtCardView: View {
    let title: String
    let distance: String
    let activePlayers: Int
    let usernames: [String]
    let navigateToLocation: (CLLocationCoordinate2D) -> Void
    
    @State private var isHovered = false
    @State private var showDetails = false
    @State private var showChat = false
    @State private var coordinate: CLLocationCoordinate2D
    
    // Initialize with the proper coordinate
    init(title: String, distance: String, activePlayers: Int, usernames: [String], navigateToLocation: @escaping (CLLocationCoordinate2D) -> Void) {
        self.title = title
        self.distance = distance
        self.activePlayers = activePlayers
        self.usernames = usernames
        self.navigateToLocation = navigateToLocation
        
        // Find the matching school to get the correct coordinate
        let matchingSchool = SharedDataStore.shared.basketballCourts.first(where: { $0.name == title })
        self._coordinate = State(initialValue: matchingSchool?.coordinate ?? CLLocationCoordinate2D(latitude: 43.7800, longitude: -79.3350))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "basketball")
                    .foregroundColor(ModernColorScheme.primary)
                Spacer()
                HStack(spacing: -8) {
                    ForEach(usernames.prefix(2), id: \.self) { _ in
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(ModernColorScheme.primary)
                            .background(ModernColorScheme.surface)
                            .clipShape(Circle())
                    }
                }
            }

            Text(distance)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)

            Text(title)
                .font(ModernFontScheme.body)
                .foregroundColor(ModernColorScheme.text)
                .lineLimit(1)
                .truncationMode(.tail)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(activePlayers) active players")
                    .font(ModernFontScheme.caption)
                    .foregroundColor(ModernColorScheme.textSecondary)
                
                HStack(spacing: 4) {
                    Button(action: { navigateToLocation(coordinate) }) {
                        Text("Navigate")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(.white)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 6)
                            .background(ModernColorScheme.primary)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if activePlayers > 0 {
                        // Show Join Chat button if there are active players
                        Button(action: { showChat = true }) {
                            Text("Join Chat")
                                .font(ModernFontScheme.caption)
                                .foregroundColor(.white)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 6)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // Show Create Game button if there are no active players
                        Button(action: { showDetails = true }) {
                            Text("Create Game")
                                .font(ModernFontScheme.caption)
                                .foregroundColor(.white)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 6)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                    
                    Button(action: { showDetails = true }) {
                        Text("Details")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(.white)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 6)
                            .background(ModernColorScheme.secondary)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(isHovered ? ModernColorScheme.surface.opacity(0.8) : ModernColorScheme.surface)
        .cornerRadius(12)
        .shadow(color: isHovered ? ModernColorScheme.primary.opacity(0.3) : ModernColorScheme.primary.opacity(0.1), radius: isHovered ? 8 : 5, x: 0, y: isHovered ? 4 : 2)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            showDetails = true
        }
        .sheet(isPresented: $showDetails) {
            CourtDetailView(title: title, activePlayers: activePlayers, usernames: usernames)
        }
        .sheet(isPresented: $showChat) {
            CourtChatView(courtName: title)
        }
        .frame(width: 200)
    }
}
