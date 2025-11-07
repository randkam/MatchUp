import SwiftUI

struct CreateTournamentView: View {
    @Environment(\.dismiss) private var dismiss
    private let network = NetworkManager()

    @State private var name: String = ""
    @State private var formatSize: String = ""
    @State private var maxTeams: String = ""
    @State private var startsAt: Date = Date().addingTimeInterval(60 * 60 * 24 * 2) // default +2 days
    @State private var location: String = ""
    @State private var prizeCents: String = ""

    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    private var isAdmin: Bool {
        (UserDefaults.standard.string(forKey: "userRole") ?? "USER").uppercased() == "ADMIN"
    }

    private var formValid: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let fs = Int(formatSize), fs > 0,
              let mt = Int(maxTeams), mt > 0,
              !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let pc = Int(prizeCents), pc >= 0 else { return false }
        // startsAt must be in the future (at least 2 hours from now to avoid immediate close)
        return startsAt > Date()
    }

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Name", text: $name)
                TextField("Format size (e.g. 3 for 3v3)", text: $formatSize)
                    .keyboardType(.numberPad)
                TextField("Max teams (power of 2 preferred)", text: $maxTeams)
                    .keyboardType(.numberPad)
                DatePicker("Starts at", selection: $startsAt, displayedComponents: [.date, .hourAndMinute])
                TextField("Location", text: $location)
                TextField("Top prize (cents)", text: $prizeCents)
                    .keyboardType(.numberPad)
            }

            if let errorMessage = errorMessage {
                Section { Text(errorMessage).foregroundColor(.red) }
            }

            Section {
                Button(action: submit) {
                    HStack {
                        if isSubmitting { ProgressView().tint(.white) }
                        Text("Create Tournament")
                            .bold()
                    }
                }
                .disabled(!formValid || !isAdmin || isSubmitting)
            }
        }
        .navigationTitle("New Tournament")
        .onAppear {
            if !isAdmin { errorMessage = "Only admins can create tournaments." }
        }
    }

    private func submit() {
        guard formValid, isAdmin else { return }
        guard let fs = Int(formatSize), let mt = Int(maxTeams), let pc = Int(prizeCents) else { return }
        let userId = UserDefaults.standard.integer(forKey: "loggedInUserId")
        isSubmitting = true
        errorMessage = nil
        network.createTournament(name: name, formatSize: fs, maxTeams: mt, startsAt: startsAt, location: location, prizeCents: pc, requestingUserId: userId) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success(_):
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}


