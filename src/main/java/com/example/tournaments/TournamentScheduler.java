package com.example.tournaments;

import com.example.activities.ActivityService;
import com.example.teams.TeamRepository;
import com.example.teams.Team;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

@Component
public class TournamentScheduler {

    private final TournamentRepository tournamentRepository;
    private final TournamentRegistrationRepository registrationRepository;
    private final TeamRepository teamRepository;
    private final ActivityService activityService;

    public TournamentScheduler(TournamentRepository tournamentRepository,
                               TournamentRegistrationRepository registrationRepository,
                               TeamRepository teamRepository,
                               ActivityService activityService) {
        this.tournamentRepository = tournamentRepository;
        this.registrationRepository = registrationRepository;
        this.teamRepository = teamRepository;
        this.activityService = activityService;
    }

    // Run every 10 minutes; create activities at ~24h and ~12h windows
    @Scheduled(cron = "0 */10 * * * *")
    public void postUpcomingTournamentActivities() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime windowStart = now.minusMinutes(10); // previous run window
        LocalDateTime windowEnd = now.plusMinutes(10);    // small future skew

        // Fetch tournaments that start soon-ish; we will filter by time window below
        List<Tournament> all = tournamentRepository.findAll();
        for (Tournament t : all) {
            if (t.getStartsAt() == null) continue;

            LocalDateTime startsAt = t.getStartsAt();

            // 24h bracket-available notification
            LocalDateTime twentyFour = startsAt.minusHours(24);
            if (!twentyFour.isBefore(windowStart) && !twentyFour.isAfter(windowEnd)) {
                List<Long> teamIds = registrationRepository.findRegisteredTeamIds(t.getId());
                for (Long teamId : teamIds) {
                    Team team = teamRepository.findById(teamId).orElse(null);
                    String teamName = team != null ? team.getName() : null;
                    String dedupe = "T24:" + t.getId() + ":" + teamId;
                    activityService.createTeamEvent(
                            "TOURNAMENT_BRACKET_AVAILABLE",
                            teamId,
                            null,
                            teamName,
                            t.getId(),
                            dedupe
                    );
                }
            }

            // 12h starts-soon notification
            LocalDateTime twelve = startsAt.minusHours(12);
            if (!twelve.isBefore(windowStart) && !twelve.isAfter(windowEnd)) {
                List<Long> teamIds = registrationRepository.findRegisteredTeamIds(t.getId());
                for (Long teamId : teamIds) {
                    Team team = teamRepository.findById(teamId).orElse(null);
                    String teamName = team != null ? team.getName() : null;
                    String dedupe = "T12:" + t.getId() + ":" + teamId;
                    activityService.createTeamEvent(
                            "TOURNAMENT_STARTS_SOON",
                            teamId,
                            null,
                            teamName,
                            t.getId(),
                            dedupe
                    );
                }
            }

            // Lock registrations at T-24h if still open
            LocalDateTime lockAt = startsAt.minusHours(24);
            if (!lockAt.isAfter(now) && startsAt.isAfter(now)) {
                if (t.getStatus() == TournamentStatus.SIGNUPS_OPEN) {
                    t.setStatus(TournamentStatus.LOCKED);
                    tournamentRepository.save(t);
                }
            }
        }
    }
}


