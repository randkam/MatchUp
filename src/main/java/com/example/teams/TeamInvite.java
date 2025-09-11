package com.example.teams;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "team_invites")
public class TeamInvite {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "team_id", nullable = false)
    private Long teamId;

    @Column(name = "invitee_user_id", nullable = false)
    private Long inviteeUserId;

    @Column(name = "status", nullable = false, length = 16)
    private String status = "PENDING";

    @Column(name = "token", nullable = false, length = 36)
    private String token;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (expiresAt == null) {
            expiresAt = createdAt.plusDays(7);
        }
        if (token == null) {
            token = UUID.randomUUID().toString();
        }
    }

    @JsonProperty("id")
    public Long getId() { return id; }
    @JsonProperty("team_id")
    public Long getTeamId() { return teamId; }
    @JsonProperty("invitee_user_id")
    public Long getInviteeUserId() { return inviteeUserId; }
    @JsonProperty("status")
    public String getStatus() { return status; }
    @JsonProperty("token")
    public String getToken() { return token; }
    @JsonProperty("expires_at")
    public LocalDateTime getExpiresAt() { return expiresAt; }
    @JsonProperty("created_at")
    public LocalDateTime getCreatedAt() { return createdAt; }

    public void setTeamId(Long teamId) { this.teamId = teamId; }
    public void setInviteeUserId(Long inviteeUserId) { this.inviteeUserId = inviteeUserId; }
    public void setStatus(String status) { this.status = status; }
    public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }
}


