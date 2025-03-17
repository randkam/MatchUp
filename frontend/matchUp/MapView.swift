import SwiftUI
import MapKit
import UserNotifications
import CoreLocation

struct School: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let activePlayers: Int
    let usernames: [String]
}

struct UserProfile {
    var username: String
    var isOnline: Bool
    var memoji: String
}

struct MapViewContent: View {  // Renamed from ContentView to avoid conflicts
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.7800, longitude: -79.3350),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @State private var userLocation = CLLocationCoordinate2D(latitude: 43.7800, longitude: -79.3350)
    @State private var userProfile = UserProfile(username: "User1", isOnline: true, memoji: "🧑‍🦱")
    @State private var showingProfile = false
    @State private var selectedSchool: School? = nil
    @State private var showingSchoolDetail = false
    
    @State private var schools = [
        School(name: "Dr Norman Bethune Collegiate Institute", coordinate: CLLocationCoordinate2D(latitude: 43.8016, longitude: -79.3181), activePlayers: 5, usernames: ["player1", "player2", "player3"]),
        School(name: "Lester B. Pearson Collegiate Institute", coordinate: CLLocationCoordinate2D(latitude: 43.8035, longitude: -79.2256), activePlayers: 3, usernames: ["playerA", "playerB"]),
        // ... other schools
    ]

    var selectedCoordinate: CLLocationCoordinate2D?

    init(selectedCoordinate: CLLocationCoordinate2D? = nil) {
        self.selectedCoordinate = selectedCoordinate
        if let coordinate = selectedCoordinate {
            self._region = State(initialValue: MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    var body: some View {
        ZStack {
            Map(coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: false,
                annotationItems: schools) { school in
                    MapAnnotation(coordinate: school.coordinate) {
                        Button(action: {
                            selectedSchool = school
                            showingSchoolDetail = true
                        }) {
                            Image(systemName: "basketball.circle.fill")
                                .foregroundColor(.red)
                                .font(.title)
                        }
                    }
            }
            .onAppear {
                if let coordinate = selectedCoordinate {
                    region.center = coordinate
                    region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                }
            }
            .overlay(
                Button(action: {
                    showingProfile.toggle()
                }) {
                    Circle()
                        .fill(userProfile.isOnline ? Color.green : Color.gray)
                        .frame(width: 20, height: 20)
                }
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                .popover(isPresented: $showingProfile) {
                    VStack {
                        Text(userProfile.memoji)
                            .font(.largeTitle)
                        Text(userProfile.username)
                            .font(.title3)
                        Text(userProfile.isOnline ? "Online" : "Away")
                            .font(.footnote)
                            .foregroundColor(userProfile.isOnline ? .green : .gray)
                    }
                    .padding()
                }
            )
        }
        .sheet(isPresented: $showingSchoolDetail) {
            if let school = selectedSchool {
                SchoolDetailView(
                    school: school,
                    usernames: school.usernames
                )
            }
        }
        .onAppear {
//            requestNotificationPermission()
//            startProximityCheck()
        }
        .navigationTitle("Map")
    }
    
    // Add proximity checks, notifications, and permissions functions here...
}
