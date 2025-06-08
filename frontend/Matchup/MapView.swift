import SwiftUI
import MapKit
import UserNotifications
import CoreLocation

struct UserProfile {
    var username: String
    var isOnline: Bool
    var memoji: String
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    override init() {
        authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location every 10 meters
        locationManager.startUpdatingLocation()
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
}

class NotificationManager: NSObject {
    static let shared = NotificationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    func requestAuthorization() {
        // Request authorization with all options
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            if granted {
                print("Notification authorization granted")
                
                // Set up notification categories for interactive notifications
                let joinAction = UNNotificationAction(identifier: "JOIN_COURT", title: "Join Court", options: .foreground)
                let viewAction = UNNotificationAction(identifier: "VIEW_DETAILS", title: "View Details", options: .foreground)
                let category = UNNotificationCategory(identifier: "COURT_NEARBY", actions: [joinAction, viewAction], intentIdentifiers: [], options: [])
                self.notificationCenter.setNotificationCategories([category])
            } else if let error = error {
                print("Notification authorization denied: \(error.localizedDescription)")
            }
        }
    }
    
    func sendNearbyCourtNotification(courtName: String, distance: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Basketball Court Nearby!"
        content.body = "\(courtName) is just \(String(format: "%.1f", distance)) km away. Tap to join the court chat!"
        content.sound = UNNotificationSound.defaultCritical
        content.badge = 1
        content.userInfo = ["courtName": courtName]
        content.categoryIdentifier = "COURT_NEARBY"
        
        // Set up notification categories and actions
        let joinAction = UNNotificationAction(identifier: "JOIN_COURT", title: "Join Court", options: .foreground)
        let viewAction = UNNotificationAction(identifier: "VIEW_DETAILS", title: "View Details", options: .foreground)
        let category = UNNotificationCategory(identifier: "COURT_NEARBY", actions: [joinAction, viewAction], intentIdentifiers: [], options: [])
        notificationCenter.setNotificationCategories([category])
        
        // Use a time interval trigger to show immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            } else {
                print("Successfully sent notification for nearby court: \(courtName)")
            }
        }
    }
}

struct MapViewContent: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.7800, longitude: -79.3350),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var userProfile = UserProfile(username: "User1", isOnline: true, memoji: "🧑‍🦱")
    @State private var showingProfile = false
    @State private var selectedSchool: BasketballSchool? = nil
    @State private var showingSchoolDetail = false
    
    // Add notification handler for court join events
    init() {
        // This empty initializer is needed for the onReceive modifier to work properly
    }
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedFilter: FilterOption = .all
    @State private var nearbySchools: Set<UUID> = []  // Track schools we've already notified about
    @State private var showNearbyAlert = false
    @State private var nearbySchool: BasketballSchool? = nil
    
    // Default to Toronto area if no coordinate is provided
    var selectedCoordinate: IdentifiableCoordinate? = nil
    
    // Use the shared data store for court data
    @ObservedObject private var dataStore = SharedDataStore.shared

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case nearby = "Nearby"
        case active = "Active"
        case inactive = "Inactive"
    }
    
    var filteredSchools: [BasketballSchool] {
        // Filter by search text first
        var filtered = dataStore.basketballCourts
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Then apply the selected filter
        switch selectedFilter {
        case .all:
            return filtered
        case .nearby:
            // Sort by distance to user's location
            if let userLocation = locationManager.location {
                return filtered.sorted { school1, school2 in
                    let location1 = CLLocation(latitude: school1.coordinate.latitude, longitude: school1.coordinate.longitude)
                    let location2 = CLLocation(latitude: school2.coordinate.latitude, longitude: school2.coordinate.longitude)
                    return userLocation.distance(from: location1) < userLocation.distance(from: location2)
                }
            }
            return filtered
        case .active:
            return filtered.filter { $0.activePlayers > 0 }
        case .inactive:
            return filtered.filter { $0.activePlayers == 0 }
        }
    }

    var body: some View {
        ZStack {
            // Using the newer Map API for iOS 17+
            MapReader { proxy in
                // Create a simpler binding that doesn't use pattern matching
                Map(position: Binding<MapCameraPosition>(
                    get: { .region(region) },
                    set: { _ in
                        // We'll handle position updates through the MapReader instead
                    }
                ), interactionModes: .all) {
                    // Add UserAnnotation for user location with a blue dot
                    UserAnnotation()
                        .tint(.blue)
                    
                    // Display user's location with a more prominent pulsing effect
                    if let userLocation = locationManager.location?.coordinate {
                        Annotation("", coordinate: userLocation) {
                            ZStack {
                                // Outer pulsing circle
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                // Middle pulsing circle
                                Circle()
                                    .fill(Color.blue.opacity(0.4))
                                    .frame(width: 30, height: 30)
                                
                                // Inner solid circle
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 15, height: 15)
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 18, height: 18)
                            )
                        }
                        .annotationTitles(.visible)
                    }
                    
                    ForEach(filteredSchools) { school in
                        Annotation("", coordinate: school.coordinate) {
                            SchoolAnnotationView(school: school)
                                .onTapGesture {
                                    selectedSchool = school
                                    showingSchoolDetail = true
                                }
                        }
                        .annotationTitles(.hidden)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                // Enable swipe gestures for the map
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            // Handle swipe gestures to navigate the map
                            let horizontalAmount = value.translation.width
                            let verticalAmount = value.translation.height
                            
                            // Calculate new center based on swipe direction and magnitude
                            let newLatitude = region.center.latitude - (verticalAmount * 0.0001)
                            let newLongitude = region.center.longitude + (horizontalAmount * 0.0001)
                            
                            withAnimation {
                                region.center = CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
                            }
                        }
                )
                .mapStyle(.standard)
            }
            .onAppear {
                // Start with the selected coordinate if provided, otherwise use default region
                if let selectedCoordinate = selectedCoordinate {
                    region.center = selectedCoordinate.coordinate
                }
                region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                
                // Request location permissions
                locationManager.requestAuthorization()
                
                // Request notification permissions
                NotificationManager.shared.requestAuthorization()
            }
            .onChange(of: locationManager.location) { _, newLocation in
                if let location = newLocation {
                    // Print location update for debugging
                    print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    
                    // Update the map region to follow the user's location
                    withAnimation {
                        region.center = location.coordinate
                    }
                    
                    // Check for nearby courts with a slight delay to ensure UI is updated first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        checkForNearbyCourts(userLocation: location)
                    }
                    
                    // Show notification to user about location tracking
                    if nearbySchools.isEmpty { // Only show once
                        let notificationContent = UNMutableNotificationContent()
                        notificationContent.title = "MatchUp Location Tracking"
                        notificationContent.body = "We're tracking your location to find basketball courts near you."
                        notificationContent.sound = UNNotificationSound.default
                        
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                        let request = UNNotificationRequest(identifier: "location_tracking", content: notificationContent, trigger: trigger)
                        UNUserNotificationCenter.current().add(request) { error in
                            if let error = error {
                                print("Error sending location tracking notification: \(error.localizedDescription)")
                            } else {
                                print("Successfully sent location tracking notification")
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack {
                // Search and Filter Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search courts...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.title2)
                            .foregroundColor(ModernColorScheme.primary)
                    }
                }
                .padding()
                
                Spacer()
                
                // Current location button
                Button(action: {
                    if let location = locationManager.location?.coordinate {
                        withAnimation {
                            region.center = location
                            region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        }
                    }
                }) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(ModernColorScheme.primary)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding()
                .offset(x: 150, y: -20) // Position in bottom right
            }
        }
        .sheet(isPresented: $showingSchoolDetail) {
            if let school = selectedSchool {
                BasketballCourtDetailView(school: school)
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(selectedFilter: $selectedFilter)
        }
        .alert(isPresented: $showNearbyAlert) {
            Alert(
                title: Text("Basketball Court Nearby"),
                message: Text("\(nearbySchool?.name ?? "") is nearby with \(nearbySchool?.activePlayers ?? 0) active players. Would you like to check it out?"),
                primaryButton: .default(Text("View Court")) {
                    if let school = nearbySchool {
                        selectedSchool = school
                        showingSchoolDetail = true
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("JoinCourt"))) { notification in
            if let courtId = notification.userInfo?["courtId"] as? UUID {
                // Find the court and update its player count
                if let index = dataStore.basketballCourts.firstIndex(where: { $0.id == courtId }) {
                    // Update the player count and add the current user
                    dataStore.basketballCourts[index].activePlayers += 1
                    if dataStore.basketballCourts[index].usernames.isEmpty {
                        dataStore.basketballCourts[index].usernames = ["You"]
                    } else {
                        dataStore.basketballCourts[index].usernames.append("You")
                    }
                    
                    // Provide haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Show a confirmation message
                    print("Successfully joined court: " + dataStore.basketballCourts[index].name)
                }
            }
        }
    }
    
    // Function to check for nearby courts
    private func checkForNearbyCourts(userLocation: CLLocation) {
        // Make the threshold larger to ensure we detect courts
        let proximityThreshold = 1.0 // 1 kilometer
        
        // Print current location for debugging
        print("Current location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
        
        for school in dataStore.basketballCourts {
            let schoolLocation = CLLocation(latitude: school.coordinate.latitude, longitude: school.coordinate.longitude)
            let distance = userLocation.distance(from: schoolLocation) / 1000 // Convert to kilometers
            
            // Print distance for debugging
            print("Distance to \(school.name): \(distance) km")
            
            // If the school is within the threshold and we haven't notified about it yet
            if distance <= proximityThreshold && !nearbySchools.contains(school.id) {
                print("Found nearby court: \(school.name) at \(distance) km")
                
                // Add to the set of notified schools
                nearbySchools.insert(school.id)
                
                // Send a notification
                NotificationManager.shared.sendNearbyCourtNotification(courtName: school.name, distance: distance)
                
                // Show an in-app alert
                nearbySchool = school
                showNearbyAlert = true
                
                // Only notify about one court at a time to avoid overwhelming the user
                break
            }
        }
    }
}

struct SchoolAnnotationView: View {
    let school: BasketballSchool
    @State private var showDetails = false
    @State private var showChat = false
    
    // Timer to auto-hide details after a few seconds
    let autoHideTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(ModernColorScheme.primary)
                    .frame(width: 50, height: 50) // Increased size for easier tapping
                    .shadow(radius: 3)
                
                Image(systemName: "basketball.fill")
                    .font(.system(size: 24)) // Increased icon size
                    .foregroundColor(.white)
            }
            
            // Player count badge
            ZStack {
                Capsule()
                    .fill(school.activePlayers > 0 ? Color.green : Color.gray)
                    .frame(width: 45, height: 24) // Increased size for easier tapping
                
                HStack(spacing: 2) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 12)) // Increased icon size
                        .foregroundColor(.white)
                    
                    Text("\(school.activePlayers)")
                        .font(.system(size: 12, weight: .bold)) // Increased text size
                        .foregroundColor(.white)
                }
            }
            
            // Court name (shown when tapped)
            if showDetails {
                VStack(spacing: 4) {
                    Text(school.name)
                        .font(.system(size: 14, weight: .medium)) // Increased text size
                        .foregroundColor(.black) // Fixed text color to ensure visibility
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(school.courtType)
                        .font(.system(size: 12)) // Increased text size
                        .foregroundColor(.gray)
                    
                    Text("⭐ \(String(format: "%.1f", school.rating))")
                        .font(.system(size: 12, weight: .bold)) // Increased text size
                        .foregroundColor(ModernColorScheme.primary)
                    
                    // Join/Create Game button
                    Button {
                        // Provide strong haptic feedback when button is tapped
                        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                        impactFeedback.prepare()
                        impactFeedback.impactOccurred()
                        
                        // Print debug information
                        print("Button tapped for court: " + school.name)
                        
                        // Update player count for demonstration purposes
                        if school.activePlayers == 0 {
                            // If no active players, add the current user
                            NotificationCenter.default.post(name: NSNotification.Name("JoinCourt"), object: nil, userInfo: ["courtId": school.id])
                            print("Creating new game at: " + school.name)
                        } else {
                            print("Joining existing game at: " + school.name)
                        }
                        
                        // Show chat view
                        showChat = true
                    } label: {
                        if school.activePlayers == 0 {
                            Text("Create Game")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(ModernColorScheme.primary)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                        } else {
                            Text("Join Chat")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.green)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .contentShape(Rectangle())
                    .scaleEffect(1.05) // Make button slightly larger
                }
                .padding(10) // Increased padding
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 3)
                .frame(width: 160) // Increased width for better readability
            }
        }
        .padding(showDetails ? 10 : 6) // Increased padding
        .background(Color.white)
        .cornerRadius(12) // Increased corner radius
        .shadow(radius: 4, x: 0, y: 2) // Enhanced shadow
        .onTapGesture {
            withAnimation(.spring()) {
                showDetails.toggle()
                
                // Reset the auto-hide timer when details are shown
                if showDetails {
                    // The timer will automatically hide details after 5 seconds
                }
            }
        }
        .onReceive(autoHideTimer) { _ in
            // Auto-hide details after timer fires
            if showDetails {
                withAnimation(.spring()) {
                    showDetails = false
                }
            }
        }

        .sheet(isPresented: $showChat) {
            CourtChatView(courtName: school.name, isNewGame: school.activePlayers == 0)
        }
    }
}

struct FilterView: View {
    @Binding var selectedFilter: MapViewContent.FilterOption
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(MapViewContent.FilterOption.allCases, id: \.self) { filter in
                Button(action: {
                    selectedFilter = filter
                    dismiss()
                }) {
                    HStack {
                        Text(filter.rawValue)
                        Spacer()
                        if selectedFilter == filter {
                            Image(systemName: "checkmark")
                                .foregroundColor(ModernColorScheme.primary)
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        let previewCoordinate = IdentifiableCoordinate(coordinate: CLLocationCoordinate2D(latitude: 43.7800, longitude: -79.3350))
        // Create a preview with default values
        MapViewContent()
    }
}
