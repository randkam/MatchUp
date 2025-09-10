import SwiftUI
import CoreLocation

struct CustomTabView: View {
    @StateObject private var authCoordinator = AuthenticationCoordinator.shared
    @State private var selectedTab = 0
    @State private var selectedCoordinate: IdentifiableCoordinate? = nil

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // NavigationStack {
                //     HomeView(selectedCoordinate: $selectedCoordinate)
                // }
                // .tabItem {
                //     Label("Home", systemImage: "house.fill")
                // }
                // .tag(0)
                // 
                // NavigationStack {
                //     MapViewContent()
                // }
                // .tabItem {
                //     Label("Map", systemImage: "map.fill")
                // }
                // .tag(1)
                // 
                // NavigationStack {
                //     ChatView()
                // }
                // .tabItem {
                //     Label("Chat", systemImage: "message.fill")
                // }
                // .tag(2)

                NavigationStack {
                    TournamentsView()
                }
                .tabItem {
                    Label("Tournaments", systemImage: "trophy.fill")
                }
                .tag(0)
                
                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(1)
            }
        }
        .accentColor(ModernColorScheme.primary)
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? ModernColorScheme.primary : ModernColorScheme.textSecondary)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(label)
                    .font(ModernFontScheme.caption)
                    .foregroundColor(isSelected ? ModernColorScheme.primary : ModernColorScheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct CustomTabView_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabView()
    }
}
