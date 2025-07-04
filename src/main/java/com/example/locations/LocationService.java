package com.example.locations;
import java.util.List;


import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import jakarta.transaction.Transactional;


@Service
public class LocationService {
    private final LocationRepository locationRepository;
	@Autowired
	public LocationService(LocationRepository locationRepository) {
		this.locationRepository = locationRepository;
	}

	public List<Location> getLocations(){
        return locationRepository.findAll();

	}

	public Location getLocation(Long locationId) {
        return locationRepository.findById(locationId)
            .orElseThrow(() -> new IllegalStateException("Location with id " + locationId + " not found"));
    }


	// public Location getUser (String userEmail){
	// 	return userRepository.findUserByUserEmail(userEmail)
	// 	.orElseThrow(() -> new IllegalStateException("User not found"));
	// }


	public void addNewLocation( Location location){
		// Ensure isLitAtNight is explicitly set to null if not provided
		if (location.isLitAtNight() == null) {
			location.setLitAtNight(null);
		}
		locationRepository.save(location);
    }	



	public void deleteUser( Long locationId){
		locationRepository.deleteById(locationId);
	  
    }

	@Transactional
	public void updateUser(Long locationId, int locationActivePlayers) {
		Location location = locationRepository.findById(locationId)
				.orElseThrow(() -> new IllegalStateException("Location not found"));
		
		if (locationActivePlayers >= 0) {
				location.setLocationActivePlayers(locationActivePlayers);
			}
		
		

	}
}