package com.example.teams;

public interface TeamMemberProjection {
    Long getId();
    Long getTeamId();
    Long getUserId();
    String getRole();
    String getJoinedAt();
    String getUsername();
}


