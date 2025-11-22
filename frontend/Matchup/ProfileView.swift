import SwiftUI
import UIKit

struct ProfileView: View {
    var body: some View {
        let userId = UserDefaults.standard.integer(forKey: "loggedInUserId")
        UserProfileView(userId: userId)
    }

}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var height: CGFloat = 120

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ModernColorScheme.accentMinimal)

            Text(value)
                .font(ModernFontScheme.heading)
                .foregroundColor(ModernColorScheme.text)

            Text(title)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(15)
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    var height: CGFloat = 120

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ModernColorScheme.primary)
            Text(value)
                .font(ModernFontScheme.body)
                .foregroundColor(ModernColorScheme.text)
                .lineLimit(1)
            Text(title)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .padding()
        .background(ModernColorScheme.surface)
        .cornerRadius(15)
    }
}

//hello
