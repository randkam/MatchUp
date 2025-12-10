package com.example.activities;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "activities")
public class Activity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    // New schema
    @Column(name = "type_id", nullable = false)
    private Short typeId;

    @Column(name = "team_id")
    private Long teamId;

    @Column(name = "tournament_id")
    private Long tournamentId;

    @Column(name = "actor_user_id")
    private Long actorUserId;

    @Column(name = "team_name_snapshot")
    private String teamNameSnapshot;

    @Column(name = "payload", columnDefinition = "json")
    private String payload;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "dedupe_key", unique = true)
    private String dedupeKey;

    @PrePersist
    protected void onCreate() { this.createdAt = java.time.LocalDateTime.now(java.time.Clock.systemUTC()); }

    @JsonProperty("id")
    public Long getId() { return id; }
    @JsonProperty("type_id")
    public Short getTypeId() { return typeId; }
    @JsonProperty("team_id")
    public Long getTeamId() { return teamId; }
    @JsonProperty("tournament_id")
    public Long getTournamentId() { return tournamentId; }
    @JsonProperty("actor_user_id")
    public Long getActorUserId() { return actorUserId; }
    @JsonProperty("team_name_snapshot")
    public String getTeamNameSnapshot() { return teamNameSnapshot; }
    @JsonProperty("payload")
    public String getPayload() { return payload; }
    @JsonProperty("created_at")
    public LocalDateTime getCreatedAt() { return createdAt; }
    public String getDedupeKey() { return dedupeKey; }

    public void setTypeId(Short typeId) { this.typeId = typeId; }
    public void setTeamId(Long teamId) { this.teamId = teamId; }
    public void setTournamentId(Long tournamentId) { this.tournamentId = tournamentId; }
    public void setActorUserId(Long actorUserId) { this.actorUserId = actorUserId; }
    public void setTeamNameSnapshot(String teamNameSnapshot) { this.teamNameSnapshot = teamNameSnapshot; }
    public void setPayload(String payload) { this.payload = payload; }
    public void setDedupeKey(String dedupeKey) { this.dedupeKey = dedupeKey; }
}


