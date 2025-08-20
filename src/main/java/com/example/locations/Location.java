package com.example.locations;

import jakarta.persistence.*;
import com.fasterxml.jackson.annotation.JsonProperty;

@Entity
@Table(name = "locations")
public class Location {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "location_id")
    private Long id;

    @JsonProperty("name")
    private String locationName;

    @JsonProperty("address")
    private String locationAddress;

    @JsonProperty("zip_code")
    private String locationZipCode;

    @JsonProperty("active_players")
    private int locationActivePlayers;
    
    @JsonProperty("is_lit_at_night")
    private Boolean isLitAtNight;
    
    @Enumerated(EnumType.STRING)
    @JsonProperty("type")
    private LocationType locationType;
    
    @JsonProperty("latitude")
    private Double locationLatitude;

    @JsonProperty("longitude")
    private Double locationLongitude;

    public Location() {
    }

    public Location(Long id, String locationName, String locationAddress, String locationZipCode,
                   int locationActivePlayers, Boolean isLitAtNight,
                   LocationType locationType, Double locationLatitude, Double locationLongitude) {
        this.id = id;
        this.locationName = locationName;
        this.locationAddress = locationAddress;
        this.locationZipCode = locationZipCode;
        this.locationActivePlayers = locationActivePlayers;
        this.isLitAtNight = isLitAtNight;
        this.locationType = locationType;
        this.locationLatitude = locationLatitude;
        this.locationLongitude = locationLongitude;
    }

    // Getters and Setters
    @JsonProperty("id")
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    @JsonProperty("name")
    public String getLocationName() {
        return locationName;
    }

    public void setLocationName(String locationName) {
        this.locationName = locationName;
    }

    @JsonProperty("address")
    public String getLocationAddress() {
        return locationAddress;
    }

    public void setLocationAddress(String locationAddress) {
        this.locationAddress = locationAddress;
    }

    @JsonProperty("zip_code")
    public String getLocationZipCode() {
        return locationZipCode;
    }

    public void setLocationZipCode(String locationZipCode) {
        this.locationZipCode = locationZipCode;
    }

    @JsonProperty("active_players")
    public int getLocationActivePlayers() {
        return locationActivePlayers;
    }

    public void setLocationActivePlayers(int locationActivePlayers) {
        this.locationActivePlayers = locationActivePlayers;
    }


    @JsonProperty("is_lit_at_night")
    public Boolean isLitAtNight() {
        return isLitAtNight;
    }

    public void setLitAtNight(Boolean litAtNight) {
        isLitAtNight = litAtNight;
    }

    @JsonProperty("type")
    public LocationType getLocationType() {
        return locationType;
    }

    public void setLocationType(LocationType locationType) {
        this.locationType = locationType;
    }

    @JsonProperty("latitude")
    public Double getLocationLatitude() {
        return locationLatitude;
    }

    public void setLocationLatitude(Double locationLatitude) {
        this.locationLatitude = locationLatitude;
    }

    @JsonProperty("longitude")
    public Double getLocationLongitude() {
        return locationLongitude;
    }

    public void setLocationLongitude(Double locationLongitude) {
        this.locationLongitude = locationLongitude;
    }
}
