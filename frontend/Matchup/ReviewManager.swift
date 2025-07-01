import Foundation

class ReviewManager {
    static let shared = ReviewManager()
    private let networkManager = NetworkManager()
    
    private init() {}
    
    func getLocationReviews(locationId: Int, completion: @escaping ([Review]?, Error?) -> Void) {
        let endpoint = APIConfig.locationReviewsEndpoint(locationId: locationId)
        networkManager.get(endpoint) { (result: Result<[Review], Error>) in
            switch result {
            case .success(let reviews):
                completion(reviews, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    func getUserReviews(userId: Int, completion: @escaping ([Review]?, Error?) -> Void) {
        let endpoint = APIConfig.userReviewsEndpoint(userId: userId)
        networkManager.get(endpoint) { (result: Result<[Review], Error>) in
            switch result {
            case .success(let reviews):
                completion(reviews, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    func addReview(locationId: Int, userId: Int, rating: Float, comment: String?, completion: @escaping (Review?, Error?) -> Void) {
        let endpoint = APIConfig.reviewsEndpoint
        
        // Create the request object
        let reviewRequest = CreateReviewRequest(
            locationId: locationId,
            userId: userId,
            rating: rating,
            comment: comment
        )
        
        // Convert the request object to dictionary
        guard let parameters = try? reviewRequest.asDictionary() else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode review request"]))
            return
        }
        
        print("Sending review parameters: \(parameters)") // Debug log
        
        networkManager.post(endpoint, parameters: parameters) { (result: Result<ReviewResponse, Error>) in
            switch result {
            case .success(let response):
                if let review = response.toReview() {
                    completion(review, nil)
                } else {
                    completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert response to review"]))
                }
            case .failure(let error):
                print("Review submission error: \(error)") // Debug log
                completion(nil, error)
            }
        }
    }
    
    func deleteReview(reviewId: Int, completion: @escaping (Bool, Error?) -> Void) {
        let endpoint = "\(APIConfig.reviewsEndpoint)/\(reviewId)"
        networkManager.delete(endpoint) { error in
            completion(error == nil, error)
        }
    }
    
    func hasUserReviewed(locationId: Int, userId: Int, completion: @escaping (Bool, Error?) -> Void) {
        let endpoint = APIConfig.checkUserReviewEndpoint(locationId: locationId, userId: userId)
        networkManager.get(endpoint) { (result: Result<Bool, Error>) in
            switch result {
            case .success(let hasReviewed):
                completion(hasReviewed, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    func getAverageRating(locationId: Int, completion: @escaping (Double?, Error?) -> Void) {
        let endpoint = APIConfig.averageRatingEndpoint(locationId: locationId)
        networkManager.get(endpoint) { (result: Result<Double, Error>) in
            switch result {
            case .success(let rating):
                completion(rating, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}

// Helper extension to convert Encodable to dictionary
extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to dictionary"])
        }
        return dictionary
    }
} 