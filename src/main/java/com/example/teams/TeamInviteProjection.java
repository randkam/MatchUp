package com.example.teams;

public interface TeamInviteProjection {
    Long getId();
    Long getTeamId();
    Long getInviteeUserId();
    String getStatus();
    String getToken();
    String getExpiresAt();
    String getCreatedAt();
    String getTeamName();
}


