package com.example.tournaments;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "matches",
       uniqueConstraints = @UniqueConstraint(columnNames = {"tournament_id", "round_number", "match_number"}))
public class TournamentMatch {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "tournament_id", nullable = false)
    private Long tournamentId;

    @Column(name = "round_number", nullable = false)
    private Integer roundNumber;

    @Column(name = "match_number", nullable = false)
    private Integer matchNumber;

    @Column(name = "team_a_id")
    private Long teamAId;

    @Column(name = "team_b_id")
    private Long teamBId;

    @Column(name = "score_a")
    private Integer scoreA = 0;

    @Column(name = "score_b")
    private Integer scoreB = 0;

    @Column(name = "winner_team_id")
    private Long winnerTeamId;

    @Column(name = "status", nullable = false, length = 16)
    private String status = "SCHEDULED"; // SCHEDULED, IN_PROGRESS, COMPLETE

    @Column(name = "scheduled_at")
    private LocalDateTime scheduledAt; // existing column from your table

    @Column(name = "next_match_id")
    private Long nextMatchId;

    @Column(name = "next_match_slot")
    private String nextMatchSlot; // "1" or "2"

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
    @JsonProperty("round_number")
    public Integer getRoundNumber() { return roundNumber; }
    @JsonProperty("match_number")
    public Integer getMatchNumber() { return matchNumber; }
    @JsonProperty("team_a_id")
    public Long getTeamAId() { return teamAId; }
    @JsonProperty("team_b_id")
    public Long getTeamBId() { return teamBId; }
    @JsonProperty("score_a")
    public Integer getScoreA() { return scoreA; }
    @JsonProperty("score_b")
    public Integer getScoreB() { return scoreB; }
    @JsonProperty("winner_team_id")
    public Long getWinnerTeamId() { return winnerTeamId; }
    @JsonProperty("status")
    public String getStatus() { return status; }
    @JsonProperty("scheduled_at")
    public LocalDateTime getScheduledAt() { return scheduledAt; }
    @JsonProperty("next_match_id")
    public Long getNextMatchId() { return nextMatchId; }
    @JsonProperty("next_match_slot")
    public String getNextMatchSlot() { return nextMatchSlot; }
    @JsonProperty("created_at")
    public LocalDateTime getCreatedAt() { return createdAt; }
    @JsonProperty("updated_at")
    public LocalDateTime getUpdatedAt() { return updatedAt; }

    public void setTournamentId(Long tournamentId) { this.tournamentId = tournamentId; }
    public void setRoundNumber(Integer roundNumber) { this.roundNumber = roundNumber; }
    public void setMatchNumber(Integer matchNumber) { this.matchNumber = matchNumber; }
    public void setTeamAId(Long teamAId) { this.teamAId = teamAId; }
    public void setTeamBId(Long teamBId) { this.teamBId = teamBId; }
    public void setScoreA(Integer scoreA) { this.scoreA = scoreA; }
    public void setScoreB(Integer scoreB) { this.scoreB = scoreB; }
    public void setWinnerTeamId(Long winnerTeamId) { this.winnerTeamId = winnerTeamId; }
    public void setStatus(String status) { this.status = status; }
    public void setScheduledAt(LocalDateTime scheduledAt) { this.scheduledAt = scheduledAt; }
    public void setNextMatchId(Long nextMatchId) { this.nextMatchId = nextMatchId; }
    public void setNextMatchSlot(String nextMatchSlot) { this.nextMatchSlot = nextMatchSlot; }
}


