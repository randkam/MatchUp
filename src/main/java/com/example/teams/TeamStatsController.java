package com.example.teams;

import com.example.tournaments.TournamentMatchRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/teams")
public class TeamStatsController {
    private final TournamentMatchRepository matchRepository;

    public TeamStatsController(TournamentMatchRepository matchRepository) {
        this.matchRepository = matchRepository;
    }

    @GetMapping("/{teamId}/tournament-stats")
    public ResponseEntity<Map<String, Long>> getTeamTournamentStats(@PathVariable Long teamId) {
        long wins = matchRepository.countByWinnerTeamId(teamId);
        long losses = matchRepository.countLossesByTeamId(teamId);
        long tournamentsWon = matchRepository.countTournamentsWon(teamId);
        Map<String, Long> body = new HashMap<>();
        body.put("wins", wins);
        body.put("losses", losses);
        body.put("tournaments_won", tournamentsWon);
        return ResponseEntity.ok(body);
    }
}


