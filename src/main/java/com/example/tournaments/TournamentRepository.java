package com.example.tournaments;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public interface TournamentRepository extends JpaRepository<Tournament, Long> {
    @Query("SELECT t FROM Tournament t WHERE t.status IN (com.example.tournaments.TournamentStatus.SIGNUPS_OPEN, com.example.tournaments.TournamentStatus.LOCKED, com.example.tournaments.TournamentStatus.FULL) AND t.startsAt > :now ORDER BY t.startsAt ASC")
    Page<Tournament> findUpcoming(LocalDateTime now, Pageable pageable);
}

