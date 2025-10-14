package com.example.tournaments;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "tournaments")
public class Tournament {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "name", nullable = false, length = 120)
    private String name;

    @Column(name = "format_size", nullable = false)
    private Integer formatSize;

    @Column(name = "max_teams", nullable = false)
    private Integer maxTeams;

    // @Column(name = "entry_fee_cents")
    // private Integer entryFeeCents;

    // @Column(name = "deposit_hold_cents")
    // private Integer depositHoldCents;

    // @Column(name = "currency", nullable = false, length = 3)
    // private String currency = "CAD";

    @Column(name = "prize_cents")
    private Integer prizeCents;

    @Column(name = "signup_deadline", nullable = false)
    private LocalDateTime signupDeadline;

    @Column(name = "starts_at", nullable = false)
    private LocalDateTime startsAt;

    @Column(name = "ends_at", nullable = true)
    private LocalDateTime endsAt;

    @Column(name = "location", nullable = true, length = 255)
    private String location;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private TournamentStatus status = TournamentStatus.DRAFT;

    @Column(name = "created_by", nullable = false)
    private Long createdBy;

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

    // Getters used for JSON mapping
    @JsonProperty("id")
    public Long getId() { return id; }

    @JsonProperty("name")
    public String getName() { return name; }

    @JsonProperty("format_size")
    public Integer getFormatSize() { return formatSize; }

    @JsonProperty("max_teams")
    public Integer getMaxTeams() { return maxTeams; }

    // @JsonProperty("entry_fee_cents")
    // public Integer getEntryFeeCents() { return entryFeeCents; }

    // @JsonProperty("deposit_hold_cents")
    // public Integer getDepositHoldCents() { return depositHoldCents; }

    // @JsonProperty("currency")
    // public String getCurrency() { return currency; }

    @JsonProperty("signup_deadline")
    public LocalDateTime getSignupDeadline() { return signupDeadline; }

    @JsonProperty("starts_at")
    public LocalDateTime getStartsAt() { return startsAt; }

    @JsonProperty("ends_at")
    public LocalDateTime getEndsAt() { return endsAt; }

    @JsonProperty("location")
    public String getLocation() { return location; }

    @JsonProperty("status")
    public TournamentStatus getStatus() { return status; }

    @JsonProperty("prize_cents")
    public Integer getPrizeCents() { return prizeCents; }

    @JsonProperty("created_by")
    public Long getCreatedBy() { return createdBy; }

    // Setters
    public void setName(String name) { this.name = name; }
    public void setFormatSize(Integer formatSize) { this.formatSize = formatSize; }
    public void setMaxTeams(Integer maxTeams) { this.maxTeams = maxTeams; }
    // public void setEntryFeeCents(Integer entryFeeCents) { this.entryFeeCents = entryFeeCents; }
    // public void setDepositHoldCents(Integer depositHoldCents) { this.depositHoldCents = depositHoldCents; }
    // public void setCurrency(String currency) { this.currency = currency; }
    public void setSignupDeadline(LocalDateTime signupDeadline) { this.signupDeadline = signupDeadline; }
    public void setStartsAt(LocalDateTime startsAt) { this.startsAt = startsAt; }
    public void setEndsAt(LocalDateTime endsAt) { this.endsAt = endsAt; }
    public void setLocation(String location) { this.location = location; }
    public void setStatus(TournamentStatus status) { this.status = status; }
    public void setCreatedBy(Long createdBy) { this.createdBy = createdBy; }
    public void setPrizeCents(Integer prizeCents) { this.prizeCents = prizeCents; }
}

