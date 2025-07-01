package com.example.reviews;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class ReviewService {
    private final ReviewRepository reviewRepository;

    @Autowired
    public ReviewService(ReviewRepository reviewRepository) {
        this.reviewRepository = reviewRepository;
    }

    public List<Review> getReviewsByLocation(Long locationId) {
        System.out.println("ReviewService: Getting reviews for location " + locationId);
        List<Review> reviews = reviewRepository.findByLocationIdOrderByCreatedAtDesc(locationId);
        System.out.println("ReviewService: Found " + reviews.size() + " reviews");
        return reviews;
    }

    public List<Review> getReviewsByUser(Long userId) {
        return reviewRepository.findByUserId(userId);
    }

    public Review addReview(Review review) {
        // Validate rating range
        if (review.getRating() < 1.0f || review.getRating() > 5.0f) {
            throw new IllegalArgumentException("Rating must be between 1 and 5");
        }
        System.out.println("ReviewService: Saving review: " + review);
        Review savedReview = reviewRepository.save(review);
        System.out.println("ReviewService: Saved review: " + savedReview);
        return savedReview;
    }

    public void deleteReview(Long reviewId) {
        reviewRepository.deleteById(reviewId);
    }

    public boolean hasUserReviewedLocation(Long locationId, Long userId) {
        return reviewRepository.existsByLocationIdAndUserId(locationId, userId);
    }

    public double getAverageRatingForLocation(Long locationId) {
        List<Review> reviews = reviewRepository.findByLocationId(locationId);
        if (reviews.isEmpty()) {
            return 0.0;
        }
        return reviews.stream()
                .mapToDouble(Review::getRating)
                .average()
                .orElse(0.0);
    }
} 