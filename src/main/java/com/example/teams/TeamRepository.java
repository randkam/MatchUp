package com.example.teams;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TeamRepository extends JpaRepository<Team, Long> {
    List<Team> findByOwnerUserId(Long ownerUserId);
    
    @Query("SELECT t FROM Team t WHERE t.ownerUserId = :userId OR t.id IN (SELECT tm.teamId FROM TeamMember tm WHERE tm.userId = :userId)")
    List<Team> findAllForUser(Long userId);
}


