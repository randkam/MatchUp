package com.example.tournaments;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TournamentRegistrationRepository extends JpaRepository<TournamentRegistration, Long> {
    List<TournamentRegistration> findByTournamentId(Long tournamentId);
    Optional<TournamentRegistration> findByTournamentIdAndTeamId(Long tournamentId, Long teamId);
    List<TournamentRegistration> findByTeamId(Long teamId);

    @Query("SELECT COUNT(tr) > 0 FROM TournamentRegistration tr WHERE tr.tournamentId = :tournamentId AND tr.teamId = :teamId")
    boolean existsByTournamentIdAndTeamId(Long tournamentId, Long teamId);

    // Returns list of userIds that are on any team already registered for the tournament
    @Query("SELECT DISTINCT tm.userId FROM com.example.teams.TeamMember tm WHERE tm.teamId IN (SELECT tr.teamId FROM TournamentRegistration tr WHERE tr.tournamentId = :tournamentId)")
    List<Long> findAllUserIdsAlreadyInTournament(Long tournamentId);

    // Returns list of teamIds registered for the tournament
    @Query("SELECT tr.teamId FROM TournamentRegistration tr WHERE tr.tournamentId = :tournamentId")
    List<Long> findRegisteredTeamIds(Long tournamentId);

    @Query("SELECT COUNT(tr) FROM TournamentRegistration tr WHERE tr.tournamentId = :tournamentId AND tr.status = 'REGISTERED'")
    long countRegisteredByTournamentId(Long tournamentId);

    @Query("SELECT tr.id as id, tr.teamId as teamId, t.name as teamName, CAST(tr.createdAt as string) as createdAt FROM TournamentRegistration tr JOIN com.example.teams.Team t ON t.id = tr.teamId WHERE tr.tournamentId = :tournamentId AND tr.status = 'REGISTERED' ORDER BY tr.createdAt ASC")
    List<TournamentRegistrationProjection> findExpandedByTournamentId(Long tournamentId);

    // Upcoming tournaments for a team
    @Query("SELECT t FROM TournamentRegistration tr JOIN Tournament t ON t.id = tr.tournamentId WHERE tr.teamId = :teamId AND t.startsAt >= CURRENT_TIMESTAMP ORDER BY t.startsAt ASC")
    List<Tournament> findUpcomingTournamentsForTeam(Long teamId);
}


