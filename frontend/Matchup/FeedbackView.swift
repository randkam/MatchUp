import SwiftUI

struct FeedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var feedbackType: FeedbackType = .generalFeedback
    @State private var title = ""
    @State private var description = ""
    @State private var locationName = ""
    @State private var locationAddress = ""
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
            return hasBasicInfo && !locationName.isEmpty && !locationAddress.isEmpty
        case .locationUpdate:
            return hasBasicInfo && (!locationName.isEmpty || !locationAddress.isEmpty)
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
            "locationAddress": locationAddress
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