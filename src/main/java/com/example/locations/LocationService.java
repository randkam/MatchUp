package com.example.locations;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

@Service
public class LocationService {

    @Autowired
    private LocationRepository locationRepository;

    public Page<Location> getAllLocations(PageRequest pageRequest, String search, Boolean isIndoor, Boolean isLit) {
        // If no filters are applied, return all locations with pagination
        if (search == null && isIndoor == null && isLit == null) {
            return locationRepository.findAll(pageRequest);
        }

        // Apply filters based on provided parameters
        if (search != null) {
            return locationRepository.findByLocationNameContainingIgnoreCaseOrLocationAddressContainingIgnoreCase(
                search, search, pageRequest);
        }

        if (isIndoor != null && isLit != null) {
            return locationRepository.findByLocationTypeAndIsLitAtNight(
                isIndoor ? LocationType.INDOOR : LocationType.OUTDOOR, isLit, pageRequest);
        }

        if (isIndoor != null) {
            return locationRepository.findByLocationType(
                isIndoor ? LocationType.INDOOR : LocationType.OUTDOOR, pageRequest);
        }

        if (isLit != null) {
            return locationRepository.findByIsLitAtNight(isLit, pageRequest);
        }

        return locationRepository.findAll(pageRequest);
    }

    public Location getLocationById(Long id) {
        return locationRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Location not found with id: " + id));
    }
}