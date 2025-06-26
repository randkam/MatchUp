//import SwiftUI
//import MapKit
//import CoreLocation
//
//struct MapView: View {
//    @StateObject private var locationManager = LocationManager()
//    @ObservedObject private var dataStore = SharedDataStore.shared
//    @State private var selectedLocation: Location? = nil
//    @State private var nearbyLocation: Location? = nil
//    @State private var region = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 43.7800, longitude: -79.3350),
//        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//    )
//    
//    var filteredLocations: [Location] {
//        // Implement your filtering logic here
//        return dataStore.locations
//    }
//    
//    var body: some View {
//        Map(coordinateRegion: $region,
//            showsUserLocation: true,
//            annotationItems: filteredLocations) { location in
//            MapAnnotation(coordinate: location.coordinate) {
//                LocationAnnotationView(
//                    location: location,
//                    isSelected: selectedLocation?.locationId == location.locationId
//                )
//                .onTapGesture {
//                    selectedLocation = location
//                }
//            }
//        }
//        .edgesIgnoringSafeArea(.all)
//        .sheet(item: $selectedLocation) { location in
//            LocationDetailView(location: location)
//        }
//        .onAppear {
//            locationManager.requestLocation()
//        }
//    }
//}
//
//struct LocationAnnotationView: View {
//    let location: Location
//    let isSelected: Bool
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            Image(systemName: "basketball.fill")
//                .font(.system(size: 24))
//                .foregroundColor(isSelected ? .white : ModernColorScheme.primary)
//                .padding(8)
//                .background(isSelected ? ModernColorScheme.primary : .white)
//                .clipShape(Circle())
//                .shadow(radius: 2)
//            
//            if isSelected {
//                Text(location.locationName)
//                    .font(ModernFontScheme.caption)
//                    .foregroundColor(ModernColorScheme.text)
//                    .padding(4)
//                    .background(ModernColorScheme.surface)
//                    .cornerRadius(4)
//                    .shadow(radius: 2)
//            }
//        }
//    }
//}
