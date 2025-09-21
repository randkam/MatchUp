package com.example.activities;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ActivityTypeInitializer {

    @Bean
    CommandLineRunner seedActivityTypes(ActivityTypeRepository repo) {
        return args -> {
            upsert(repo, "TEAM_REGISTERED_TOURNAMENT", "registered for a tournament");
            upsert(repo, "TEAM_MEMBER_ADDED", "joined the team");
            upsert(repo, "TEAM_DELETED", "team was deleted");
            upsert(repo, "TEAM_MEMBER_LEFT", "left the team");
            upsert(repo, "TEAM_INVITE_RECEIVED", "invited you to a team");
        };
    }

    private void upsert(ActivityTypeRepository repo, String code, String description) {
        ActivityType at = repo.findByCode(code).orElseGet(ActivityType::new);
        at.setCode(code);
        at.setDescription(description);
        repo.save(at);
    }
}


