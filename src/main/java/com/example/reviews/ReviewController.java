package com.example.reviews;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reviews")
public class ReviewController {
    private final ReviewService reviewService;

    @Autowired
    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @GetMapping("/location/{locationId}")
    public ResponseEntity<List<Review>> getLocationReviews(@PathVariable Long locationId) {
        System.out.println("Fetching reviews for location: " + locationId);
        List<Review> reviews = reviewService.getReviewsByLocation(locationId);
        System.out.println("Found " + reviews.size() + " reviews: " + reviews);
        return ResponseEntity.ok(reviews);
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<Review>> getUserReviews(@PathVariable Long userId) {
        return ResponseEntity.ok(reviewService.getReviewsByUser(userId));
    }

    @PostMapping
    public ResponseEntity<Review> addReview(@RequestBody Review review) {
        System.out.println("Adding new review: " + review);
        Review savedReview = reviewService.addReview(review);
        System.out.println("Saved review: " + savedReview);
        return ResponseEntity.ok(savedReview);
    }

    @DeleteMapping("/{reviewId}")
    public ResponseEntity<Void> deleteReview(@PathVariable Long reviewId) {
        reviewService.deleteReview(reviewId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/check/{locationId}/{userId}")
    public ResponseEntity<Boolean> hasUserReviewed(
            @PathVariable Long locationId,
            @PathVariable Long userId) {
        return ResponseEntity.ok(reviewService.hasUserReviewedLocation(locationId, userId));
    }

    @GetMapping("/average/{locationId}")
    public ResponseEntity<Double> getAverageRating(@PathVariable Long locationId) {
        return ResponseEntity.ok(reviewService.getAverageRatingForLocation(locationId));
    }
} 