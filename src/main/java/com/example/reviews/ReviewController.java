package com.example.reviews;

import com.example.config.PaginationConfig;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/reviews")
public class ReviewController {

    @Autowired
    private ReviewService reviewService;

    @GetMapping("/location/{locationId}")
    public ResponseEntity<Page<Review>> getLocationReviews(
            @PathVariable int locationId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String direction) {
        return ResponseEntity.ok(reviewService.getLocationReviews(
            locationId, PaginationConfig.createPageRequest(page, size, sortBy, direction)));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<Page<Review>> getUserReviews(
            @PathVariable int userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String direction) {
        return ResponseEntity.ok(reviewService.getUserReviews(
            userId, PaginationConfig.createPageRequest(page, size, sortBy, direction)));
    }

    @GetMapping("/check/{locationId}/{userId}")
    public ResponseEntity<Boolean> hasUserReviewed(
            @PathVariable int locationId,
            @PathVariable int userId) {
        return ResponseEntity.ok(reviewService.hasUserReviewed(locationId, userId));
    }

    @GetMapping("/average/{locationId}")
    public ResponseEntity<Double> getAverageRating(@PathVariable int locationId) {
        return ResponseEntity.ok(reviewService.getAverageRating(locationId));
    }

    @PostMapping
    public ResponseEntity<Review> addReview(@RequestBody Review review) {
        return ResponseEntity.ok(reviewService.addReview(review));
    }

    @DeleteMapping("/{reviewId}")
    public ResponseEntity<Void> deleteReview(@PathVariable int reviewId) {
        reviewService.deleteReview(reviewId);
        return ResponseEntity.ok().build();
    }
} 