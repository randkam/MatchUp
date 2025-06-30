import SwiftUI

struct ReviewsView: View {
    let locationId: Int
    @State private var reviews: [Review] = []
    @State private var averageRating: Double = 0.0
    @State private var userRating: Double = 3.0
    @State private var userComment: String = ""
    @State private var showingAddReview = false
    @State private var hasUserReviewed = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            ModernColorScheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Average Rating Header
                VStack(spacing: 8) {
                    Text("Rating")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f", averageRating))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 24))
                    }
                    
                    Text("\(reviews.count) reviews")
                        .foregroundColor(.gray)
                }
                .padding()
                
                // Add Review Button
                if !hasUserReviewed {
                    Button(action: {
                        showingAddReview = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Review")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }
                
                // Reviews List
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if reviews.isEmpty {
                    Text("No reviews yet")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(reviews) { review in
                                ReviewCard(review: review)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddReview) {
            AddReviewView(locationId: locationId) { newReview in
                if let review = newReview {
                    reviews.insert(review, at: 0)
                    hasUserReviewed = true
                    loadAverageRating()
                }
            }
        }
        .onAppear {
            loadReviews()
            loadAverageRating()
            checkUserReview()
        }
    }
    
    private func loadReviews() {
        ReviewManager.shared.getLocationReviews(locationId: locationId) { reviews, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                } else if let reviews = reviews {
                    self.reviews = reviews
                }
            }
        }
    }
    
    private func loadAverageRating() {
        ReviewManager.shared.getAverageRating(locationId: locationId) { rating, error in
            DispatchQueue.main.async {
                if let rating = rating {
                    self.averageRating = rating
                }
            }
        }
    }
    
    private func checkUserReview() {
        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int else { return }
        
        ReviewManager.shared.hasUserReviewed(locationId: locationId, userId: userId) { hasReviewed, error in
            DispatchQueue.main.async {
                self.hasUserReviewed = hasReviewed
            }
        }
    }
}

struct ReviewCard: View {
    let review: Review
    @State private var username: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(username)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", review.rating))
                        .foregroundColor(.white)
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            if let comment = review.comment, !comment.isEmpty {
                Text(comment)
                    .foregroundColor(.white)
                    .padding(.top, 4)
            }
            
            Text(formatDate(review.createdAt))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .onAppear {
            loadUsername()
        }
    }
    
    private func loadUsername() {
        NetworkManager().getUser(userId: review.userId) { user in
            if let user = user {
                DispatchQueue.main.async {
                    self.username = user.username
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct AddReviewView: View {
    let locationId: Int
    let onComplete: (Review?) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var rating: Double = 3.0
    @State private var comment: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                ModernColorScheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Rate your experience")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= Int(rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.system(size: 32))
                                .onTapGesture {
                                    rating = Double(index)
                                }
                        }
                    }
                    
                    TextEditor(text: $comment)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    Button(action: submitReview) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Submit Review")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(isSubmitting)
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func submitReview() {
        guard let userId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int else {
            errorMessage = "Please log in to submit a review"
            return
        }
        
        isSubmitting = true
        ReviewManager.shared.addReview(
            locationId: locationId,
            userId: userId,
            rating: Float(rating),
            comment: comment.isEmpty ? nil : comment
        ) { review, error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    onComplete(review)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
} 