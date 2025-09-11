package com.example.users;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_stats")
public class UserStats {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

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
}


