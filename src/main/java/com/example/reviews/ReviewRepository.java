package com.example.reviews;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReviewRepository extends JpaRepository<Review, Long> {
    Page<Review> findByLocationId(int locationId, Pageable pageable);
    Page<Review> findByUserId(int userId, Pageable pageable);
    List<Review> findByLocationId(int locationId);
    boolean existsByLocationIdAndUserId(int locationId, int userId);
} 