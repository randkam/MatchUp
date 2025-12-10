import SwiftUI

struct AttendanceView: View {
    let tournament: Tournament
    @State private var rows: [TournamentAttendanceRow] = []
    @State private var isLoading = false
    @State private var isApplying = false
    @State private var errorMessage: String?
    
    private let network = NetworkManager()
    
    private var attendanceDeadline: Date {
        Calendar.current.date(byAdding: .minute, value: -30, to: tournament.startsAt) ?? tournament.startsAt
    }
    
    private var requestingUserId: Int {
        UserDefaults.standard.integer(forKey: "loggedInUserId")
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Attendance cutoff")
                        .font(.headline)
                    Text(deadlineString())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Teams must check in at the front desk by this time. Admins may still update attendance after the cutoff, but players see this as a strict requirement.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }.padding(.vertical, 6)
            }
            
            Section(header: Text("Teams")) {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else if rows.isEmpty {
                    Text("No registered teams")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(rows.indices, id: \.self) { idx in
                        HStack {
                            Text(rows[idx].teamName)
                            Spacer()
                            Toggle("Checked In", isOn: Binding(
                                get: { rows[idx].checkedIn },
                                set: { newVal in setAttendance(idx: idx, value: newVal) }
                            ))
                            .labelsHidden()
                        }
                    }
                }
            }
            
            Section {
                Button(action: applyAttendance) {
                    if isApplying { ProgressView() } else { Text("Apply Attendance to Bracket") }
                }
                .disabled(isApplying)
            }
        }
        .navigationTitle("Attendance")
        .onAppear(perform: load)
        .alert(item: Binding(
            get: { errorMessage.map { ErrorWrapper(message: $0) } },
            set: { _ in errorMessage = nil }
        )) { wrapper in
            Alert(title: Text("Error"), message: Text(wrapper.message), dismissButton: .default(Text("OK")))
        }
    }
    
    private func load() {
        isLoading = true
        network.getAttendanceList(tournamentId: tournament.id) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let list):
                    self.rows = list
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                }
            }
        }
    }
    
    private func setAttendance(idx: Int, value: Bool) {
        let teamId = rows[idx].teamId
        rows[idx].checkedIn = value
        network.setAttendance(tournamentId: tournament.id, teamId: teamId, checkedIn: value, requestingUserId: requestingUserId) { err in
            DispatchQueue.main.async {
                if let err = err {
                    self.errorMessage = err.localizedDescription
                    // revert on failure
                    self.rows[idx].checkedIn.toggle()
                }
            }
        }
    }
    
    private func applyAttendance() {
        isApplying = true
        network.enforceAttendance(tournamentId: tournament.id, requestingUserId: requestingUserId) { result in
            DispatchQueue.main.async {
                isApplying = false
                if case .failure(let err) = result {
                    self.errorMessage = err.localizedDescription
                }
            }
        }
    }
    
    private func deadlineString() -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: attendanceDeadline)
    }
    
    private struct ErrorWrapper: Identifiable {
        let id = UUID()
        let message: String
    }
}


