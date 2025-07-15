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
    @State private var currentPage = 0
    @State private var hasMorePages = true
    @State private var isRefreshing = false
    
    private let networkManager = NetworkManager()
    private let pageSize = 20
    
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
                if isLoading && reviews.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .onAppear {
                            print("Showing loading state")
                        }
                } else if !isLoading && reviews.isEmpty {
                    Text("No reviews yet")
                        .foregroundColor(.gray)
                        .padding()
                        .onAppear {
                            print("Showing no reviews state")
                        }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(reviews) { review in
                                ReviewCard(review: review)
                                    .onAppear {
                                        loadMoreIfNeeded(currentItem: review)
                                    }
                            }
                            .onAppear {
                                print("Showing \(reviews.count) reviews")
                            }
                            
                            if isLoading {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await refresh()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddReview) {
            AddReviewView(locationId: locationId) { newReview in
                if let review = newReview {
                    loadReviews(refresh: true)
                    loadAverageRating()
                    hasUserReviewed = true
                }
            }
        }
        .onAppear {
            loadReviews(refresh: true)
            loadAverageRating()
            checkUserReview()
        }
    }
    
    private func loadReviews(refresh: Bool = false) {
        print("Loading reviews for locationId: \(locationId)")
        isLoading = true
        
        ReviewManager.shared.getLocationReviews(locationId: locationId) { reviews, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let reviews = reviews {
                    print("Successfully loaded \(reviews.count) reviews")
                    self.reviews = reviews
                } else if let error = error {
                    print("Failed to load reviews: \(error)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadMoreIfNeeded(currentItem item: Review) {
        guard !isLoading else { return }
        
        let thresholdIndex = reviews.index(reviews.endIndex, offsetBy: -5)
        if reviews.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            loadReviews()
        }
    }
    
    private func loadAverageRating() {
        ReviewManager.shared.getAverageRating(locationId: locationId) { rating, error in
            if let rating = rating {
                DispatchQueue.main.async {
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
    
    private func refresh() async {
        isRefreshing = true
        loadReviews(refresh: true)
        loadAverageRating()
        checkUserReview()
        isRefreshing = false
    }
}

struct ReviewCard: View {
    let review: Review
    @State private var username: String = ""
    @State private var isLoadingUsername = true
    @State private var loadingError = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {  // Increased spacing
            HStack {
                if isLoadingUsername {
                    Text("Loading...")
                        .font(.headline)
                        .foregroundColor(.gray)
                } else {
                    Text(username.isEmpty ? "Anonymous" : username)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", review.rating))
                        .foregroundColor(.white)
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            if let comment = review.comment {
                Text(comment)
                    .foregroundColor(.white)
                    .padding(8)  // Added padding
                    .background(Color.gray.opacity(0.2))  // Added background
                    .cornerRadius(8)  // Added corner radius
                    .fixedSize(horizontal: false, vertical: true)
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
        isLoadingUsername = true
        loadingError = false
        
        NetworkManager().getUser(userId: review.userId) { result in
            DispatchQueue.main.async {
                isLoadingUsername = false
                switch result {
                case .success(let user):
                    self.username = user.userName
                case .failure(let error):
                    print("Error loading username: \(error)")
                    loadingError = true
                    self.username = "Anonymous"
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
