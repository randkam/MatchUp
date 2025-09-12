package com.example.activities;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class ActivityService {

    @Autowired
    private ActivityRepository activityRepository;

    public void createActivityForUsers(List<Long> userIds, String type, String message) {
        if (userIds == null || userIds.isEmpty()) return;
        List<Activity> batch = new ArrayList<>();
        for (Long uid : userIds) {
            Activity a = new Activity();
            a.setUserId(uid);
            a.setType(type);
            a.setMessage(message);
            batch.add(a);
        }
        activityRepository.saveAll(batch);
    }

    public List<Activity> getRecentForUser(Long userId) {
        return activityRepository.findTop50ByUserIdOrderByCreatedAtDesc(userId);
    }
}


