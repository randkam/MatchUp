package com.example.activities;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/activities")
public class ActivityController {

    @Autowired
    private ActivityService activityService;

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<ActivityFeedItem>> getUserActivities(@PathVariable Long userId) {
        return ResponseEntity.ok(activityService.getRecentFeedForUser(userId));
    }
}


