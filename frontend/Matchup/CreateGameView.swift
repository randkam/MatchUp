import SwiftUI

struct CreateGameView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var gameTitle = ""
    @State private var gameType = "3v3"
    @State private var maxPlayers = 6
    @State private var location = ""
    @State private var date = Date()
    @State private var description = ""
    @State private var showLocationPicker = false
    @State private var showDatePicker = false
    @State private var isAnimating = false
    
    let gameTypes = ["3v3", "5v5", "1v1", "Tournament"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Game Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Game Title")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        
                        TextField("Enter game title", text: $gameTitle)
                            .font(ModernFontScheme.body)
                            .padding()
                            .background(ModernColorScheme.surface)
                            .foregroundColor(ModernColorScheme.text)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ModernColorScheme.primary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : -50)
                    .animation(.easeOut(duration: 0.8), value: isAnimating)
                    
                    // Game Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Game Type")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        
                        Picker("Game Type", selection: $gameType) {
                            ForEach(gameTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        .background(ModernColorScheme.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ModernColorScheme.primary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : -50)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)
                    
                    // Max Players
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Maximum Players")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        
                        Stepper(value: $maxPlayers, in: 2...20) {
                            Text("\(maxPlayers) players")
                                .font(ModernFontScheme.body)
                                .foregroundColor(ModernColorScheme.text)
                        }
                        .padding()
                        .background(ModernColorScheme.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ModernColorScheme.primary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : -50)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: isAnimating)
                    
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        
                        Button(action: { showLocationPicker = true }) {
                            HStack {
                                Text(location.isEmpty ? "Select location" : location)
                                    .font(ModernFontScheme.body)
                                    .foregroundColor(location.isEmpty ? ModernColorScheme.textSecondary : ModernColorScheme.text)
                                Spacer()
                                Image(systemName: "location.fill")
                                    .foregroundColor(ModernColorScheme.primary)
                            }
                            .padding()
                            .background(ModernColorScheme.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ModernColorScheme.primary.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : -50)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: isAnimating)
                    
                    // Date and Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date & Time")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        
                        Button(action: { showDatePicker = true }) {
                            HStack {
                                Text(date, style: .date)
                                    .font(ModernFontScheme.body)
                                    .foregroundColor(ModernColorScheme.text)
                                Text(date, style: .time)
                                    .font(ModernFontScheme.body)
                                    .foregroundColor(ModernColorScheme.text)
                                Spacer()
                                Image(systemName: "calendar")
                                    .foregroundColor(ModernColorScheme.primary)
                            }
                            .padding()
                            .background(ModernColorScheme.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ModernColorScheme.primary.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : -50)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: isAnimating)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(ModernFontScheme.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                        
                        TextEditor(text: $description)
                            .font(ModernFontScheme.body)
                            .frame(height: 100)
                            .padding()
                            .background(ModernColorScheme.surface)
                            .foregroundColor(ModernColorScheme.text)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ModernColorScheme.primary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : -50)
                    .animation(.easeOut(duration: 0.8).delay(1.0), value: isAnimating)
                    
                    // Create Button
                    Button(action: createGame) {
                        Text("Create Game")
                            .font(ModernFontScheme.body)
                            .foregroundColor(ModernColorScheme.text)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ModernColorScheme.primary)
                            .cornerRadius(12)
                            .shadow(color: ModernColorScheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 50)
                    .animation(.easeOut(duration: 0.8).delay(1.2), value: isAnimating)
                }
                .padding(.vertical)
            }
            .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
            .navigationTitle("Create Game")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(location: $location)
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerView(date: $date)
            }
            .onAppear {
                isAnimating = true
            }
        }
    }
    
    private func createGame() {
        // Validate inputs
        guard !gameTitle.isEmpty, !location.isEmpty else {
            // Show error alert
            return
        }
        
        // Create game logic here
        dismiss()
    }
}

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var location: String
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredLocations, id: \.self) { location in
                    Button(action: {
                        self.location = location
                        dismiss()
                    }) {
                        HStack {
                            Text(location)
                            Spacer()
                            if self.location == location {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ModernColorScheme.primary)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search location")
            .navigationTitle("Select Location")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private var filteredLocations: [String] {
        if searchText.isEmpty {
            return ["Central Park", "Local Court", "Community Center", "School Gym", "Sports Complex"]
        }
        return ["Central Park", "Local Court", "Community Center", "School Gym", "Sports Complex"]
            .filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
}

struct DatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date & Time",
                          selection: $date,
                          displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Select Date & Time")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
} 