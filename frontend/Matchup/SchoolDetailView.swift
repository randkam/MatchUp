import SwiftUI
import CoreLocation

// Renamed to avoid conflict with existing SchoolDetailView in Untitled 2.swift
struct BasketballCourtDetailView: View {
    let school: BasketballSchool
    @Environment(\.presentationMode) var presentationMode
    @State private var showChat = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image
                ZStack(alignment: .topTrailing) {
                    Image("basketball_court")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(20)
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(ModernColorScheme.text)
                            .padding(10)
                            .background(ModernColorScheme.surface.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                
                // Court Title
                Text(school.name)
                    .font(ModernFontScheme.title)
                    .foregroundColor(ModernColorScheme.text)
                    .padding(.horizontal)
                
                // Court Description
                Text(school.description)
                    .font(ModernFontScheme.body)
                    .foregroundColor(ModernColorScheme.text)
                    .padding(.horizontal)
                
                // Court Details
                VStack(alignment: .leading, spacing: 15) {
                    DetailRow(icon: "person.3.fill", text: "\(school.activePlayers) active players")
                    DetailRow(icon: "star.fill", text: "\(school.rating) (\(Int.random(in: 80...150)) ratings)")
                    DetailRow(icon: "clock.fill", text: "Open \(school.openHours)")
                    DetailRow(icon: "basketball.fill", text: school.courtType)
                }
                .padding(.horizontal)
                
                // Active Players
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active Players")
                        .font(ModernFontScheme.heading)
                        .foregroundColor(ModernColorScheme.text)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(school.usernames, id: \.self) { username in
                                PlayerBubble(username: username)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Live Chat Banner
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(ModernColorScheme.primary.opacity(0.2))
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Live Court Chat")
                                .font(ModernFontScheme.heading)
                                .foregroundColor(ModernColorScheme.text)
                            
                            Text("\(school.activePlayers) players active in chat")
                                .font(ModernFontScheme.caption)
                                .foregroundColor(ModernColorScheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showChat = true
                        }) {
                            Text("Join Now")
                                .font(ModernFontScheme.caption.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(ModernColorScheme.primary)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                .frame(height: 80)
                .padding(.horizontal)
                
                // Buttons
                HStack(spacing: 15) {
                    Button(action: {
                        // Navigate to this court on the map
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Navigate")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ModernColorScheme.primary)
                        .foregroundColor(ModernColorScheme.text)
                        .cornerRadius(15)
                    }
                    
                    Button(action: {
                        showChat = true
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Join Chat")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ModernColorScheme.secondary)
                        .foregroundColor(ModernColorScheme.text)
                        .cornerRadius(15)
                    }
                }
                .padding()
            }
        }
        .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showChat) {
//            CourtChatView(courtName: school.name)
        }
    }
}

struct PlayerBubble: View {
    let username: String
    
    var body: some View {
        VStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(ModernColorScheme.primary)
                .background(ModernColorScheme.surface)
                .clipShape(Circle())
            
            Text(username)
                .font(ModernFontScheme.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 70)
    }
}
