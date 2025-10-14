package com.example.users;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserStatsRepository extends JpaRepository<UserStats, UserStatsKey> {
    Optional<UserStats> findFirstByUserIdAndSport(Long userId, String sport);
}


