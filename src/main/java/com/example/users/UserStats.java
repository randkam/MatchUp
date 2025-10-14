package com.example.users;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_stats")
@IdClass(UserStatsKey.class)
public class UserStats {
    @Id
    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Id
    @Column(name = "sport", nullable = false, length = 32)
    private String sport;

    @Column(name = "match_wins", nullable = false)
    private Integer matchWins;

    @Column(name = "match_losses", nullable = false)
    private Integer matchLosses;

    @Column(name = "titles", nullable = false)
    private Integer titles;

    @Column(name = "last_updated")
    private LocalDateTime lastUpdated;

    @JsonProperty("user_id")
    public Long getUserId() { return userId; }
    @JsonProperty("sport")
    public String getSport() { return sport; }
    @JsonProperty("match_wins")
    public Integer getMatchWins() { return matchWins; }
    @JsonProperty("match_losses")
    public Integer getMatchLosses() { return matchLosses; }
    @JsonProperty("titles")
    public Integer getTitles() { return titles; }
    @JsonProperty("last_updated")
    public LocalDateTime getLastUpdated() { return lastUpdated; }

    public void setUserId(Long userId) { this.userId = userId; }
    public void setSport(String sport) { this.sport = sport; }
    public void setMatchWins(Integer matchWins) { this.matchWins = matchWins; }
    public void setMatchLosses(Integer matchLosses) { this.matchLosses = matchLosses; }
    public void setTitles(Integer titles) { this.titles = titles; }
    public void setLastUpdated(LocalDateTime lastUpdated) { this.lastUpdated = lastUpdated; }

    public void incrementWin() { if (matchWins == null) matchWins = 0; matchWins += 1; this.lastUpdated = LocalDateTime.now(); }
    public void incrementLoss() { if (matchLosses == null) matchLosses = 0; matchLosses += 1; this.lastUpdated = LocalDateTime.now(); }
    public void incrementTitle() { if (titles == null) titles = 0; titles += 1; this.lastUpdated = LocalDateTime.now(); }
}


