package com.example.tournaments;

import com.example.activities.ActivityService;
import com.example.teams.TeamMemberRepository;
import com.example.teams.TeamRepository;
import com.example.users.UserStats;
import com.example.users.UserStatsRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import jakarta.persistence.EntityManager;

@Service
public class BracketService {
    private final TournamentRepository tournamentRepository;
    private final TournamentRegistrationRepository registrationRepository;
    private final TournamentMatchRepository matchRepository;
    // TeamRepository available if needed later for validations
    private final TeamRepository teamRepository;
    private final TeamMemberRepository teamMemberRepository;
    private final UserStatsRepository userStatsRepository;

    private final ActivityService activityService;
    private final EntityManager entityManager;

    public BracketService(TournamentRepository tournamentRepository,
                          TournamentRegistrationRepository registrationRepository,
                          TournamentMatchRepository matchRepository,
                          TeamRepository teamRepository,
                          TeamMemberRepository teamMemberRepository,
                          UserStatsRepository userStatsRepository,
                          ActivityService activityService,
                          EntityManager entityManager) {
        this.tournamentRepository = tournamentRepository;
        this.registrationRepository = registrationRepository;
        this.matchRepository = matchRepository;
        this.teamRepository = teamRepository;
        this.teamMemberRepository = teamMemberRepository;
        this.userStatsRepository = userStatsRepository;
        this.activityService = activityService;
        this.entityManager = entityManager;
    }

    public List<TournamentMatch> getBracket(Long tournamentId) {
        return matchRepository.findByTournamentIdOrderByRoundNumberAscMatchNumberAsc(tournamentId);
    }

    @Transactional
    public List<TournamentMatch> autoGenerateIfWindow(Long tournamentId) {
        Tournament t = tournamentRepository.findById(tournamentId)
                .orElseThrow(() -> new IllegalStateException("Tournament not found"));
        // Only generate inside the 24h window prior to start
        java.time.LocalDateTime now = java.time.LocalDateTime.now();
        if (t.getStartsAt().minusHours(24).isAfter(now)) {
            throw new IllegalStateException("Bracket not available yet");
        }
        if (matchRepository.existsByTournamentId(tournamentId)) {
            return matchRepository.findByTournamentIdOrderByRoundNumberAscMatchNumberAsc(tournamentId);
        }
        // Generate with shuffle=true and no owner gating
        return generateBracketInternal(tournamentId, true);
    }

    @Transactional
    public List<TournamentMatch> generateBracket(Long tournamentId, boolean shuffle, Long requestingUserId) {
        // Keep endpoint but remove owner requirement (admin endpoint can be added later if needed)
        if (matchRepository.existsByTournamentId(tournamentId)) {
            throw new IllegalStateException("Bracket already exists");
        }
        // Always generate with random seeding
        return generateBracketInternal(tournamentId, true);
    }
    
    @Transactional
    public List<TournamentMatch> regenerateBracket(Long tournamentId, Long requestingUserId) {
        // Admin-gated at controller; here just reset and regenerate with shuffle=true
        if (matchRepository.existsByTournamentId(tournamentId)) {
            matchRepository.deleteByTournamentId(tournamentId);
            matchRepository.flush();
            // Clear persistence context to avoid stale entities interfering in the same transaction
            entityManager.clear();
        }
        return generateBracketInternal(tournamentId, true);
    }

    private List<TournamentMatch> generateBracketInternal(Long tournamentId, boolean shuffle) {
        Tournament t = tournamentRepository.findById(tournamentId)
                .orElseThrow(() -> new IllegalStateException("Tournament not found"));

        List<Long> registeredTeamIds = registrationRepository.findRegisteredTeamIds(tournamentId);
        if (registeredTeamIds == null || registeredTeamIds.isEmpty()) {
            throw new IllegalStateException("No registered teams");
        }

        Integer maxTeams = t.getMaxTeams();
        if (maxTeams == null || maxTeams <= 0 || (maxTeams & (maxTeams - 1)) != 0) {
            throw new IllegalStateException("Tournament max_teams must be a power of 2");
        }
        if (registeredTeamIds.size() > maxTeams) {
            throw new IllegalStateException("Registered teams exceed tournament maximum");
        }

        // Always shuffle for random seeding
        List<Long> order = new ArrayList<>(registeredTeamIds);
        Collections.shuffle(order, new Random());

        // Pad with byes (null placeholders) up to maxTeams
        int byesToInsert = maxTeams - order.size();
        for (int i = 0; i < byesToInsert; i++) {
            order.add(null);
        }

        int rounds = (int) (Math.log(maxTeams) / Math.log(2));

        // Pre-create all matches
        List<TournamentMatch> created = new ArrayList<>();
        Map<String, TournamentMatch> index = new HashMap<>();
        for (int r = 1; r <= rounds; r++) {
            int matchesInRound = 1 << (rounds - r);
            for (int m = 1; m <= matchesInRound; m++) {
                TournamentMatch tm = new TournamentMatch();
                tm.setTournamentId(tournamentId);
                tm.setRoundNumber(r);
                tm.setMatchNumber(m);
                created.add(tm);
                index.put(r + ":" + m, tm);
            }
        }

        // Link next match pointers
        for (int r = 1; r < rounds; r++) {
            int matchesInRound = 1 << (rounds - r);
            for (int m = 1; m <= matchesInRound; m++) {
                // Pre-link index keys; IDs set after initial save
                index.get(r + ":" + m);
                int nextRound = r + 1;
                int nextMatchNumber = (m + 1) / 2;
                index.get(nextRound + ":" + nextMatchNumber);
                // Persist after save to get IDs
                // We'll set references after first save when IDs are known
            }
        }

        // Save to get IDs
        matchRepository.saveAll(created);

        // Rebuild index by key after IDs exist
        Map<String, TournamentMatch> persisted = new HashMap<>();
        for (TournamentMatch tm : matchRepository.findByTournamentIdOrderByRoundNumberAscMatchNumberAsc(tournamentId)) {
            persisted.put(tm.getRoundNumber() + ":" + tm.getMatchNumber(), tm);
        }

        // Assign next_match references (persist immediately so IDs are present for following links)
        for (int r = 1; r < rounds; r++) {
            int matchesInRound = 1 << (rounds - r);
            for (int m = 1; m <= matchesInRound; m++) {
                TournamentMatch cur = persisted.get(r + ":" + m);
                TournamentMatch next = persisted.get((r + 1) + ":" + ((m + 1) / 2));
                if (next != null) {
                    cur.setNextMatchId(next.getId());
                    cur.setNextMatchSlot((m % 2 == 1) ? "1" : "2");
                }
            }
        }
        matchRepository.saveAll(persisted.values());

        // Round 1 pairings (includes null byes)
        for (int i = 0; i < maxTeams; i += 2) {
            int matchNumber = (i / 2) + 1;
            TournamentMatch tm = persisted.get("1:" + matchNumber);
            tm.setTeamAId(order.get(i));
            tm.setTeamBId(order.get(i + 1));
        }

        // Auto-advance any matches with a bye (one null slot). Propagate repeatedly until stable.
        boolean progressed = true;
        while (progressed) {
            progressed = false;
            for (int r = 1; r <= rounds; r++) {
                int matchesInRound = 1 << (rounds - r);
                for (int m = 1; m <= matchesInRound; m++) {
                    TournamentMatch cur = persisted.get(r + ":" + m);
                    if (cur == null) continue;
                    if (!"COMPLETE".equals(cur.getStatus())) {
                        Long a = cur.getTeamAId();
                        Long b = cur.getTeamBId();
                        // Auto-complete if exactly one team is present
                        if ((a != null && b == null) || (a == null && b != null)) {
                            Long winner = (a != null) ? a : b;
                            cur.setWinnerTeamId(winner);
                            cur.setStatus("COMPLETE");
                            // advance to next match if exists
                            if (cur.getNextMatchId() != null && cur.getNextMatchSlot() != null) {
                                TournamentMatch next = null;
                                // next is in "persisted" map by round/match, but we only have ID here; find by round/match via known mapping
                                int nextRound = r + 1;
                                int nextMatchNumber = (m + 1) / 2;
                                next = persisted.get(nextRound + ":" + nextMatchNumber);
                                if (next != null) {
                                    if ("1".equals(cur.getNextMatchSlot())) {
                                        if (!Objects.equals(next.getTeamAId(), winner)) {
                                            next.setTeamAId(winner);
                                        }
                                    } else {
                                        if (!Objects.equals(next.getTeamBId(), winner)) {
                                            next.setTeamBId(winner);
                                        }
                                    }
                                }
                            }
                            progressed = true;
                        }
                    }
                }
            }
        }

        matchRepository.saveAll(persisted.values());
        return matchRepository.findByTournamentIdOrderByRoundNumberAscMatchNumberAsc(tournamentId);
    }

    @Transactional
    public TournamentMatch updateScore(Long tournamentId, Long matchId, int scoreA, int scoreB, Long requestingUserId) {
        // Authorization should be based on user role (ADMIN) at controller layer or security filter.
        TournamentMatch match = matchRepository.findById(matchId)
                .orElseThrow(() -> new IllegalStateException("Match not found"));
        if (!Objects.equals(match.getTournamentId(), tournamentId)) {
            throw new IllegalStateException("Match not in this tournament");
        }

        match.setScoreA(scoreA);
        match.setScoreB(scoreB);

        if (Objects.equals(scoreA, scoreB)) {
            throw new IllegalStateException("Ties are not allowed");
        }

        Long winner = (scoreA > scoreB) ? match.getTeamAId() : match.getTeamBId();
        Long loser = (winner != null && winner.equals(match.getTeamAId())) ? match.getTeamBId() : match.getTeamAId();
        match.setWinnerTeamId(winner);
        match.setStatus("COMPLETE");

        // Advance
        boolean isFinal = (match.getNextMatchId() == null);
        if (match.getNextMatchId() != null && match.getNextMatchSlot() != null) {
            TournamentMatch next = matchRepository.findById(match.getNextMatchId())
                    .orElseThrow(() -> new IllegalStateException("Next match not found"));
            if ("1".equals(match.getNextMatchSlot())) {
                next.setTeamAId(winner);
            } else {
                next.setTeamBId(winner);
            }
            matchRepository.save(next);
        }

        // Update user stats for both teams
        updateUserStatsForMatch(winner, loser, isFinal);

        TournamentMatch saved = matchRepository.save(match);

        // Post activities for both teams with scores
        if (winner != null && loser != null) {
            String loserName = teamRepository.findById(loser).map(com.example.teams.Team::getName).orElse(null);
            String winnerName = teamRepository.findById(winner).map(com.example.teams.Team::getName).orElse(null);
            Map<String, Object> extras = new HashMap<>();
            extras.put("opponent_team_id", loser);
            if (loserName != null) extras.put("opponent_team_name", loserName);
            extras.put("score_for", Objects.equals(winner, match.getTeamAId()) ? scoreA : scoreB);
            extras.put("score_against", Objects.equals(winner, match.getTeamAId()) ? scoreB : scoreA);
            String dedupeWin = "MR:WIN:" + saved.getId() + ":" + winner;
            activityService.createTeamEventWithExtras(
                    "MATCH_RESULT_WIN",
                    winner,
                    null,
                    null,
                    match.getTournamentId(),
                    dedupeWin,
                    extras
            );

            Map<String, Object> extrasL = new HashMap<>();
            extrasL.put("opponent_team_id", winner);
            if (winnerName != null) extrasL.put("opponent_team_name", winnerName);
            extrasL.put("score_for", Objects.equals(winner, match.getTeamAId()) ? scoreB : scoreA);
            extrasL.put("score_against", Objects.equals(winner, match.getTeamAId()) ? scoreA : scoreB);
            String dedupeLoss = "MR:LOSS:" + saved.getId() + ":" + loser;
            activityService.createTeamEventWithExtras(
                    "MATCH_RESULT_LOSS",
                    loser,
                    null,
                    null,
                    match.getTournamentId(),
                    dedupeLoss,
                    extrasL
            );
        }

        // Do NOT auto-finalize tournament here even for final; an explicit "announce winner" action will handle completion.

        return saved;
    }

    private boolean isTeamCheckedIn(Long tournamentId, Long teamId) {
        if (teamId == null) return false;
        return registrationRepository.findByTournamentIdAndTeamId(tournamentId, teamId)
                .map(TournamentRegistration::isCheckedIn)
                .orElse(false);
    }

    @Transactional
    public List<TournamentMatch> enforceAttendance(Long tournamentId) {
        Tournament tournament = tournamentRepository.findById(tournamentId)
                .orElseThrow(() -> new IllegalStateException("Tournament not found"));

        // Build checked-in map and set of absent teamIds
        java.util.List<TournamentRegistration> regs = registrationRepository.findByTournamentId(tournamentId);
        java.util.Set<Long> present = new java.util.HashSet<>();
        java.util.Set<Long> absent = new java.util.HashSet<>();
        for (TournamentRegistration tr : regs) {
            if ("REGISTERED".equals(tr.getStatus()) && tr.isCheckedIn()) present.add(tr.getTeamId());
            if ("REGISTERED".equals(tr.getStatus()) && !tr.isCheckedIn()) absent.add(tr.getTeamId());
        }

        // If bracket not present, nothing to enforce yet
        if (!matchRepository.existsByTournamentId(tournamentId)) {
            // If fewer than 2 teams present at/after check-in cutoff, mark cancelled-complete
            if (present.size() < 2 && java.time.LocalDateTime.now().isAfter(tournament.getStartsAt().minusMinutes(30))) {
                tournament.setEndsAt(java.time.LocalDateTime.now());
                tournament.setStatus(TournamentStatus.COMPLETE);
                tournamentRepository.save(tournament);
                // Notify registered teams
                java.util.List<Long> teamIds = registrationRepository.findRegisteredTeamIds(tournamentId);
                for (Long teamId : teamIds) {
                    String dedupe = "T_DONE_INSUFFICIENT:" + tournamentId + ":" + teamId;
                    java.util.Map<String, Object> extras = new java.util.HashMap<>();
                    extras.put("note", "Tournament cancelled: not enough teams checked in.");
                    activityService.createTeamEventWithExtras(
                            "TOURNAMENT_COMPLETED",
                            teamId,
                            null,
                            null,
                            tournamentId,
                            dedupe,
                            extras
                    );
                }
            }
            return java.util.Collections.emptyList();
        }

        // Load all matches
        java.util.List<TournamentMatch> matches = matchRepository.findByTournamentIdOrderByRoundNumberAscMatchNumberAsc(tournamentId);
        int maxRound = 0;
        for (TournamentMatch m : matches) maxRound = Math.max(maxRound, m.getRoundNumber());

        // Remove absent teams from upcoming matches
        for (TournamentMatch m : matches) {
            if (!"COMPLETE".equals(m.getStatus())) {
                if (m.getTeamAId() != null && absent.contains(m.getTeamAId())) {
                    m.setTeamAId(null);
                }
                if (m.getTeamBId() != null && absent.contains(m.getTeamBId())) {
                    m.setTeamBId(null);
                }
            }
        }

        // Propagate auto-advance for any one-sided matches
        boolean progressed = true;
        while (progressed) {
            progressed = false;
            for (int r = 1; r <= maxRound; r++) {
                int matchesInRound = 1 << (maxRound - r);
                for (int mnum = 1; mnum <= matchesInRound; mnum++) {
                    // find match
                    TournamentMatch cur = null;
                    for (TournamentMatch x : matches) {
                        if (x.getRoundNumber() == r && x.getMatchNumber() == mnum) { cur = x; break; }
                    }
                    if (cur == null) continue;
                    if (!"COMPLETE".equals(cur.getStatus())) {
                        Long a = cur.getTeamAId();
                        Long b = cur.getTeamBId();
                        // if both absent, leave empty
                        if ((a != null && b == null) || (a == null && b != null)) {
                            Long winner = (a != null) ? a : b;
                            // Only present teams can advance
                            if (!present.contains(winner)) {
                                // if winner is not present, treat as no-show -> clear and continue
                                if (a != null && !present.contains(a)) cur.setTeamAId(null);
                                if (b != null && !present.contains(b)) cur.setTeamBId(null);
                                continue;
                            }
                            cur.setWinnerTeamId(winner);
                            cur.setStatus("COMPLETE");
                            if (cur.getNextMatchId() != null && cur.getNextMatchSlot() != null) {
                                // find next by round/match number
                                int nextRound = r + 1;
                                int nextMatchNumber = (mnum + 1) / 2;
                                TournamentMatch next = null;
                                for (TournamentMatch x : matches) {
                                    if (x.getRoundNumber() == nextRound && x.getMatchNumber() == nextMatchNumber) { next = x; break; }
                                }
                                if (next != null) {
                                    if ("1".equals(cur.getNextMatchSlot())) {
                                        next.setTeamAId(winner);
                                    } else {
                                        next.setTeamBId(winner);
                                    }
                                }
                            } else {
                                // Final match resolved via attendance
                                if (isTeamCheckedIn(tournamentId, winner)) {
                                    tournament.setEndsAt(java.time.LocalDateTime.now());
                                    tournament.setStatus(TournamentStatus.COMPLETE);
                                    tournamentRepository.save(tournament);
                                    // notify
                                    java.util.List<Long> teamIds = registrationRepository.findRegisteredTeamIds(tournamentId);
                                    String winnerName = teamRepository.findById(winner).map(com.example.teams.Team::getName).orElse(null);
                                    for (Long teamId : teamIds) {
                                        String dedupe = "T_DONE:" + tournamentId + ":" + teamId;
                                        java.util.Map<String, Object> extras = new java.util.HashMap<>();
                                        extras.put("winner_team_id", winner);
                                        if (winnerName != null) extras.put("winner_team_name", winnerName);
                                        activityService.createTeamEventWithExtras(
                                                "TOURNAMENT_COMPLETED",
                                                teamId,
                                                null,
                                                null,
                                                tournamentId,
                                                dedupe,
                                                extras
                                        );
                                    }
                                }
                            }
                            progressed = true;
                        }
                    }
                }
            }
        }

        // If fewer than 2 teams present, cancel (complete with message)
        if (present.size() < 2) {
            tournament.setEndsAt(java.time.LocalDateTime.now());
            tournament.setStatus(TournamentStatus.COMPLETE);
            tournamentRepository.save(tournament);
            // Clear any recorded winners to avoid implying a champion by byes
            for (TournamentMatch m : matches) {
                m.setWinnerTeamId(null);
            }
            matchRepository.saveAll(matches);
            java.util.List<Long> teamIds = registrationRepository.findRegisteredTeamIds(tournamentId);
            for (Long teamId : teamIds) {
                String dedupe = "T_DONE_INSUFFICIENT:" + tournamentId + ":" + teamId;
                java.util.Map<String, Object> extras = new java.util.HashMap<>();
                extras.put("note", "Tournament cancelled: not enough teams checked in.");
                activityService.createTeamEventWithExtras(
                        "TOURNAMENT_COMPLETED",
                        teamId,
                        null,
                        null,
                        tournamentId,
                        dedupe,
                        extras
                );
            }
        }

        matchRepository.saveAll(matches);
        return matchRepository.findByTournamentIdOrderByRoundNumberAscMatchNumberAsc(tournamentId);
    }
    private void updateUserStatsForMatch(Long winnerTeamId, Long loserTeamId, boolean isFinal) {
        if (winnerTeamId == null || loserTeamId == null) return;
        java.util.List<Long> winnerUserIds = teamMemberRepository.findUserIdsByTeamId(winnerTeamId);
        java.util.List<Long> loserUserIds = teamMemberRepository.findUserIdsByTeamId(loserTeamId);

        for (Long uid : winnerUserIds) {
            upsertStats(uid, true, isFinal);
        }
        for (Long uid : loserUserIds) {
            upsertStats(uid, false, false);
        }
    }

    private void upsertStats(Long userId, boolean isWin, boolean addTitle) {
        String sport = "basketball";
        UserStats stats = userStatsRepository.findFirstByUserIdAndSport(userId, sport).orElse(null);
        if (stats == null) {
            stats = new UserStats();
            stats.setUserId(userId);
            stats.setSport(sport);
            stats.setMatchWins(0);
            stats.setMatchLosses(0);
            stats.setTitles(0);
        }
        if (isWin) stats.incrementWin(); else stats.incrementLoss();
        if (addTitle) stats.incrementTitle();
        userStatsRepository.save(stats);
    }

    private void addTitleForTeam(Long teamId) {
        if (teamId == null) return;
        java.util.List<Long> userIds = teamMemberRepository.findUserIdsByTeamId(teamId);
        for (Long uid : userIds) {
            UserStats stats = userStatsRepository.findFirstByUserIdAndSport(uid, "basketball").orElse(null);
            if (stats == null) {
                stats = new UserStats();
                stats.setUserId(uid);
                stats.setSport("basketball");
                stats.setMatchWins(0);
                stats.setMatchLosses(0);
                stats.setTitles(0);
            }
            stats.incrementTitle();
            userStatsRepository.save(stats);
        }
    }
    
    @Transactional
    public Tournament finalizeTournament(Long tournamentId, Long requestingUserId) {
        // Find final match (max round)
        java.util.List<TournamentMatch> matches = matchRepository.findByTournamentIdOrderByRoundNumberAscMatchNumberAsc(tournamentId);
        if (matches.isEmpty()) throw new IllegalStateException("No bracket found");
        int maxRound = 0;
        for (TournamentMatch m : matches) maxRound = Math.max(maxRound, m.getRoundNumber());
        TournamentMatch finalMatch = null;
        for (TournamentMatch m : matches) {
            if (m.getRoundNumber() == maxRound) { finalMatch = m; break; }
        }
        if (finalMatch == null || !"COMPLETE".equals(finalMatch.getStatus()) || finalMatch.getWinnerTeamId() == null) {
            throw new IllegalStateException("Final match is not complete");
        }
        Long winner = finalMatch.getWinnerTeamId();
        if (!isTeamCheckedIn(tournamentId, winner)) {
            throw new IllegalStateException("Winner team has not checked in");
        }
        Tournament tournament = tournamentRepository.findById(tournamentId).orElseThrow(() -> new IllegalStateException("Tournament not found"));
        tournament.setEndsAt(java.time.LocalDateTime.now());
        tournament.setStatus(TournamentStatus.COMPLETE);
        tournamentRepository.save(tournament);
        
        // Add title to winner team members
        addTitleForTeam(winner);
        
        // Notify all teams
        String winnerName = teamRepository.findById(winner).map(com.example.teams.Team::getName).orElse(null);
        java.util.List<Long> teamIds = registrationRepository.findRegisteredTeamIds(tournamentId);
        for (Long teamId : teamIds) {
            String dedupe = "T_DONE:" + tournamentId + ":" + teamId;
            java.util.Map<String, Object> extras = new java.util.HashMap<>();
            extras.put("winner_team_id", winner);
            if (winnerName != null) extras.put("winner_team_name", winnerName);
            activityService.createTeamEventWithExtras(
                    "TOURNAMENT_COMPLETED",
                    teamId,
                    null,
                    null,
                    tournamentId,
                    dedupe,
                    extras
            );
        }
        // Winner announcement activity
        activityService.createTeamEvent("TOURNAMENT_WINNER", winner, null, winnerName, tournamentId, "T_WINNER:" + tournamentId + ":" + winner);
        return tournament;
    }
}


