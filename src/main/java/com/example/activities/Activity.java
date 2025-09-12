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

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "type", nullable = false, length = 40)
    private String type; // TEAM_REGISTERED, MEMBER_JOINED

    @Column(name = "message", nullable = false, length = 255)
    private String message;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() { this.createdAt = LocalDateTime.now(); }

    @JsonProperty("id")
    public Long getId() { return id; }
    @JsonProperty("user_id")
    public Long getUserId() { return userId; }
    @JsonProperty("type")
    public String getType() { return type; }
    @JsonProperty("message")
    public String getMessage() { return message; }
    @JsonProperty("created_at")
    public LocalDateTime getCreatedAt() { return createdAt; }

    public void setUserId(Long userId) { this.userId = userId; }
    public void setType(String type) { this.type = type; }
    public void setMessage(String message) { this.message = message; }
}


