package com.example.tournaments;

import com.example.users.User;
import com.example.users.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/tournaments/{tournamentId}")
public class BracketController {
    private final BracketService bracketService;
    private final UserRepository userRepository;

    public BracketController(BracketService bracketService, UserRepository userRepository) {
        this.bracketService = bracketService;
        this.userRepository = userRepository;
    }

    @GetMapping("/bracket")
    public ResponseEntity<List<TournamentMatch>> getBracket(@PathVariable Long tournamentId) {
        // Auto-generate if within 24h and not present
        List<TournamentMatch> existing = bracketService.getBracket(tournamentId);
        if (existing == null || existing.isEmpty()) {
            try {
                List<TournamentMatch> created = bracketService.autoGenerateIfWindow(tournamentId);
                if (created != null) return ResponseEntity.ok(created);
            } catch (IllegalStateException e) {
                // fall through and return empty with 200; frontend will show not generated yet
            }
        }
        return ResponseEntity.ok(existing);
    }

    // Keep manual generate for admin tools if needed later (optional)
    @PostMapping("/bracket/regenerate")
    public ResponseEntity<?> regenerate(@PathVariable Long tournamentId,
                                        @RequestParam(name = "requesting_user_id") Long requestingUserId) {
        // Admin only
        String role = userRepository.findById(requestingUserId)
                .map(User::getRole)
                .orElse("USER");
        if (!"ADMIN".equalsIgnoreCase(role)) {
            return ResponseEntity.status(403).body(Map.of("message", "Only admins can regenerate brackets"));
        }
        try {
            List<TournamentMatch> created = bracketService.regenerateBracket(tournamentId, requestingUserId);
            return ResponseEntity.ok(created);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PatchMapping("/matches/{matchId}/score")
    public ResponseEntity<?> updateScore(@PathVariable Long tournamentId,
                                         @PathVariable Long matchId,
                                         @RequestBody Map<String, Integer> body,
                                         @RequestParam(name = "requesting_user_id") Long requestingUserId) {
        try {
            // Enforce ADMIN role for score updates
            String role = userRepository.findById(requestingUserId)
                    .map(User::getRole)
                    .orElse("USER");
            if (!"ADMIN".equalsIgnoreCase(role)) {
                return ResponseEntity.status(403).body(Map.of("message", "Only admins can update scores"));
            }
            int scoreA = body.getOrDefault("team1_score", body.getOrDefault("score_a", 0));
            int scoreB = body.getOrDefault("team2_score", body.getOrDefault("score_b", 0));
            TournamentMatch updated = bracketService.updateScore(tournamentId, matchId, scoreA, scoreB, requestingUserId);
            return ResponseEntity.ok(updated);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }
    
    @PostMapping("/finalize")
    public ResponseEntity<?> finalizeTournament(@PathVariable Long tournamentId,
                                                @RequestParam(name = "requesting_user_id") Long requestingUserId) {
        // Admin only
        String role = userRepository.findById(requestingUserId)
                .map(User::getRole)
                .orElse("USER");
        if (!"ADMIN".equalsIgnoreCase(role)) {
            return ResponseEntity.status(403).body(Map.of("message", "Only admins can finalize"));
        }
        try {
            Tournament t = bracketService.finalizeTournament(tournamentId, requestingUserId);
            return ResponseEntity.ok(t);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }
}


