import SwiftUI
import CoreLocation

// Model for recent activity
struct RecentActivity: Identifiable {
    let id = UUID()
    let court: String
    let date: String
    let type: String
    let result: String
}

// Favorite Court Row
struct FavoriteCourtRow: View {
    let courtName: String
    
    var body: some View {
        HStack {
            Image(systemName: "basketball.fill")
                .foregroundColor(ModernColorScheme.accentMinimal)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(ModernColorScheme.surface)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(courtName)
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.text)
                
                // TODO: Implement rating system
                // let rating = SharedDataStore.shared.locations.first(where: { $0.locationName == courtName })?.locationRating ?? 4.0
                Text("⭐ Coming Soon")
                    .font(ModernFontScheme.caption)
                    .foregroundColor(ModernColorScheme.textSecondary)
            }
            
            Spacer()
            
            Button(action: {
                // Navigate to court details
            }) {
                Text("Visit")
                    .font(ModernFontScheme.caption)
                    .foregroundColor(.white)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 12)
                    .background(ModernColorScheme.accentMinimal)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(12)
        .shadow(color: ModernColorScheme.accentMinimal.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Recent Activity Row
struct RecentActivityRow: View {
    let activity: RecentActivity
    
    var body: some View {
        HStack {
            Image(systemName: activity.type == "Played Game" ? "basketball.fill" : "message.fill")
                .foregroundColor(ModernColorScheme.accentMinimal)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(ModernColorScheme.surface)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.court)
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.text)
                
                HStack {
                    Text(activity.type)
                        .font(ModernFontScheme.caption)
                        .foregroundColor(ModernColorScheme.textSecondary)
                    
                    if !activity.result.isEmpty {
                        Text("•")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        
                        Text(activity.result)
                            .font(ModernFontScheme.caption)
                            .foregroundColor(activity.result == "Won" ? .green : .red)
                    }
                }
            }
            
            Spacer()
            
            Text(activity.date)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
        }
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(12)
        .shadow(color: ModernColorScheme.accentMinimal.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Availability Selection View
struct AvailabilitySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTimes: [String]
    let allTimes: [String]
    
    var body: some View {
        List(allTimes, id: \.self) { time in
            Button(action: {
                if selectedTimes.contains(time) {
                    selectedTimes.removeAll { $0 == time }
                } else {
                    selectedTimes.append(time)
                }
            }) {
                HStack {
                    Text(time)
                    Spacer()
                    if selectedTimes.contains(time) {
                        Image(systemName: "checkmark")
                            .foregroundColor(ModernColorScheme.accentMinimal)
                    }
                }
            }
        }
        .navigationTitle("Availability")
        .navigationBarItems(trailing: Button("Done") { dismiss() })
    }
}

// Favorite Court Selection View
struct FavoriteCourtSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCourts: [String] = []
    
    // Use the shared data store for location data
    @ObservedObject private var dataStore = SharedDataStore.shared
    
    var body: some View {
        List {
            ForEach(dataStore.locations, id: \.locationId) { location in
                Button(action: {
                    if selectedCourts.contains(location.locationName) {
                        selectedCourts.removeAll { $0 == location.locationName }
                    } else {
                        selectedCourts.append(location.locationName)
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(location.locationName)
                                .font(ModernFontScheme.body)
                            
                            // TODO: Implement rating and court type
                            Text("Details coming soon")
                                .font(ModernFontScheme.caption)
                                .foregroundColor(ModernColorScheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        if selectedCourts.contains(location.locationName) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                        } else {
                            Image(systemName: "heart")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .navigationTitle("Favorite Courts")
        .navigationBarItems(trailing: Button("Done") { dismiss() })
        .onAppear {
            // Initialize with current favorites
            selectedCourts = ["Earl Haig Secondary School", "Newtonbrook Secondary School", "Georges Vanier Secondary School"]
        }
    }
}

struct ProfileSettingsRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ModernColorScheme.accentMinimal)
            Text(title)
                .font(ModernFontScheme.body)
                .foregroundColor(ModernColorScheme.text)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(ModernColorScheme.textSecondary)
        }
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(15)
        .padding(.horizontal)
    }
}
