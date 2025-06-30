package com.example.reviews;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ReviewRepository extends JpaRepository<Review, Long> {
    List<Review> findByLocationId(Long locationId);
    List<Review> findByUserId(Long userId);
    List<Review> findByLocationIdOrderByCreatedAtDesc(Long locationId);
    boolean existsByLocationIdAndUserId(Long locationId, Long userId);
} 