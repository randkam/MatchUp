package com.example.reviews;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ReviewService {

    @Autowired
    private ReviewRepository reviewRepository;

    public Page<Review> getLocationReviews(int locationId, PageRequest pageRequest) {
        return reviewRepository.findByLocationId(locationId, pageRequest);
    }

    public Page<Review> getUserReviews(int userId, PageRequest pageRequest) {
        return reviewRepository.findByUserId(userId, pageRequest);
    }

    public boolean hasUserReviewed(int locationId, int userId) {
        return reviewRepository.existsByLocationIdAndUserId(locationId, userId);
    }

    public double getAverageRating(int locationId) {
        return reviewRepository.findByLocationId(locationId)
            .stream()
            .mapToDouble(Review::getRating)
            .average()
            .orElse(0.0);
    }

    @Transactional
    public Review addReview(Review review) {
        return reviewRepository.save(review);
    }

    @Transactional
    public void deleteReview(int reviewId) {
        reviewRepository.deleteById((long) reviewId);
    }
} 