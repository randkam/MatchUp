package com.example.tournaments;

import com.example.users.User;
import com.example.users.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/tournaments")
public class TournamentController {

    @Autowired
    private TournamentService tournamentService;

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/upcoming")
    public ResponseEntity<Page<Tournament>> getUpcoming(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") Integer size,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String direction
    ) {
        Page<Tournament> tournaments = tournamentService.getUpcomingTournaments(page, size, sortBy, direction);
        return ResponseEntity.ok(tournaments);
    }

    @GetMapping("/live")
    public ResponseEntity<Page<Tournament>> getLive(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") Integer size,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String direction
    ) {
        Page<Tournament> tournaments = tournamentService.getLiveTournaments(page, size, sortBy, direction);
        return ResponseEntity.ok(tournaments);
    }

    @GetMapping("/past")
    public ResponseEntity<Page<Tournament>> getPast(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") Integer size,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String direction
    ) {
        Page<Tournament> tournaments = tournamentService.getPastTournaments(page, size, sortBy, direction);
        return ResponseEntity.ok(tournaments);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Tournament> getById(@PathVariable Long id) {
        return tournamentService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody Map<String, Object> body) {
        // Required fields: name, format_size, max_teams, starts_at, location, prize_cents, requesting_user_id
        String name = (String) body.get("name");
        Number formatSizeNum = (Number) body.get("format_size");
        Number maxTeamsNum = (Number) body.get("max_teams");
        String startsAtStr = (String) body.get("starts_at");
        String location = (String) body.get("location");
        Number prizeCentsNum = (Number) body.get("prize_cents");
        Number requestingUserIdNum = (Number) body.get("requesting_user_id");

        if (name == null || name.isBlank() || formatSizeNum == null || maxTeamsNum == null ||
                startsAtStr == null || startsAtStr.isBlank() || location == null || location.isBlank() ||
                prizeCentsNum == null || requestingUserIdNum == null) {
            Map<String, String> error = new HashMap<>();
            error.put("message", "Missing required fields: name, format_size, max_teams, starts_at, location, prize_cents, requesting_user_id");
            return ResponseEntity.badRequest().body(error);
        }

        // Admin check
        Long reqUserId = requestingUserIdNum.longValue();
        User requestingUser = userRepository.findById(reqUserId).orElse(null);
        if (requestingUser == null || requestingUser.getRole() == null || !"ADMIN".equalsIgnoreCase(requestingUser.getRole())) {
            Map<String, String> error = new HashMap<>();
            error.put("message", "Only admin users can create tournaments");
            return ResponseEntity.status(403).body(error);
        }

        // Parse starts_at
        LocalDateTime startsAt;
        try {
            // Try ISO with or without fraction
            try {
                startsAt = LocalDateTime.parse(startsAtStr, DateTimeFormatter.ISO_DATE_TIME);
            } catch (Exception ex) {
                DateTimeFormatter df = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");
                startsAt = LocalDateTime.parse(startsAtStr, df);
            }
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("message", "Invalid starts_at format. Use ISO-8601, e.g. 2025-01-31T18:00:00");
            return ResponseEntity.badRequest().body(error);
        }

        Tournament t = new Tournament();
        t.setName(name.trim());
        t.setFormatSize(formatSizeNum.intValue());
        t.setMaxTeams(maxTeamsNum.intValue());
        t.setStartsAt(startsAt);
        t.setSignupDeadline(startsAt.minusHours(24));
        t.setLocation(location.trim());
        t.setPrizeCents(prizeCentsNum.intValue());
        t.setStatus(TournamentStatus.SIGNUPS_OPEN);
        t.setCreatedBy(reqUserId);
        t.setEndsAt(null);

        Tournament saved = tournamentService.save(t);
        return ResponseEntity.created(URI.create("/api/v1/tournaments/" + saved.getId())).body(saved);
    }
}

