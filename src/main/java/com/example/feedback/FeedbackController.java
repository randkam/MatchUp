package com.example.feedback;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/feedback")
public class FeedbackController {

    @Autowired
    private FeedbackService feedbackService;

    @PostMapping
    public ResponseEntity<Feedback> submitFeedback(@RequestBody Feedback feedback) {
        return ResponseEntity.ok(feedbackService.submitFeedback(feedback));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<Feedback>> getFeedbackByUser(@PathVariable Long userId) {
        return ResponseEntity.ok(feedbackService.getFeedbackByUser(userId));
    }

    @GetMapping("/type/{type}")
    public ResponseEntity<List<Feedback>> getFeedbackByType(@PathVariable Feedback.FeedbackType type) {
        return ResponseEntity.ok(feedbackService.getFeedbackByType(type));
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<List<Feedback>> getFeedbackByStatus(@PathVariable Feedback.FeedbackStatus status) {
        return ResponseEntity.ok(feedbackService.getFeedbackByStatus(status));
    }

    @PutMapping("/{feedbackId}/status")
    public ResponseEntity<Feedback> updateFeedbackStatus(
            @PathVariable Long feedbackId,
            @RequestParam Feedback.FeedbackStatus status) {
        return ResponseEntity.ok(feedbackService.updateFeedbackStatus(feedbackId, status));
    }
} 