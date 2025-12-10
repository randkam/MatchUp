package com.example.tournaments;

import com.example.users.User;
import com.example.users.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/tournaments/{tournamentId}/attendance")
public class AttendanceController {
    private final TournamentRepository tournamentRepository;
    private final TournamentRegistrationRepository registrationRepository;
    private final com.example.teams.TeamRepository teamRepository;
    private final UserRepository userRepository;
    private final BracketService bracketService;

    public AttendanceController(TournamentRepository tournamentRepository,
                                TournamentRegistrationRepository registrationRepository,
                                com.example.teams.TeamRepository teamRepository,
                                UserRepository userRepository,
                                BracketService bracketService) {
        this.tournamentRepository = tournamentRepository;
        this.registrationRepository = registrationRepository;
        this.teamRepository = teamRepository;
        this.userRepository = userRepository;
        this.bracketService = bracketService;
    }

    @GetMapping
    public ResponseEntity<?> list(@PathVariable Long tournamentId) {
        Tournament t = tournamentRepository.findById(tournamentId).orElse(null);
        if (t == null) return ResponseEntity.notFound().build();
        List<TournamentRegistration> regs = registrationRepository.findByTournamentId(tournamentId);
        List<Map<String, Object>> out = new java.util.ArrayList<>();
        for (TournamentRegistration r : regs) {
            if (!"REGISTERED".equals(r.getStatus())) continue;
            Map<String, Object> row = new HashMap<>();
            row.put("team_id", r.getTeamId());
            row.put("team_name", teamRepository.findById(r.getTeamId()).map(com.example.teams.Team::getName).orElse("Team " + r.getTeamId()));
            row.put("checked_in", r.isCheckedIn());
            row.put("registered_at", r.getCreatedAt() != null ? r.getCreatedAt().toString() : null);
            out.add(row);
        }
        return ResponseEntity.ok(out);
    }

    @PatchMapping("/by-team/{teamId}")
    public ResponseEntity<?> setAttendance(@PathVariable Long tournamentId,
                                           @PathVariable Long teamId,
                                           @RequestParam("requesting_user_id") Long requestingUserId,
                                           @RequestBody Map<String, Object> body) {
        String role = userRepository.findById(requestingUserId).map(User::getRole).orElse("USER");
        if (!"ADMIN".equalsIgnoreCase(role)) {
            return ResponseEntity.status(403).body(Map.of("message", "Only admins can update attendance"));
        }
        TournamentRegistration reg = registrationRepository.findByTournamentIdAndTeamId(tournamentId, teamId)
                .orElse(null);
        if (reg == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Registration not found"));
        }
        Object ci = body.get("checked_in");
        boolean checked = false;
        if (ci instanceof Boolean) checked = (Boolean) ci;
        else if (ci instanceof String) checked = Boolean.parseBoolean((String) ci);
        reg.setCheckedIn(checked);
        registrationRepository.save(reg);

        // If marked absent, enforce immediately; if marked present, leave bracket as-is
        if (!checked) {
            bracketService.enforceAttendance(tournamentId);
        }
        return ResponseEntity.ok(Map.of(
                "team_id", reg.getTeamId(),
                "checked_in", reg.isCheckedIn()
        ));
    }

    @PostMapping("/enforce")
    public ResponseEntity<?> enforce(@PathVariable Long tournamentId,
                                     @RequestParam("requesting_user_id") Long requestingUserId) {
        String role = userRepository.findById(requestingUserId).map(User::getRole).orElse("USER");
        if (!"ADMIN".equalsIgnoreCase(role)) {
            return ResponseEntity.status(403).body(Map.of("message", "Only admins can enforce attendance"));
        }
        try {
            List<TournamentMatch> updated = bracketService.enforceAttendance(tournamentId);
            return ResponseEntity.ok(updated);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }
}


