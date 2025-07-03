import SwiftUI
import MapKit

struct FeedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var locationManager = LocationManager()
    
    @State private var feedbackType: FeedbackType = .generalFeedback
    @State private var title = ""
    @State private var description = ""
    @State private var locationName = ""
    @State private var locationAddress = ""
    @State private var showLocationPicker = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    enum FeedbackType: String, CaseIterable {
        case newLocation = "New Location"
        case locationUpdate = "Location Update"
        case appConcern = "App Concern"
        case generalFeedback = "General Feedback"
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Feedback Type
                Section(header: Text("Type")) {
                    Picker("Feedback Type", selection: $feedbackType) {
                        ForEach(FeedbackType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Title and Description
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                // Location Details (for location-related feedback)
                if feedbackType == .newLocation || feedbackType == .locationUpdate {
                    Section(header: Text("Location Details")) {
                        TextField("Location Name", text: $locationName)
                        TextField("Address", text: $locationAddress)
                        Button(action: {
                            showLocationPicker = true
                        }) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                Text("Pick Location on Map")
                            }
                        }
                        if let coordinate = selectedCoordinate {
                            Text("Selected: \(coordinate.latitude), \(coordinate.longitude)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Submit Button
                Section {
                    Button(action: submitFeedback) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Submit Feedback")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSubmitting || !isValidForm)
                }
            }
            .navigationTitle("Submit Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(selectedCoordinate: $selectedCoordinate)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Feedback"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("submitted") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
    }
    
    private var isValidForm: Bool {
        let hasBasicInfo = !title.isEmpty && !description.isEmpty
        
        switch feedbackType {
        case .newLocation:
            return hasBasicInfo && !locationName.isEmpty && !locationAddress.isEmpty && selectedCoordinate != nil
        case .locationUpdate:
            return hasBasicInfo && (!locationName.isEmpty || !locationAddress.isEmpty || selectedCoordinate != nil)
        default:
            return hasBasicInfo
        }
    }
    
    private func submitFeedback() {
        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int,
              let userName = UserDefaults.standard.string(forKey: "loggedInUserName") else {
            alertMessage = "Please log in to submit feedback"
            showAlert = true
            return
        }
        
        isSubmitting = true
        
        let feedback = [
            "userId": userId,
            "userName": userName,
            "type": feedbackType.rawValue.uppercased().replacingOccurrences(of: " ", with: "_"),
            "title": title,
            "description": description,
            "locationName": locationName,
            "locationAddress": locationAddress,
            "latitude": selectedCoordinate?.latitude as Any,
            "longitude": selectedCoordinate?.longitude as Any
        ] as [String : Any]
        
        NetworkManager().submitFeedback(feedback: feedback) { success, error in
            DispatchQueue.main.async {
                isSubmitting = false
                if success {
                    alertMessage = "Feedback submitted successfully"
                    showAlert = true
                } else {
                    alertMessage = "Error submitting feedback: \(error?.localizedDescription ?? "Unknown error")"
                    showAlert = true
                }
            }
        }
    }
}

struct LocationPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var pinLocation: CLLocationCoordinate2D?
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, annotationItems: pinLocation.map { [$0] } ?? []) { coordinate in
                    MapPin(coordinate: coordinate)
                }
                .gesture(
                    LongPressGesture(minimumDuration: 0.2)
                        .sequenced(before: DragGesture(minimumDistance: 0))
                        .onEnded { value in
                            switch value {
                            case .second(true, let drag):
                                if let location = drag?.location {
                                    let coordinate = convertToCoordinate(location)
                                    pinLocation = coordinate
                                }
                            default:
                                break
                            }
                        }
                )
                
                if pinLocation == nil {
                    Text("Long press to select location")
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.top, 50)
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedCoordinate = pinLocation
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(pinLocation == nil)
                }
            }
        }
    }
    
    private func convertToCoordinate(_ point: CGPoint) -> CLLocationCoordinate2D {
        let rect = UIScreen.main.bounds
        let midX = rect.width / 2
        let midY = rect.height / 2
        
        let deltaLat = region.span.latitudeDelta * (point.y - midY) / rect.height
        let deltaLon = region.span.longitudeDelta * (point.x - midX) / rect.width
        
        return CLLocationCoordinate2D(
            latitude: region.center.latitude - deltaLat,
            longitude: region.center.longitude + deltaLon
        )
    }
} 