package com.example.tournaments;

import com.example.teams.TeamMemberRepository;
import com.example.teams.TeamRepository;
import com.example.activities.ActivityService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class TournamentRegistrationService {

    @Autowired
    private TournamentRepository tournamentRepository;
    @Autowired
    private TournamentRegistrationRepository registrationRepository;
    @Autowired
    private TeamRepository teamRepository;
    @Autowired
    private TeamMemberRepository teamMemberRepository;
    @Autowired
    private ActivityService activityService;

    public TournamentRegistration registerTeam(Long tournamentId, Long teamId, Long requestingUserId) {
        // Validate tournament exists
        Tournament tournament = tournamentRepository.findById(tournamentId)
                .orElseThrow(() -> new IllegalStateException("Tournament not found"));

        // Capacity check first, treat FULL as a derived state
        long registeredCount = registrationRepository.countRegisteredByTournamentId(tournamentId);
        if (registeredCount >= tournament.getMaxTeams()) {
            if (tournament.getStatus() != TournamentStatus.FULL) {
                tournament.setStatus(TournamentStatus.FULL);
                tournamentRepository.save(tournament);
            }
            throw new IllegalStateException("Tournament is at capacity");
        }

        // Gate signups by status but allow if status was incorrectly FULL while capacity remains
        boolean signupsAllowedStatus = (tournament.getStatus() == TournamentStatus.SIGNUPS_OPEN
                || tournament.getStatus() == TournamentStatus.LOCKED
                || tournament.getStatus() == TournamentStatus.FULL);
        if (!signupsAllowedStatus) {
            throw new IllegalStateException("Tournament signups are not open");
        }

        // Validate team exists
        teamRepository.findById(teamId).orElseThrow(() -> new IllegalStateException("Team not found"));

        // Only captain can register
        boolean isCaptain = teamMemberRepository.isCaptain(teamId, requestingUserId);
        if (!isCaptain) {
            throw new IllegalStateException("Only team captains can register teams");
        }

        // Prevent duplicate team registration
        if (registrationRepository.existsByTournamentIdAndTeamId(tournamentId, teamId)) {
            throw new IllegalStateException("This team is already registered for the tournament");
        }

        // Prevent a player from registering twice across teams
        List<Long> alreadyInUserIds = registrationRepository.findAllUserIdsAlreadyInTournament(tournamentId);
        if (!alreadyInUserIds.isEmpty()) {
            List<Long> thisTeamUserIds = teamMemberRepository.findUserIdsByTeamId(teamId);
            for (Long uid : thisTeamUserIds) {
                if (alreadyInUserIds.contains(uid)) {
                    throw new IllegalStateException("User ID " + uid + " is already registered in this tournament on another team");
                }
            }
        }

        TournamentRegistration reg = new TournamentRegistration();
        reg.setTournamentId(tournamentId);
        reg.setTeamId(teamId);
        reg.setStatus("REGISTERED");
        reg.setCheckedIn(false);
        TournamentRegistration saved = registrationRepository.save(reg);

        // If we hit capacity after this registration, mark tournament as FULL
        long newCount = registrationRepository.countRegisteredByTournamentId(tournamentId);
        if (newCount == tournament.getMaxTeams() && tournament.getStatus() != TournamentStatus.FULL) {
            tournament.setStatus(TournamentStatus.FULL);
            tournamentRepository.save(tournament);
        }

        // Create activity (single row) with snapshot and payload message
        String teamName = teamRepository.findById(teamId).map(t -> t.getName()).orElse(null);
        String dedupeKey = "TEAM_REGISTERED_TOURNAMENT:" + tournamentId + ":" + teamId;
        activityService.createTeamEvent("TEAM_REGISTERED_TOURNAMENT", teamId, requestingUserId, teamName, tournamentId, dedupeKey);
        return saved;
    }

    public List<TournamentRegistration> listRegistrations(Long tournamentId) {
        return registrationRepository.findByTournamentId(tournamentId);
    }

    public List<Map<String, Object>> listRegistrationsExpanded(Long tournamentId) {
        List<TournamentRegistrationProjection> rows = registrationRepository.findExpandedByTournamentId(tournamentId);
        List<Map<String, Object>> out = new java.util.ArrayList<>();
        int seed = 1;
        for (TournamentRegistrationProjection r : rows) {
            Map<String, Object> row = new HashMap<>();
            row.put("id", r.getId());
            row.put("team_id", r.getTeamId());
            row.put("team_name", r.getTeamName());
            row.put("seed", seed++);
            row.put("created_at", r.getCreatedAt());
            out.add(row);
        }
        return out;
    }

    public Map<String, Object> getEligibility(Long tournamentId, Long userId) {
        Map<String, Object> result = new HashMap<>();
        List<Long> registeredTeamIds = registrationRepository.findRegisteredTeamIds(tournamentId);
        List<Long> conflictedUserIds = registrationRepository.findAllUserIdsAlreadyInTournament(tournamentId);
        result.put("registered_team_ids", registeredTeamIds);
        result.put("conflicted_user_ids", conflictedUserIds);
        return result;
    }

    public List<Tournament> getUpcomingForTeam(Long teamId) {
        return registrationRepository.findUpcomingTournamentsForTeam(teamId);
    }

    public List<Tournament> getPastForTeam(Long teamId) {
        return registrationRepository.findPastTournamentsForTeam(teamId);
    }

    public void unregisterTeam(Long tournamentId, Long teamId, Long requestingUserId) {
        // Validate tournament exists
        Tournament tournament = tournamentRepository.findById(tournamentId)
                .orElseThrow(() -> new IllegalStateException("Tournament not found"));

        // Enforce 24-hour lockout before start time
        java.time.LocalDateTime now = java.time.LocalDateTime.now();
        if (tournament.getStartsAt() != null && !now.isBefore(tournament.getStartsAt().minusHours(24))) {
            throw new IllegalStateException("Unregistration window has closed (24 hours before start)");
        }

        // Validate team exists
        teamRepository.findById(teamId).orElseThrow(() -> new IllegalStateException("Team not found"));

        // Only captain can unregister the team
        boolean isCaptain = teamMemberRepository.isCaptain(teamId, requestingUserId);
        if (!isCaptain) {
            throw new IllegalStateException("Only team captains can unregister teams");
        }

        TournamentRegistration reg = registrationRepository
                .findByTournamentIdAndTeamId(tournamentId, teamId)
                .orElseThrow(() -> new IllegalStateException("Registration not found"));

        if (!"REGISTERED".equals(reg.getStatus())) {
            // No-op if already cancelled/other
            return;
        }

        reg.setStatus("CANCELLED");
        registrationRepository.save(reg);

        recalcTournamentStatusIfNeeded(tournament);
    }

    private void recalcTournamentStatusIfNeeded(Tournament tournament) {
        long count = registrationRepository.countRegisteredByTournamentId(tournament.getId());
        if (tournament.getStatus() == TournamentStatus.FULL && count < tournament.getMaxTeams()) {
            tournament.setStatus(TournamentStatus.SIGNUPS_OPEN);
            tournamentRepository.save(tournament);
        }
    }
}


