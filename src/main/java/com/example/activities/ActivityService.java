package com.example.activities;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class ActivityService {

    @Autowired
    private ActivityRepository activityRepository;
    @Autowired
    private ActivityTypeRepository activityTypeRepository;

    private Short getTypeId(String code) {
        return activityTypeRepository.findByCode(code)
                .map(ActivityType::getId)
                .orElseThrow(() -> new IllegalStateException("Unknown activity type code: " + code));
    }

    public void createTeamEvent(String typeCode, Long teamId, Long actorUserId, String teamNameSnapshot, Long tournamentId, String dedupeKey) {
        if (dedupeKey != null && activityRepository.existsByDedupeKey(dedupeKey)) return;
        Activity a = new Activity();
        a.setTypeId(getTypeId(typeCode));
        a.setTeamId(teamId);
        a.setActorUserId(actorUserId);
        a.setTeamNameSnapshot(teamNameSnapshot);
        a.setTournamentId(tournamentId);
        a.setDedupeKey(dedupeKey);
        // Store lightweight payload snapshot so old activities still show names after deletions
        StringBuilder payload = new StringBuilder("{");
        boolean first = true;
        if (teamId != null) {
            payload.append("\"team_id\":").append(teamId);
            first = false;
        }
        if (teamNameSnapshot != null) {
            if (!first) payload.append(",");
            String safeName = teamNameSnapshot.replace("\\\"", "\\\\\"");
            payload.append("\"team_name\":\"").append(safeName).append("\"");
            first = false;
        }
        if (tournamentId != null) {
            if (!first) payload.append(",");
            payload.append("\"tournament_id\":").append(tournamentId);
        }
        payload.append("}");
        a.setPayload(payload.toString());
        activityRepository.save(a);
    }

    public List<ActivityFeedItem> getRecentFeedForUser(Long userId) {
        List<Object[]> rows = activityRepository.findFeedForUser(userId);
        List<ActivityFeedItem> out = new ArrayList<>();
        for (Object[] r : rows) {
            Long id = ((Number) r[0]).longValue();
            String typeCode = (String) r[1];
            Long teamId = r[2] == null ? null : ((Number) r[2]).longValue();
            Long tournamentId = r[3] == null ? null : ((Number) r[3]).longValue();
            Long actorUserId = r[4] == null ? null : ((Number) r[4]).longValue();
            String actorUsername = (String) r[5];
            String teamName = (String) r[6];
            String tournamentName = (String) r[7];
            String message = (String) r[8];
            String createdAt = (String) r[9];
            out.add(new ActivityFeedItem(id, typeCode, teamId, tournamentId, actorUserId, actorUsername, teamName, tournamentName, message, createdAt));
        }
        return out;
    }

    public void createTeamDeletedEvent(Long teamId, Long actorUserId, String teamNameSnapshot) {
        Activity a = new Activity();
        a.setTypeId(getTypeId("TEAM_DELETED"));
        a.setTeamId(null); // will be nulled after delete
        a.setActorUserId(actorUserId);
        a.setTeamNameSnapshot(teamNameSnapshot);
        String safeName = teamNameSnapshot == null ? null : teamNameSnapshot.replace("\\\"", "\\\\\"");
        a.setPayload(safeName == null ?
                ("{\"team_id\":" + teamId + "}") :
                ("{\"team_id\":" + teamId + ",\"team_name\":\"" + safeName + "\"}"));
        activityRepository.save(a);
    }
}


