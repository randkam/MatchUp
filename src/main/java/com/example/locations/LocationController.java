package com.example.locations;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;


@RestController
@RequestMapping(path = "api/v1/locations")
public class LocationController {
    private final LocationService locationService;
    
    
    @Autowired
    public LocationController(LocationService locationService) {
        this.locationService = locationService;
    }

    @GetMapping
	public List<Location> getLocations(){
       return locationService.getLocations();

	}

    // @GetMapping(path = "{address}")
    // public Location getUser(@PathVariable("address") String userEmail) {
    // return userService.getUser(userEmail);
    // }

    @PostMapping
    public void registerNewUser( @RequestBody  Location location){
        locationService.addNewLocation(location);
        
    }

    @DeleteMapping(path =  "{locationId}")
    public void deleteUser(@PathVariable("locationId") Long locationId){
        locationService.deleteUser(locationId);
    }

    @PutMapping(path = "{userId}")
    public void updateUser(@PathVariable("locationId") long locationId, @RequestParam(required = false) int locationActivePlayers){
        locationService.updateUser(locationId, locationActivePlayers);
    }
    
} 
