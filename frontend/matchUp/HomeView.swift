import SwiftUI
import CoreLocation

// Identifiable Coordinate to store user-selected location
struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// Filter options for sorting the courts
enum FilterOption: String, CaseIterable, Identifiable {
    case closest = "Closest"
    case mostActivePlayers = "Most Active Players"
    
    var id: String { self.rawValue }
}

struct HomeView: View {
    @State private var userLocation = CLLocationCoordinate2D(latitude: 43.7800, longitude: -79.3350)
    @State private var schools = [
        School(name: "Dr Norman Bethune Collegiate Institute", coordinate: CLLocationCoordinate2D(latitude: 43.8016, longitude: -79.3181), activePlayers: 5, usernames: ["player1", "player2", "player3"]),
        School(name: "Lester B. Pearson Collegiate Institute", coordinate: CLLocationCoordinate2D(latitude: 43.8035, longitude: -79.2256), activePlayers: 3, usernames: ["playerA", "playerB"]),
        School(name: "Maplewood High School", coordinate: CLLocationCoordinate2D(latitude: 43.7694, longitude: -79.1927), activePlayers: 2, usernames: ["playerX", "playerY"]),
        School(name: "George B Little Public School", coordinate: CLLocationCoordinate2D(latitude: 43.7654, longitude: -79.2154), activePlayers: 4, usernames: ["playerC", "playerD"]),
        School(name: "David and Mary Thomson Collegiate Institute", coordinate: CLLocationCoordinate2D(latitude: 43.7506, longitude: -79.2707), activePlayers: 1, usernames: ["playerE"]),
        School(name: "Newtonbrook Secondary School", coordinate: CLLocationCoordinate2D(latitude: 43.7981, longitude: -79.4198), activePlayers: 6, usernames: ["playerF", "playerG"]),
        School(name: "Georges Vanier Secondary School", coordinate: CLLocationCoordinate2D(latitude: 43.7772, longitude: -79.3464), activePlayers: 3, usernames: ["playerH", "playerI"]),
        School(name: "Northview Heights Secondary School", coordinate: CLLocationCoordinate2D(latitude: 43.7808, longitude: -79.4391), activePlayers: 2, usernames: ["playerJ", "playerK"]),
        School(name: "Earl Haig Secondary School", coordinate: CLLocationCoordinate2D(latitude: 43.7663, longitude: -79.4018), activePlayers: 7, usernames: ["playerL", "playerM"]),
        School(name: "Don Mills Collegiate Institute", coordinate: CLLocationCoordinate2D(latitude: 43.7380, longitude: -79.3343), activePlayers: 5, usernames: ["playerN", "playerO"])
    ]
    
    @State private var playersVisitedToday: Int = 20
    let totalPlayersToday: Int = 20
    @Binding var selectedCoordinate: IdentifiableCoordinate?
    @State private var filterOption: FilterOption = .closest

    // State to hold the logged-in user's name
    @State private var userName: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Top Section: Home, Hello, Username, and Profile Image
                    HStack {
                        Text("Home")
                            .font(Font.custom("Inter", size: 20))
                            .foregroundColor(.white)
                            .bold()

                        Spacer()

                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Hello Username (dynamic)
                    Text("Hello \(userName)")
                        .font(Font.custom("Inter", size: 40))
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)

                    // Hottest Court Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Hottest Court 🔥")
                                .font(Font.custom("Inter", size: 20))
                                .bold()
                                .foregroundColor(.white)

                            Spacer()

                            HStack(spacing: -8) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .clipShape(Circle())
                                }
                            }
                        }

                        Text("Dr Norman Bethune Collegiate Institute")
                            .font(Font.custom("Inter", size: 16))
                            .foregroundColor(.gray)

                        Text("5 Active Players | 2.8 km")
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(.gray)

                        Text("# of Players Visited Today")
                            .font(Font.custom("Inter", size: 16))
                            .foregroundColor(.white)

                        // Dynamic ProgressView based on 20 players visited out of 20
                        ProgressView(value: Double(playersVisitedToday) / Double(totalPlayersToday))
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(x: 1, y: 4, anchor: .center)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(15)
                    .padding(.horizontal)

                    // Courts Section Header with Filter
                    HStack {
                        Text("Courts")
                            .font(Font.custom("Inter", size: 20))
                            .foregroundColor(.white)
                            .bold()

                        Spacer()

                        // Filter beside Courts
                        Menu {
                            Picker("Filter", selection: $filterOption) {
                                ForEach(FilterOption.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Vertically Scrollable Court Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredSchools) { school in
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
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .onAppear {
                loadUserProfile() // Load the user's profile when view appears
            }
        }
    }

    // Filtered schools based on the selected filter option
    var filteredSchools: [School] {
        switch filterOption {
        case .closest:
            return schools.sorted {
                calculateDistance(to: $0.coordinate) < calculateDistance(to: $1.coordinate)
            }
        case .mostActivePlayers:
            return schools.sorted {
                $0.activePlayers > $1.activePlayers
            }
        }
    }

    // Calculate distance from user's location to the school's location
    func calculateDistance(to coordinate: CLLocationCoordinate2D) -> Double {
        let schoolLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let currentUserLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        return round((currentUserLocation.distance(from: schoolLocation) / 1000) * 10) / 10 // Convert to kilometers and round to 1 decimal place
    }

    // Load the user's profile from UserDefaults
    private func loadUserProfile() {
        if let savedUserName = UserDefaults.standard.string(forKey: "loggedInUserName") {
            userName = savedUserName
        } else {
            userName = "Username" // Fallback if no user is logged in
        }
    }
}

// Custom Court Card View with ellipsis for long school names
struct CourtCardView: View {
    let title: String
    let distance: String
    let activePlayers: Int
    let usernames: [String]
    let navigateToLocation: (CLLocationCoordinate2D) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "basketball")
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: -8) {
                    ForEach(usernames.prefix(2), id: \.self) { _ in
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .clipShape(Circle())
                    }
                }
            }

            Text(distance)
                .font(.caption)
                .foregroundColor(.gray)

            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail) // Use ellipsis for long text

            ProgressView(value: Double(activePlayers) / 10.0)
                .progressViewStyle(LinearProgressViewStyle(tint: activePlayers > 5 ? .green : .yellow))
                .scaleEffect(x: 1, y: 2, anchor: .center)

            HStack {
                Spacer()
                Text("\(activePlayers)/10")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedCoordinate: .constant(nil))
    }
}
