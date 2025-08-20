package com.example.reviews;

import com.example.locations.Location;
import com.example.locations.LocationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ReviewService {

    @Autowired
    private ReviewRepository reviewRepository;

    @Autowired
    private LocationRepository locationRepository;

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

    private void updateLocationReviewCount(Long locationId) {
        Location location = locationRepository.findById(locationId)
            .orElseThrow(() -> new RuntimeException("Location not found with id: " + locationId));
        // locationReviews field removed; no longer updating a denormalized count on the Location entity
        locationRepository.save(location);
    }

    @Transactional
    public Review addReview(Review review) {
        Review savedReview = reviewRepository.save(review);
        updateLocationReviewCount(review.getLocationId());
        return savedReview;
    }

    @Transactional
    public void deleteReview(int reviewId) {
        Review review = reviewRepository.findById((long) reviewId)
            .orElseThrow(() -> new RuntimeException("Review not found with id: " + reviewId));
        Long locationId = review.getLocationId();
        reviewRepository.deleteById((long) reviewId);
        updateLocationReviewCount(locationId);
    }
} 