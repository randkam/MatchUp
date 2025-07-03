import SwiftUI
import CoreLocation

// Filter options for sorting the courts
struct FilterOptions {
    var indoor: Bool = false
    var outdoor: Bool = false
    var hasLights: Bool = false
}

enum SortOption {
    case activePlayersDesc
    case activePlayersAsc
    
    var description: String {
        switch self {
        case .activePlayersDesc:
            return "Most Active Players"
        case .activePlayersAsc:
            return "Least Active Players"
        }
    }
}

extension Location {
//    var coordinate: CLLocationCoordinate2D {
//        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//    }
}

struct HomeView: View {
    // MARK: - Properties
    @StateObject private var locationManager = LocationManager()
    @StateObject private var authCoordinator = AuthenticationCoordinator.shared
    @ObservedObject private var dataStore = SharedDataStore.shared
    
    @Binding var selectedCoordinate: IdentifiableCoordinate?
    @State private var filters = FilterOptions()
    @State private var sortOption: SortOption = .activePlayersDesc
    @State private var showSortMenu = false
    @State private var searchText = ""
    @State private var showProfile = false
    @State private var showNotifications = false
    @State private var isAnimating = false
    @State private var showFeedback = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                SearchBarView(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 0.5)
                
                // Filters and Sort Button
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterToggle(title: "Indoor", isSelected: $filters.indoor)
                            FilterToggle(title: "Outdoor", isSelected: $filters.outdoor)
                            FilterToggle(title: "Has Lights", isSelected: $filters.hasLights)
                        }
                        .padding(.horizontal)
                    }
                    
                    Menu {
                        Button(action: { sortOption = .activePlayersDesc }) {
                            Label("Most Active", systemImage: "arrow.down")
                        }
                        Button(action: { sortOption = .activePlayersAsc }) {
                            Label("Least Active", systemImage: "arrow.up")
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(ModernColorScheme.primary)
                            .padding(8)
                            .background(ModernColorScheme.surface)
                            .cornerRadius(8)
                    }
                    .padding(.trailing)
                    
                    Button(action: { showFeedback = true }) {
                        Image(systemName: "plus.bubble")
                            .foregroundColor(ModernColorScheme.primary)
                            .padding(8)
                            .background(ModernColorScheme.surface)
                            .cornerRadius(8)
                    }
                    .padding(.trailing)
                }
                .padding(.vertical, 8)
                
                if dataStore.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: ModernColorScheme.primary))
                    Spacer()
                } else {
                    // Locations List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if filteredLocations.isEmpty {
                                EmptyStateView(filters: filters)
                            } else {
                                ForEach(filteredLocations) { location in
                                    NavigationLink(destination: LocationDetailView(location: location)) {
                                        LocationCard(location: location) {
                                            // Empty closure since navigation is handled by NavigationLink
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .background(ModernColorScheme.background)
        }
        .sheet(isPresented: $showFeedback) {
            FeedbackView()
        }
        .onAppear {
            // Set navigation bar appearance
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            
            isAnimating = true
            locationManager.requestLocation()
        }
        .alert("Error", isPresented: .constant(dataStore.error != nil)) {
            Button("OK") {
                dataStore.error = nil
            }
        } message: {
            Text(dataStore.error?.localizedDescription ?? "An error occurred")
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredLocations: [Location] {
        var locations = dataStore.locations
        
        // Apply filters
        if filters.indoor && !filters.outdoor {
            locations = locations.filter { $0.locationType == .indoor }
        } else if !filters.indoor && filters.outdoor {
            locations = locations.filter { $0.locationType == .outdoor }
        }
        
        if filters.hasLights {
            locations = locations.filter { $0.isLitAtNight == true }
        }
        
        // Apply search filter if text is not empty
        if !searchText.isEmpty {
            locations = locations.filter {
                $0.locationName.localizedCaseInsensitiveContains(searchText) ||
                $0.locationAddress.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .activePlayersDesc:
            locations.sort { $0.locationActivePlayers > $1.locationActivePlayers }
        case .activePlayersAsc:
            locations.sort { $0.locationActivePlayers < $1.locationActivePlayers }
        }
        
        return locations
    }
    
    // MARK: - Helper Methods
    
    private func refreshData() async {
        await MainActor.run {
            dataStore.fetchLocations()
        }
    }
}

// MARK: - Subviews

struct SearchBarView: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ModernColorScheme.textSecondary)
            TextField("Search locations", text: $text)
                .font(ModernFontScheme.body)
                .foregroundColor(ModernColorScheme.text)
        }
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(12)
        .ignoresSafeArea(edges: .top)
    }
}

struct FilterToggle: View {
    let title: String
    @Binding var isSelected: Bool
    
    var body: some View {
        Button(action: { isSelected.toggle() }) {
            Text(title)
                .font(ModernFontScheme.body)
                .foregroundColor(isSelected ? .white : ModernColorScheme.text)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(isSelected ? ModernColorScheme.primary : ModernColorScheme.surface)
                .cornerRadius(20)
        }
    }
}

struct LocationCard: View {
    let location: Location
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Location Name and Type
            HStack {
                Text(location.locationName)
                    .font(ModernFontScheme.heading)
                    .foregroundColor(ModernColorScheme.text)
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Court Type Badge
                    HStack(spacing: 4) {
                        Image(systemName: location.locationType == .indoor ? "building.2.fill" : "sun.max.fill")
                            .foregroundColor(ModernColorScheme.primary)
                        Text(location.locationType == .indoor ? "Indoor" : "Outdoor")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ModernColorScheme.surface.opacity(0.6))
                    .cornerRadius(8)
                    
                    // Lit at Night Badge
                    if let isLit = location.isLitAtNight, isLit {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Lit")
                                .font(ModernFontScheme.caption)
                                .foregroundColor(ModernColorScheme.textSecondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ModernColorScheme.surface.opacity(0.6))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Active Players
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(ModernColorScheme.primary)
                Text("\(location.locationActivePlayers) active players")
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.textSecondary)
            }
            
            // Address
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(ModernColorScheme.primary)
                Text(location.locationAddress)
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(16)
        .shadow(color: ModernColorScheme.primary.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct EmptyStateView: View {
    let filters: FilterOptions
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(ModernColorScheme.textSecondary)
                .padding(.bottom, 8)
            
            Text(getEmptyStateMessage())
                .font(ModernFontScheme.body)
                .foregroundColor(ModernColorScheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func getEmptyStateMessage() -> String {
        var message = "No courts found"
        
        if filters.indoor && !filters.outdoor {
            message += " for indoor courts"
        } else if !filters.indoor && filters.outdoor {
            message += " for outdoor courts"
        }
        
        if filters.hasLights {
            message += " with lights"
        }
        
        return message
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}
