package com.example.locations;

import jakarta.persistence.*;
import com.fasterxml.jackson.annotation.JsonProperty;

@Entity
@Table(name = "locations")
public class Location {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long locationId;
    private String locationName;
    private String locationAddress;
    private String locationZipCode;
    private int locationActivePlayers;
    private String locationReviews;
    
    @JsonProperty("is_lit_at_night")
    private Boolean isLitAtNight;
    
    @Enumerated(EnumType.STRING)
    private LocationType locationType;
    
    private Double locationLatitude;
    private Double locationLongitude;

    public Location() {
    }

    public Location(Long locationId, String locationName, String locationAddress, String locationZipCode,
                   int locationActivePlayers, String locationReviews, Boolean isLitAtNight,
                   LocationType locationType, Double locationLatitude, Double locationLongitude) {
        this.locationId = locationId;
        this.locationName = locationName;
        this.locationAddress = locationAddress;
        this.locationZipCode = locationZipCode;
        this.locationActivePlayers = locationActivePlayers;
        this.locationReviews = locationReviews;
        this.isLitAtNight = isLitAtNight;
        this.locationType = locationType;
        this.locationLatitude = locationLatitude;
        this.locationLongitude = locationLongitude;
    }

    // Getters and Setters
    public Long getLocationId() {
        return locationId;
    }

    public void setLocationId(Long locationId) {
        this.locationId = locationId;
    }

    public String getLocationName() {
        return locationName;
    }

    public void setLocationName(String locationName) {
        this.locationName = locationName;
    }

    public String getLocationAddress() {
        return locationAddress;
    }

    public void setLocationAddress(String locationAddress) {
        this.locationAddress = locationAddress;
    }

    public String getLocationZipCode() {
        return locationZipCode;
    }

    public void setLocationZipCode(String locationZipCode) {
        this.locationZipCode = locationZipCode;
    }

    public int getLocationActivePlayers() {
        return locationActivePlayers;
    }

    public void setLocationActivePlayers(int locationActivePlayers) {
        this.locationActivePlayers = locationActivePlayers;
    }

    public String getLocationReviews() {
        return locationReviews;
    }

    public void setLocationReviews(String locationReviews) {
        this.locationReviews = locationReviews;
    }

    public Boolean isLitAtNight() {
        return isLitAtNight;
    }

    public void setLitAtNight(Boolean litAtNight) {
        isLitAtNight = litAtNight;
    }

    public LocationType getLocationType() {
        return locationType;
    }

    public void setLocationType(LocationType locationType) {
        this.locationType = locationType;
    }

    public Double getLocationLatitude() {
        return locationLatitude;
    }

    public void setLocationLatitude(Double locationLatitude) {
        this.locationLatitude = locationLatitude;
    }

    public Double getLocationLongitude() {
        return locationLongitude;
    }

    public void setLocationLongitude(Double locationLongitude) {
        this.locationLongitude = locationLongitude;
    }
}
