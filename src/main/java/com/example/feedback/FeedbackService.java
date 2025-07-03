package com.example.feedback;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class FeedbackService {
    
    @Autowired
    private FeedbackRepository feedbackRepository;

    public Feedback submitFeedback(Feedback feedback) {
        return feedbackRepository.save(feedback);
    }

    public List<Feedback> getAllFeedback() {
        return feedbackRepository.findAll();
    }

    public List<Feedback> getFeedbackByUser(Long userId) {
        return feedbackRepository.findByUserId(userId);
    }

    public List<Feedback> getFeedbackByType(Feedback.FeedbackType type) {
        return feedbackRepository.findByType(type);
    }

    public List<Feedback> getFeedbackByStatus(Feedback.FeedbackStatus status) {
        return feedbackRepository.findByStatus(status);
    }

    public Feedback updateFeedbackStatus(Long feedbackId, Feedback.FeedbackStatus status) {
        Feedback feedback = feedbackRepository.findById(feedbackId)
            .orElseThrow(() -> new RuntimeException("Feedback not found"));
        feedback.setStatus(status);
        return feedbackRepository.save(feedback);
    }
} 