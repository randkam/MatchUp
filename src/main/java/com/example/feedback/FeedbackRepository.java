package com.example.feedback;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface FeedbackRepository extends JpaRepository<Feedback, Long> {
    List<Feedback> findByUserId(Long userId);
    List<Feedback> findByType(Feedback.FeedbackType type);
    List<Feedback> findByStatus(Feedback.FeedbackStatus status);
} 