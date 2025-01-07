package com.example.userJoinedLocations;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/user-locations")
public class UserJoinedLocationsController {

    @Autowired
    private UserJoinedLocationsService service;

    @GetMapping("/user/{userId}")
    public List<UserJoinedLocations> getLocationsByUserId(@PathVariable Long userId) {
        return service.getLocationsByUserId(userId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED) // Explicitly set the status to 201 Created
    public UserJoinedLocations addUserLocation(@RequestBody UserJoinedLocations userJoinedLocations) {
        return service.save(userJoinedLocations);
    }


    @DeleteMapping("/user/{userId}/location/{locationId}")
    public void removeUserLocation(@PathVariable Long userId, @PathVariable Long locationId) {
        service.removeUserLocation(userId, locationId);
    }
}

