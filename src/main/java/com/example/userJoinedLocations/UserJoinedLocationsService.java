package com.example.userJoinedLocations;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class UserJoinedLocationsService {

    @Autowired
    private UserJoinedLocationsRepository repository;

    public List<UserJoinedLocations> getLocationsByUserId(Long userId) {
        return repository.findByUserId(userId);
    }

    public UserJoinedLocations save(UserJoinedLocations userJoinedLocations) {
        return repository.save(userJoinedLocations);
    }
    
    public void removeUserLocation(Long userId, Long locationId) {
        repository.deleteByUserIdAndLocationId(userId, locationId);
    }
}