package com.example.activities;

public class ActivityFeedItem {
    public Long id;
    public String typeCode;
    public Long teamId;
    public Long tournamentId;
    public String tournamentName;
    public Long actorUserId;
    public String actorUsername;
    public String teamName;
    public String message;
    public String createdAt;
    public String payload;

    public ActivityFeedItem(Long id, String typeCode, Long teamId, Long tournamentId, Long actorUserId, String actorUsername, String teamName, String tournamentName, String message, String createdAt, String payload) {
        this.id = id;
        this.typeCode = typeCode;
        this.teamId = teamId;
        this.tournamentId = tournamentId;
        this.actorUserId = actorUserId;
        this.actorUsername = actorUsername;
        this.teamName = teamName;
        this.tournamentName = tournamentName;
        this.message = message;
        this.createdAt = createdAt;
        this.payload = payload;
    }
}


