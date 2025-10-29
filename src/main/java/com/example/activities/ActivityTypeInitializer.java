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
            // Tournament lifecycle & match results
            upsert(repo, "TOURNAMENT_BRACKET_AVAILABLE", "tournament bracket is available");
            upsert(repo, "TOURNAMENT_STARTS_SOON", "tournament starts in 12 hours");
            upsert(repo, "MATCH_RESULT_WIN", "won a match");
            upsert(repo, "MATCH_RESULT_LOSS", "lost a match");
            upsert(repo, "TOURNAMENT_COMPLETED", "tournament is complete");
            upsert(repo, "TOURNAMENT_WINNER", "won the tournament");
        };
    }

    private void upsert(ActivityTypeRepository repo, String code, String description) {
        ActivityType at = repo.findByCode(code).orElseGet(ActivityType::new);
        at.setCode(code);
        at.setDescription(description);
        repo.save(at);
    }
}


