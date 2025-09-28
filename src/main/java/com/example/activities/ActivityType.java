package com.example.activities;

import jakarta.persistence.*;

@Entity
@Table(name = "activity_types")
public class ActivityType {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Short id;

    @Column(name = "code", nullable = false, unique = true, length = 64)
    private String code;

    @Column(name = "description", nullable = false, length = 255)
    private String description;

    public Short getId() { return id; }
    public String getCode() { return code; }
    public String getDescription() { return description; }

    public void setCode(String code) { this.code = code; }
    public void setDescription(String description) { this.description = description; }
}


