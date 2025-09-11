package com.example.teams;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "teams")
public class Team {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "name", nullable = false, length = 80)
    private String name;

    // Stored as ENUM('basketball') at DB level; map as String for simplicity
    @Column(name = "sport", nullable = false, length = 32)
    private String sport;

    @Column(name = "owner_user_id", nullable = false)
    private Long ownerUserId;

    @Column(name = "logo_url")
    private String logoUrl;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    @JsonProperty("id")
    public Long getId() { return id; }
    @JsonProperty("name")
    public String getName() { return name; }
    @JsonProperty("sport")
    public String getSport() { return sport; }
    @JsonProperty("owner_user_id")
    public Long getOwnerUserId() { return ownerUserId; }
    @JsonProperty("logo_url")
    public String getLogoUrl() { return logoUrl; }
    @JsonProperty("created_at")
    public LocalDateTime getCreatedAt() { return createdAt; }

    public void setName(String name) { this.name = name; }
    public void setSport(String sport) { this.sport = sport; }
    public void setOwnerUserId(Long ownerUserId) { this.ownerUserId = ownerUserId; }
    public void setLogoUrl(String logoUrl) { this.logoUrl = logoUrl; }
}


