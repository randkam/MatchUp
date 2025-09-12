package com.example.tournaments;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "tournament_registrations")
public class TournamentRegistration {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "tournament_id", nullable = false)
    private Long tournamentId;

    @Column(name = "team_id", nullable = false)
    private Long teamId;

    @Column(name = "status", nullable = false, length = 24)
    private String status = "REGISTERED"; // REGISTERED, CANCELLED, CHECKED_IN

    @Column(name = "seed")
    private Integer seed;

    @Column(name = "checked_in", nullable = false)
    private boolean checkedIn = false;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = createdAt;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    @JsonProperty("id")
    public Long getId() { return id; }
    @JsonProperty("tournament_id")
    public Long getTournamentId() { return tournamentId; }
    @JsonProperty("team_id")
    public Long getTeamId() { return teamId; }
    @JsonProperty("status")
    public String getStatus() { return status; }
    @JsonProperty("seed")
    public Integer getSeed() { return seed; }
    @JsonProperty("checked_in")
    public boolean isCheckedIn() { return checkedIn; }
    @JsonProperty("created_at")
    public LocalDateTime getCreatedAt() { return createdAt; }
    @JsonProperty("updated_at")
    public LocalDateTime getUpdatedAt() { return updatedAt; }

    public void setTournamentId(Long tournamentId) { this.tournamentId = tournamentId; }
    public void setTeamId(Long teamId) { this.teamId = teamId; }
    public void setStatus(String status) { this.status = status; }
    public void setSeed(Integer seed) { this.seed = seed; }
    public void setCheckedIn(boolean checkedIn) { this.checkedIn = checkedIn; }
}


