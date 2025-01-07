package com.example.userJoinedLocations;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserJoinedLocationsRepository extends JpaRepository<UserJoinedLocations, Long> {
    List<UserJoinedLocations> findByUserId(Long userId);
    void deleteByUserIdAndLocationId(Long userId, Long locationId);

}