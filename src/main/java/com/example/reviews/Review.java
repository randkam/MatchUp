package com.example.reviews;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import com.fasterxml.jackson.annotation.JsonProperty;

@Entity
@Table(name = "reviews")
public class Review {
    @Id
    @SequenceGenerator(
        name = "review_sequence",
        sequenceName = "review_sequence",
        allocationSize = 1
    )
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "review_sequence")
    private Long id;
    
    @JsonProperty("location_id")
    private Long locationId;
    
    @JsonProperty("user_id")
    private Long userId;
    
    private Float rating;
    private String comment;
    
    @JsonProperty("created_at")
    private LocalDateTime createdAt;

    // Default constructor
    public Review() {
        this.createdAt = LocalDateTime.now();
    }

    // Constructor with fields
    public Review(Long locationId, Long userId, Float rating, String comment) {
        this.locationId = locationId;
        this.userId = userId;
        this.rating = rating;
        this.comment = comment;
        this.createdAt = LocalDateTime.now();
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getLocationId() {
        return locationId;
    }

    public void setLocationId(Long locationId) {
        this.locationId = locationId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public Float getRating() {
        return rating;
    }

    public void setRating(Float rating) {
        this.rating = rating;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
} 