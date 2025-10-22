package com.example.tournaments;

import com.example.activities.ActivityService;
import com.example.teams.TeamMemberRepository;
import com.example.teams.TeamRepository;
import com.example.users.UserStats;
import com.example.users.UserStatsRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

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

    public BracketService(TournamentRepository tournamentRepository,
                          TournamentRegistrationRepository registrationRepository,
                          TournamentMatchRepository matchRepository,
                          TeamRepository teamRepository,
                          TeamMemberRepository teamMemberRepository,
                          UserStatsRepository userStatsRepository,
                          ActivityService activityService) {
        this.tournamentRepository = tournamentRepository;
        this.registrationRepository = registrationRepository;
        this.matchRepository = matchRepository;
        this.teamRepository = teamRepository;
        this.teamMemberRepository = teamMemberRepository;
        this.userStatsRepository = userStatsRepository;
        this.activityService = activityService;
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
        return generateBracketInternal(tournamentId, shuffle);
    }

    private List<TournamentMatch> generateBracketInternal(Long tournamentId, boolean shuffle) {
        Tournament t = tournamentRepository.findById(tournamentId)
                .orElseThrow(() -> new IllegalStateException("Tournament not found"));

        List<Long> teamIds = registrationRepository.findRegisteredTeamIds(tournamentId);
        if (teamIds == null || teamIds.isEmpty()) {
            throw new IllegalStateException("No registered teams");
        }

        int n = teamIds.size();
        if ((n & (n - 1)) != 0) {
            throw new IllegalStateException("Number of teams must be a power of 2");
        }

        List<Long> order = new ArrayList<>(teamIds);
        if (shuffle) Collections.shuffle(order, new Random());

        int rounds = (int) (Math.log(n) / Math.log(2));

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

        // Round 1 pairings
        for (int i = 0; i < n; i += 2) {
            int matchNumber = (i / 2) + 1;
            TournamentMatch tm = persisted.get("1:" + matchNumber);
            tm.setTeamAId(order.get(i));
            tm.setTeamBId(order.get(i + 1));
        }

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

        // If final, post single tournament completion notification to all teams with winner info
        if (isFinal && winner != null) {
            java.util.List<Long> teamIds = registrationRepository.findRegisteredTeamIds(match.getTournamentId());
            String winnerName = teamRepository.findById(winner).map(com.example.teams.Team::getName).orElse(null);
            for (Long teamId : teamIds) {
                String dedupe = "T_DONE:" + match.getTournamentId() + ":" + teamId;
                java.util.Map<String, Object> extras = new java.util.HashMap<>();
                extras.put("winner_team_id", winner);
                if (winnerName != null) extras.put("winner_team_name", winnerName);
                activityService.createTeamEventWithExtras(
                        "TOURNAMENT_COMPLETED",
                        teamId,
                        null,
                        null,
                        match.getTournamentId(),
                        dedupe,
                        extras
                );
            }
        }

        return saved;
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
}


