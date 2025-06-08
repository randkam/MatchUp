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
                .foregroundColor(ModernColorScheme.primary)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(ModernColorScheme.surface)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(courtName)
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.text)
                
                // Find the matching school to get the rating
                let rating = SharedDataStore.shared.basketballCourts.first(where: { $0.name == courtName })?.rating ?? 4.0
                
                Text("⭐ \(String(format: "%.1f", rating))")
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
                    .background(ModernColorScheme.primary)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(12)
        .shadow(color: ModernColorScheme.primary.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Recent Activity Row
struct RecentActivityRow: View {
    let activity: RecentActivity
    
    var body: some View {
        HStack {
            Image(systemName: activity.type == "Played Game" ? "basketball.fill" : "message.fill")
                .foregroundColor(ModernColorScheme.primary)
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
        .shadow(color: ModernColorScheme.primary.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Availability Selection View
struct AvailabilitySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTimes: [String]
    let allTimes: [String]
    
    var body: some View {
        List {
            ForEach(allTimes, id: \.self) { time in
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
                                .foregroundColor(ModernColorScheme.primary)
                        }
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
    
    // Use the shared data store for court data
    @ObservedObject private var dataStore = SharedDataStore.shared
    
    var body: some View {
        List {
            ForEach(dataStore.basketballCourts, id: \.id) { school in
                Button(action: {
                    if selectedCourts.contains(school.name) {
                        selectedCourts.removeAll { $0 == school.name }
                    } else {
                        selectedCourts.append(school.name)
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(school.name)
                                .font(ModernFontScheme.body)
                            
                            HStack {
                                Text("⭐ \(String(format: "%.1f", school.rating))")
                                Text("•")
                                Text("\(school.courtType)")
                            }
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        if selectedCourts.contains(school.name) {
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
