import SwiftUI

struct FeedbackHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var feedbackHistory: [FeedbackItem] = []
    @State private var isLoading = true
    @State private var error: String?
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else if feedbackHistory.isEmpty {
                Text("No feedback history")
                    .foregroundColor(ModernColorScheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(feedbackHistory) { feedback in
                    FeedbackHistoryRow(feedback: feedback)
                }
            }
        }
        .navigationTitle("Feedback History")
        .onAppear(perform: loadFeedbackHistory)
        .refreshable {
            await loadFeedbackHistoryAsync()
        }
    }
    
    private func loadFeedbackHistory() {
        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int else {
            error = "Please log in to view feedback history"
            isLoading = false
            return
        }
        
        NetworkManager().getFeedbackHistory(userId: userId) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let feedback):
                    self.feedbackHistory = feedback
                case .failure(let error):
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    private func loadFeedbackHistoryAsync() async {
        isLoading = true
        loadFeedbackHistory()
    }
}

struct FeedbackHistoryRow: View {
    let feedback: FeedbackItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(feedback.title)
                    .font(.headline)
                Spacer()
                StatusBadge(status: feedback.status)
            }
            
            Text(feedback.type.rawValue)
                .font(.subheadline)
                .foregroundColor(ModernColorScheme.textSecondary)
            
            Text(feedback.description)
                .font(.body)
                .foregroundColor(ModernColorScheme.text)
                .lineLimit(2)
            
            Text(feedback.formattedDate)
                .font(.caption)
                .foregroundColor(ModernColorScheme.textSecondary)
        }
        .padding(.vertical, 8)
    }
}

struct StatusBadge: View {
    let status: FeedbackStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(12)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending:
            return .orange
        case .inReview:
            return .blue
        case .approved:
            return .green
        case .rejected:
            return .red
        case .resolved:
            return .purple
        }
    }
} 