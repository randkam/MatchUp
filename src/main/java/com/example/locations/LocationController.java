package com.example.locations;

import com.example.config.PaginationConfig;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/locations")
public class LocationController {

    @Autowired
    private LocationService locationService;

    @GetMapping
    public ResponseEntity<Page<Location>> getAllLocations(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") Integer size,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String direction,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Boolean isIndoor,
            @RequestParam(required = false) Boolean isLit) {
        Page<Location> locationsPage = locationService.getAllLocations(
            PaginationConfig.createPageRequest(page, size, sortBy, direction),
            search, isIndoor, isLit);
        return ResponseEntity.ok(locationsPage);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Location> getLocationById(@PathVariable Long id) {
        return ResponseEntity.ok(locationService.getLocationById(id));
    }

    @PostMapping("/{id}/increment-players")
    public ResponseEntity<Location> incrementActivePlayers(@PathVariable Long id) {
        Location location = locationService.incrementActivePlayers(id);
        return ResponseEntity.ok(location);
    }

    @PostMapping("/{id}/decrement-players")
    public ResponseEntity<Location> decrementActivePlayers(@PathVariable Long id) {
        Location location = locationService.decrementActivePlayers(id);
        return ResponseEntity.ok(location);
    }
} 
