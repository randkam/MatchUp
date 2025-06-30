package com.example.locations;


import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;

@Entity
@Table(name ="locations")
public class Location {

    public enum LocationType {
        INDOOR,
        OUTDOOR
    }

    @Id
    @SequenceGenerator(
        name = "location_sequence",
        sequenceName = "location_sequence",
        allocationSize = 1
    )

    @GeneratedValue(
        strategy = GenerationType.SEQUENCE,
        generator = "location_sequence"
    )

    private Long locationId;
    private String locationName;
    private String locationAddress;
    private String locationZipCode;
    private int locationActivePlayers;
    private String locationReviews;
    private boolean isLitAtNight;

    @Enumerated(EnumType.STRING)
    private LocationType locationType;

    public Location() {
    }

    public Location(Long locationId, String locationName, String locationAdress, int locationActivePlayers, String locationZipCode, String locationReviews, LocationType locationType) {
        this.locationId = locationId;
        this.locationName = locationName;
        this.locationActivePlayers = locationActivePlayers;
        this.locationZipCode = locationZipCode;
        this.locationReviews = locationReviews;
        this.locationType = locationType;
    }

    public Location(String locationName, String locationAddress) {
        this.locationName = locationName;
        this.locationAddress = locationAddress;
        // this.userEmail = userEmail;
        // this.userPassword = hashPassword(userPassword);
    }

    public Long getLocationId() {
        return locationId;
    }

    public String getLocationName() {
        return locationName;
    }

    public String getLocationAddress() {
        return locationAddress;
    }

    public String getLocationZipCode() {
        return locationZipCode;
    }

    public int getLocationActivePlayers() {
        return locationActivePlayers;
    }

    public String getLocationReviews() {
        return locationReviews;
    }

    public LocationType getLocationType() {
        return locationType;
    }

    public boolean isLitAtNight() {
        return isLitAtNight;
    }

    public void setLocationId(Long locationId) {
        this.locationId = locationId;
    }

    public void setLocationName(String locationName) {
        this.locationName = locationName;
    }

    public void setLocationAddress(String locationAddress) {
        this.locationAddress = locationAddress;
    }

    public void setLocationZipCode(String locationZipCode) {
        this.locationZipCode = locationZipCode;
    }

    public void setLocationActivePlayers(int locationActivePlayers) {
        this.locationActivePlayers = locationActivePlayers;
    }

    public void setLocationReviews(String locationReviews) {
        this.locationReviews = locationReviews;
    }

    public void setLocationType(LocationType locationType) {
        this.locationType = locationType;
    }

    public void setLitAtNight(boolean litAtNight) {
        isLitAtNight = litAtNight;
    }

    @Override
    public String toString() {
        return "locations [locationId=" + locationId + ", locationName=" + locationName + ", locationAddress=" + locationAddress + ", locationType=" + locationType + "]";
    }
}
