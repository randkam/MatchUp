package com.example.teams;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "team_members")
public class TeamMember {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "team_id", nullable = false)
    private Long teamId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "role", nullable = false, length = 16)
    private String role; // CAPTAIN or PLAYER

    @Column(name = "joined_at", nullable = false)
    private LocalDateTime joinedAt;

    @PrePersist
    protected void onJoin() { joinedAt = LocalDateTime.now(); }

    @JsonProperty("id")
    public Long getId() { return id; }
    @JsonProperty("team_id")
    public Long getTeamId() { return teamId; }
    @JsonProperty("user_id")
    public Long getUserId() { return userId; }
    @JsonProperty("role")
    public String getRole() { return role; }
    @JsonProperty("joined_at")
    public LocalDateTime getJoinedAt() { return joinedAt; }

    public void setTeamId(Long teamId) { this.teamId = teamId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public void setRole(String role) { this.role = role; }
}


