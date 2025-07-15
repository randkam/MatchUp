import SwiftUI
import MapKit
import CoreLocation

struct MapViewContent: View {
    @StateObject private var locationManager = LocationManager()
    @ObservedObject private var dataStore = SharedDataStore.shared
    @State private var selectedLocation: Location? = nil
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var userTrackingMode: MapUserTrackingMode = .none
    @State private var searchText = ""
    @State private var hasSetInitialLocation = false
    @State private var showSearchResults = false
    
    private var filteredLocations: [Location] {
        if searchText.isEmpty {
            return []
        }
        return dataStore.locations.filter { location in
            location.locationName.localizedCaseInsensitiveContains(searchText) ||
            location.locationAddress.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region,
                    showsUserLocation: true,
                    userTrackingMode: $userTrackingMode,
                    annotationItems: dataStore.locations) { location in
                    MapAnnotation(coordinate: location.coordinate ?? CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)) {
                        NavigationLink(destination: LocationDetailView(location: location)) {
                            CourtAnnotationView(
                                location: location,
                                isSelected: selectedLocation?.locationId == location.locationId
                            )
                        }
                    }
                }
                .ignoresSafeArea()
                
                // Search and controls overlay
                VStack(spacing: 16) {
                    // Search bar with results
                    VStack(spacing: 0) {
                        // Search bar container
                        HStack(spacing: 16) {
                            // Search bar
                            MapSearchBar(text: $searchText)
                                .frame(maxWidth: .infinity)
                            
                            // Recenter button
                            Button(action: {
                                if let userLocation = locationManager.location?.coordinate {
                                    withAnimation {
                                        region.center = userLocation
                                        region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    }
                                }
                            }) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(ModernColorScheme.primary)
                                    .frame(width: 40, height: 40)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Search results
                        if !searchText.isEmpty && !filteredLocations.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(filteredLocations) { location in
                                    Button(action: {
                                        navigateToLocation(location)
                                    }) {
                                        HStack(spacing: 12) {
                                            // Location icon
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(ModernColorScheme.primary)
                                                .font(.system(size: 24))
                                            
                                            // Location details
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(location.locationName)
                                                    .foregroundColor(.black)
                                                    .font(.system(size: 16, weight: .medium))
                                                Text(location.locationAddress)
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 14))
                                            }
                                            Spacer()
                                            
                                            // Navigate arrow
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                    }
                                    
                                    if location.id != filteredLocations.last?.id {
                                        Divider()
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom info card
                    if let nearestLocation = getNearestLocation() {
                        Button(action: {
                            navigateToLocation(nearestLocation)
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nearest Court")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(nearestLocation.locationName)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.black)
                                        Text(nearestLocation.locationAddress)
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    // Active players badge
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.3.fill")
                                            .foregroundColor(ModernColorScheme.primary)
                                        Text("\(nearestLocation.locationActivePlayers)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(ModernColorScheme.primary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(ModernColorScheme.primary.opacity(0.1))
                                    .cornerRadius(16)
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .onAppear {
            locationManager.requestLocation()
        }
        .onChange(of: locationManager.location) { newLocation in
            if !hasSetInitialLocation, let userLocation = newLocation?.coordinate {
                hasSetInitialLocation = true
                withAnimation {
                    region.center = userLocation
                    region.span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                }
            }
        }
    }
    
    private func navigateToLocation(_ location: Location) {
        searchText = ""  // Clear search text
        
        // Animate to the selected location
        if let coordinate = location.coordinate {
            withAnimation {
                region.center = coordinate
                region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            }
        }
    }
    
    private func getNearestLocation() -> Location? {
        guard let userLocation = locationManager.location else { return nil }
        
        return dataStore.locations.min { location1, location2 in
            guard let coord1 = location1.coordinate,
                  let coord2 = location2.coordinate else { return false }
            
            let distance1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
                .distance(from: userLocation)
            let distance2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
                .distance(from: userLocation)
            
            return distance1 < distance2
        }
    }
}

struct MapSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16))
            
            TextField("Search courts...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.black)
                .font(.system(size: 16))
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct CourtAnnotationView: View {
    let location: Location
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(ModernColorScheme.primary)
                    .frame(width: 40, height: 40)
                    .shadow(color: ModernColorScheme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: "basketball.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            if isSelected {
                Text(location.locationName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
    }
}

// Helper view for the location list
struct LocationListView: View {
    let locations: [Location]
    @Binding var selectedLocation: Location?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(locations) { location in
                    Button(action: {
                        selectedLocation = location
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(location.locationName)
                                    .font(.headline)
                                Text(location.locationAddress)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                }
            }
            .padding()
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.3)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
}

struct LocationListItem: View {
    let location: Location
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(location.locationName)
                .font(.headline)
            Text(location.locationAddress)
                .font(.subheadline)
                .foregroundColor(.gray)
            HStack {
                if let type = location.locationType {
                    Text(type.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                if let isLit = location.isLitAtNight {
                    Text(isLit ? "Lit at Night" : "Not Lit")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isLit ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .cornerRadius(8)
                }
                Text("\(location.locationActivePlayers) Active")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MapViewContent_Previews: PreviewProvider {
    static var previews: some View {
        MapViewContent()
    }
}
