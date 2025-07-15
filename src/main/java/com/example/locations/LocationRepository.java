package com.example.locations;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LocationRepository extends JpaRepository<Location, Long> {
    Page<Location> findByLocationNameContainingIgnoreCaseOrLocationAddressContainingIgnoreCase(
        String name, String address, Pageable pageable);
    
    Page<Location> findByLocationType(LocationType type, Pageable pageable);
    
    Page<Location> findByLocationTypeAndIsLitAtNight(LocationType type, Boolean isLit, Pageable pageable);
    
    Page<Location> findByIsLitAtNight(Boolean isLit, Pageable pageable);
}
