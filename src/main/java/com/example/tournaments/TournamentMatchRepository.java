package com.example.tournaments;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TournamentMatchRepository extends JpaRepository<TournamentMatch, Long> {
    List<TournamentMatch> findByTournamentIdOrderByRoundNumberAscMatchNumberAsc(Long tournamentId);
    List<TournamentMatch> findByTournamentIdAndRoundNumberOrderByMatchNumberAsc(Long tournamentId, Integer roundNumber);
    boolean existsByTournamentId(Long tournamentId);
    java.util.Optional<TournamentMatch> findByTournamentIdAndRoundNumberAndMatchNumber(Long tournamentId, Integer roundNumber, Integer matchNumber);

    long countByWinnerTeamId(Long teamId);

    @Query("SELECT COUNT(m) FROM TournamentMatch m WHERE m.status = 'COMPLETE' AND (m.teamAId = :teamId OR m.teamBId = :teamId) AND (m.winnerTeamId IS NULL OR m.winnerTeamId <> :teamId)")
    long countLossesByTeamId(Long teamId);

    @Query("SELECT COUNT(m) FROM TournamentMatch m WHERE m.status = 'COMPLETE' AND m.winnerTeamId = :teamId AND m.nextMatchId IS NULL")
    long countTournamentsWon(Long teamId);
}


