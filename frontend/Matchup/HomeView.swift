import SwiftUI
import CoreLocation

// Filter options for sorting the courts
struct FilterOptions: Equatable {
    var indoor: Bool = false
    var outdoor: Bool = false
    var hasLights: Bool = false
}

enum SortOption {
    case activePlayersDesc
    case activePlayersAsc
    case distance
    
    var description: String {
        switch self {
        case .activePlayersDesc:
            return "Most Active Players"
        case .activePlayersAsc:
            return "Least Active Players"
        case .distance:
            return "Nearest First"
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
    @State private var isRefreshing = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                SearchBarView(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 0.5)
                    .onChange(of: searchText) { _ in
                        dataStore.fetchLocations(
                            search: searchText.isEmpty ? nil : searchText,
                            isIndoor: filters.indoor ? true : (filters.outdoor ? false : nil),
                            isLit: filters.hasLights ? true : nil,
                            refresh: true
                        )
                    }
                
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
                        Button(action: { sortOption = .distance }) {
                            Label("Nearest First", systemImage: "location")
                        }
                        Button(action: { sortOption = .activePlayersDesc }) {
                            Label("Most Active", systemImage: "arrow.down")
                        }
                        Button(action: { sortOption = .activePlayersAsc }) {
                            Label("Least Active", systemImage: "arrow.up")
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(ModernColorScheme.accentMinimal)
                            .padding(8)
                            .background(ModernColorScheme.surface)
                            .cornerRadius(8)
                    }
                    .padding(.trailing)
                }
                .padding(.vertical, 8)
                .onChange(of: filters) { _ in
                    dataStore.fetchLocations(
                        search: searchText.isEmpty ? nil : searchText,
                        isIndoor: filters.indoor ? true : (filters.outdoor ? false : nil),
                        isLit: filters.hasLights ? true : nil,
                        refresh: true
                    )
                }
                
                if dataStore.isLoading && dataStore.locations.isEmpty {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: ModernColorScheme.brandBlue))
                    Spacer()
                } else {
                    // Locations List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if !dataStore.isLoading && filteredLocations.isEmpty {
                                EmptyStateView(filters: filters)
                            } else {
                                ForEach(filteredLocations) { location in
                                    NavigationLink(destination: LocationDetailView(location: location)) {
                                        LocationCard(location: location) {
                                            // Empty closure since navigation is handled by NavigationLink
                                        }
                                        .padding(.horizontal)
                                        .onAppear {
                                            dataStore.loadMoreIfNeeded(currentItem: location)
                                        }
                                    }
                                }
                                
                                if dataStore.isLoading {
                                    ProgressView()
                                        .padding()
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await refresh()
                    }
                }
            }
            .background(ModernColorScheme.background)
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
            
            dataStore.fetchLocations(
                search: searchText.isEmpty ? nil : searchText,
                isIndoor: filters.indoor ? true : (filters.outdoor ? false : nil),
                isLit: filters.hasLights ? true : nil,
                refresh: true
            )
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
        
        // Apply sorting
        switch sortOption {
        case .activePlayersDesc:
            locations.sort { $0.locationActivePlayers > $1.locationActivePlayers }
        case .activePlayersAsc:
            locations.sort { $0.locationActivePlayers < $1.locationActivePlayers }
        case .distance:
            // Sort by distance from user's current location
            if let userLocation = locationManager.location?.coordinate {
                locations.sort { loc1, loc2 in
                    guard let lat1 = loc1.locationLatitude,
                          let lon1 = loc1.locationLongitude,
                          let lat2 = loc2.locationLatitude,
                          let lon2 = loc2.locationLongitude else {
                        return false
                    }
                    
                    let coord1 = CLLocation(latitude: lat1, longitude: lon1)
                    let coord2 = CLLocation(latitude: lat2, longitude: lon2)
                    let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                    
                    return coord1.distance(from: userCLLocation) < coord2.distance(from: userCLLocation)
                }
            }
        }
        
        return locations
    }
    
    // MARK: - Helper Methods
    private func refresh() async {
        isRefreshing = true
        dataStore.fetchLocations(
            search: searchText.isEmpty ? nil : searchText,
            isIndoor: filters.indoor ? true : (filters.outdoor ? false : nil),
            isLit: filters.hasLights ? true : nil,
            refresh: true
        )
        isRefreshing = false
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
                .background(isSelected ? ModernColorScheme.brandBlue : ModernColorScheme.surface)
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
                            .foregroundColor(ModernColorScheme.accentMinimal)
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
                    .foregroundColor(ModernColorScheme.accentMinimal)
                Text("\(location.locationActivePlayers) active players")
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.textSecondary)
            }
            
            // Address
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(ModernColorScheme.accentMinimal)
                Text(location.locationAddress)
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(16)
        .shadow(color: ModernColorScheme.brandBlue.opacity(0.1), radius: 5, x: 0, y: 2)
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
    private let networkManager = NetworkManager()
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 300 // Update every 5 minutes
    private var activeLocationId: Int? // Track which location we're currently at
    private let proximityThreshold: Double = 50 // 50 meters threshold
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest // Use best accuracy for court detection
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = true
        manager.activityType = .fitness
        manager.distanceFilter = 10 // Update location when user moves 10 meters
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        startUpdatingLocation()
    }
    
    private func startUpdatingLocation() {
        print("LocationManager: Starting location updates")
        manager.startUpdatingLocation()
        // Start timer for periodic updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            print("LocationManager: Timer triggered - requesting location update")
            self?.manager.requestLocation()
        }
    }
    
    func stopUpdatingLocation() {
        print("LocationManager: Stopping location updates")
        manager.stopUpdatingLocation()
        updateTimer?.invalidate()
        updateTimer = nil
        
        // If we were at a location, decrement the count
        if let locationId = activeLocationId {
            decrementActivePlayersCount(for: locationId)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        self.location = location
        
        print("LocationManager: Received location update - lat: \(location.coordinate.latitude), lon: \(location.coordinate.longitude)")
        
        // Get userId from UserDefaults
        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int else {
            print("LocationManager: User ID not found in UserDefaults")
            return
        }
        
        print("LocationManager: Updating location for user \(userId)")
        
        // Update location on server
        networkManager.updateUserLocation(
            userId: userId,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        ) { success, error in
            if let error = error {
                print("LocationManager: Failed to update location on server - \(error.localizedDescription)")
            } else if success {
                print("LocationManager: Successfully updated location on server")
            }
        }
        
        // Check nearby courts
        checkNearbyCourts(userLocation: location)
    }
    
    private func checkNearbyCourts(userLocation: CLLocation) {
        let dataStore = SharedDataStore.shared
        
        // Find the closest court within threshold
        var closestCourt: (location: Location, distance: CLLocationDistance)?
        
        for location in dataStore.locations {
            guard let latitude = location.locationLatitude,
                  let longitude = location.locationLongitude else {
                continue
            }
            
            let courtLocation = CLLocation(latitude: latitude, longitude: longitude)
            let distance = userLocation.distance(from: courtLocation)
            
            if distance <= proximityThreshold {
                if let current = closestCourt {
                    if distance < current.distance {
                        closestCourt = (location, distance)
                    }
                } else {
                    closestCourt = (location, distance)
                }
            }
        }
        
        // Handle court proximity
        if let (closestLocation, _) = closestCourt {
            if activeLocationId != closestLocation.locationId {
                // If we were at a different location, decrement its count
                if let oldLocationId = activeLocationId {
                    decrementActivePlayersCount(for: oldLocationId)
                }
                
                // Increment count for new location
                incrementActivePlayersCount(for: closestLocation.locationId)
                activeLocationId = closestLocation.locationId
            }
        } else if let oldLocationId = activeLocationId {
            // If we're not near any court but were previously at one
            decrementActivePlayersCount(for: oldLocationId)
            activeLocationId = nil
        }
    }
    
    private func incrementActivePlayersCount(for locationId: Int) {
        networkManager.incrementActivePlayers(locationId: locationId) { result in
            switch result {
            case .success(let location):
                print("LocationManager: Successfully incremented active players for location \(locationId)")
                // Update the location in SharedDataStore
                DispatchQueue.main.async {
                    if let index = SharedDataStore.shared.locations.firstIndex(where: { $0.locationId == locationId }) {
                        SharedDataStore.shared.locations[index] = location
                    }
                }
            case .failure(let error):
                print("LocationManager: Failed to increment active players - \(error.localizedDescription)")
            }
        }
    }
    
    private func decrementActivePlayersCount(for locationId: Int) {
        networkManager.decrementActivePlayers(locationId: locationId) { result in
            switch result {
            case .success(let location):
                print("LocationManager: Successfully decremented active players for location \(locationId)")
                // Update the location in SharedDataStore
                DispatchQueue.main.async {
                    if let index = SharedDataStore.shared.locations.firstIndex(where: { $0.locationId == locationId }) {
                        SharedDataStore.shared.locations[index] = location
                    }
                }
            case .failure(let error):
                print("LocationManager: Failed to decrement active players - \(error.localizedDescription)")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: Failed to get location - \(error.localizedDescription)")
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("LocationManager: Location access denied by user")
                stopUpdatingLocation()
            case .locationUnknown:
                print("LocationManager: Location currently unavailable")
            default:
                print("LocationManager: Other location error: \(clError.localizedDescription)")
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("LocationManager: Location access authorized")
            startUpdatingLocation()
        case .denied, .restricted:
            print("LocationManager: Location access denied or restricted")
            stopUpdatingLocation()
        case .notDetermined:
            print("LocationManager: Location access not determined")
        @unknown default:
            print("LocationManager: Unknown authorization status")
        }
    }
}
