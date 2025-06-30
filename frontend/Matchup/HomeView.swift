import SwiftUI
import CoreLocation

// Filter options for sorting the courts
enum FilterOption: String, CaseIterable {
    case active = "Active"
    case inactive = "Inactive"
    case indoor = "Indoor"
    case outdoor = "Outdoor"
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
    @State private var selectedFilter: FilterOption = .active
    @State private var searchText = ""
    @State private var showProfile = false
    @State private var showNotifications = false
    @State private var isAnimating = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                SearchBarView(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 0.5)
                
                // Single Filter Section
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            FilterButton(
                                title: option.rawValue,
                                isSelected: selectedFilter == option,
                                action: { selectedFilter = option }
                            )
                        }
                    }
                    .padding(.horizontal)
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
                                VStack(spacing: 12) {
                                    Image(systemName: {
                                        switch selectedFilter {
                                        case .active:
                                            return "figure.basketball"
                                        case .inactive:
                                            return "basketball.fill"
                                        case .indoor:
                                            return "building.2.fill"
                                        case .outdoor:
                                            return "sun.max.fill"
                                        }
                                    }())
                                    .font(.system(size: 50))
                                    .foregroundColor(ModernColorScheme.textSecondary)
                                    .padding(.bottom, 8)
                                    
                                    Text({
                                        switch selectedFilter {
                                        case .active:
                                            return "No active courts at the moment"
                                        case .inactive:
                                            return "No inactive courts at the moment"
                                        case .indoor:
                                            return "No indoor courts available"
                                        case .outdoor:
                                            return "No outdoor courts available"
                                        }
                                    }())
                                    .font(ModernFontScheme.body)
                                    .foregroundColor(ModernColorScheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
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
        var locations: [Location]
        
        // First apply activity filter
        switch selectedFilter {
        case .active:
            locations = dataStore.activeCourts
            print("Filtered active courts: \(locations.count)")
        case .inactive:
            locations = dataStore.inactiveCourts
            print("Filtered inactive courts: \(locations.count)")
        case .indoor:
            locations = dataStore.locations.filter { $0.locationType == .indoor }
            print("Filtered indoor courts: \(locations.count)")
        case .outdoor:
            locations = dataStore.locations.filter { $0.locationType == .outdoor }
            print("Filtered outdoor courts: \(locations.count)")
        }
        
        // Apply search filter if text is not empty
        if !searchText.isEmpty {
            let beforeCount = locations.count
            locations = locations.filter {
                $0.locationName.localizedCaseInsensitiveContains(searchText) ||
                $0.locationAddress.localizedCaseInsensitiveContains(searchText)
            }
            print("After search filter: \(locations.count) (was \(beforeCount))")
        }
        
        // Sort by active players (descending) for active filter
        if selectedFilter == .active {
            locations.sort { $0.locationActivePlayers > $1.locationActivePlayers }
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

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
                    if location.isLitAtNight {
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
