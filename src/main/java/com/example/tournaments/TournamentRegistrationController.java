package com.example.tournaments;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/tournaments")
public class TournamentRegistrationController {

    @Autowired
    private TournamentRegistrationService registrationService;

    @PostMapping("/{tournamentId}/registrations")
    public ResponseEntity<?> register(@PathVariable Long tournamentId, @RequestBody Map<String, Object> body) {
        Number teamIdNum = (Number) body.get("team_id");
        Number userIdNum = (Number) body.get("requesting_user_id");
        Object agreementsAcceptedObj = body.get("agreements_accepted");
        if (teamIdNum == null || userIdNum == null) {
            Map<String, String> error = new HashMap<>();
            error.put("message", "Missing required fields: team_id, requesting_user_id");
            return ResponseEntity.badRequest().body(error);
        }
        // Enforce agreements acceptance before allowing registration
        boolean agreementsAccepted = false;
        if (agreementsAcceptedObj instanceof Boolean) {
            agreementsAccepted = (Boolean) agreementsAcceptedObj;
        } else if (agreementsAcceptedObj instanceof String) {
            agreementsAccepted = Boolean.parseBoolean((String) agreementsAcceptedObj);
        }
        if (!agreementsAccepted) {
            Map<String, String> error = new HashMap<>();
            error.put("message", "You must agree to all policies before registering.");
            return ResponseEntity.badRequest().body(error);
        }
        try {
            TournamentRegistration created = registrationService.registerTeam(tournamentId, teamIdNum.longValue(), userIdNum.longValue());
            return ResponseEntity.created(URI.create("/api/v1/tournaments/" + tournamentId + "/registrations/" + created.getId())).body(created);
        } catch (IllegalStateException e) {
            Map<String, String> error = new HashMap<>();
            error.put("message", e.getMessage());
            return ResponseEntity.status(409).body(error);
        }
    }

    @GetMapping("/{tournamentId}/registrations")
    public ResponseEntity<List<TournamentRegistration>> list(@PathVariable Long tournamentId) {
        return ResponseEntity.ok(registrationService.listRegistrations(tournamentId));
    }

    @GetMapping("/{tournamentId}/registrations/expanded")
    public ResponseEntity<List<Map<String, Object>>> listExpanded(@PathVariable Long tournamentId) {
        return ResponseEntity.ok(registrationService.listRegistrationsExpanded(tournamentId));
    }

    // Eligibility helper endpoint (IDs of already-registered users/teams)
    @GetMapping("/{tournamentId}/eligibility")
    public ResponseEntity<Map<String, Object>> eligibility(@PathVariable Long tournamentId, @RequestParam("user_id") Long userId) {
        return ResponseEntity.ok(registrationService.getEligibility(tournamentId, userId));
    }

    @DeleteMapping("/{tournamentId}/registrations/by-team/{teamId}")
    public ResponseEntity<?> unregister(@PathVariable Long tournamentId,
                                        @PathVariable Long teamId,
                                        @RequestParam("requesting_user_id") Long requestingUserId) {
        try {
            registrationService.unregisterTeam(tournamentId, teamId, requestingUserId);
            Map<String, String> body = new HashMap<>();
            body.put("message", "Team unregistered");
            return ResponseEntity.ok(body);
        } catch (IllegalStateException e) {
            Map<String, String> error = new HashMap<>();
            error.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    // Upcoming tournaments a specific team is registered for
    @GetMapping("/teams/{teamId}/upcoming")
    public ResponseEntity<List<Tournament>> teamUpcoming(@PathVariable Long teamId) {
        return ResponseEntity.ok(registrationService.getUpcomingForTeam(teamId));
    }

    // Past tournaments a specific team participated in (startsAt before now)
    @GetMapping("/teams/{teamId}/past")
    public ResponseEntity<List<Tournament>> teamPast(@PathVariable Long teamId) {
        return ResponseEntity.ok(registrationService.getPastForTeam(teamId));
    }
}


