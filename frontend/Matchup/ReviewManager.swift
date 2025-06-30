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
        let parameters: [String: Any] = [
            "location_id": locationId,
            "user_id": userId,
            "rating": rating,
            "comment": comment ?? ""
        ]
        
        networkManager.post(endpoint, parameters: parameters) { (result: Result<Review, Error>) in
            switch result {
            case .success(let review):
                completion(review, nil)
            case .failure(let error):
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