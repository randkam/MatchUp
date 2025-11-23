package com.example.teams;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/teams")
public class TeamController {

    @Autowired
    private TeamService teamService;

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<Team>> getUserTeams(@PathVariable Long userId) {
        return ResponseEntity.ok(teamService.getTeamsForUser(userId));
    }

    @GetMapping("/{teamId}")
    public ResponseEntity<Team> getTeam(@PathVariable Long teamId) {
        try {
            return ResponseEntity.ok(teamService.getTeamById(teamId));
        } catch (IllegalStateException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping
    public ResponseEntity<Team> createTeam(@RequestBody Map<String, Object> body) {
        String name = (String) body.get("name");
        Number ownerUserIdNum = (Number) body.get("owner_user_id");
        String logoUrl = (String) body.getOrDefault("logo_url", "NA");
        if (name == null || ownerUserIdNum == null) {
            Map<String, String> error = new HashMap<>();
            error.put("message", "Missing required fields: name, owner_user_id");
            return ResponseEntity.badRequest().build();
        }
        Long ownerUserId = ownerUserIdNum.longValue();
        Team created = teamService.createTeam(name, ownerUserId, logoUrl);
        return ResponseEntity.created(URI.create("/api/v1/teams/" + created.getId())).body(created);
    }

    @GetMapping("/{teamId}/members")
    public ResponseEntity<List<TeamMember>> getMembers(@PathVariable Long teamId) {
        return ResponseEntity.ok(teamService.getMembers(teamId));
    }

    @GetMapping("/{teamId}/members/expanded")
    public ResponseEntity<List<Map<String, Object>>> getMembersExpanded(@PathVariable Long teamId) {
        return ResponseEntity.ok(teamService.getMembersWithUsernames(teamId));
    }

    @PostMapping("/{teamId}/invites")
    public ResponseEntity<?> invite(@PathVariable Long teamId, @RequestBody Map<String, Object> body) {
        Number inviteeNum = (Number) body.get("invitee_user_id");
        if (inviteeNum == null) return ResponseEntity.badRequest().build();
        try {
            TeamInvite invite = teamService.inviteUserToTeam(teamId, inviteeNum.longValue());
            return ResponseEntity.ok(invite);
        } catch (InviteConflictException ice) {
            Map<String, Object> error = new HashMap<>();
            error.put("message", ice.getMessage());
            error.put("tournament_id", ice.getTournamentId());
            error.put("tournament_name", ice.getTournamentName());
            error.put("code", "INVITE_CONFLICT");
            return ResponseEntity.badRequest().body(error);
        } catch (IllegalStateException e) {
            Map<String, String> error = new HashMap<>();
            error.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @GetMapping("/invites/user/{userId}")
    public ResponseEntity<List<Map<String, Object>>> pendingInvites(@PathVariable Long userId) {
        return ResponseEntity.ok(teamService.getPendingInvitesForUserExpanded(userId));
    }

    @PostMapping("/invites/{inviteId}/respond")
    public ResponseEntity<?> respond(@PathVariable Long inviteId, @RequestParam("accept") boolean accept) {
        try {
            return ResponseEntity.ok(teamService.respondToInvite(inviteId, accept));
        } catch (IllegalStateException e) {
            Map<String, String> error = new HashMap<>();
            error.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PostMapping("/{teamId}/leave")
    public ResponseEntity<Map<String, String>> leave(@PathVariable Long teamId, @RequestParam("user_id") Long userId) {
        Map<String, String> body = new HashMap<>();
        try {
            teamService.leaveTeam(teamId, userId);
            body.put("message", "Left team");
            return ResponseEntity.ok(body);
        } catch (IllegalStateException e) {
            body.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(body);
        }
    }

    @DeleteMapping("/{teamId}")
    public ResponseEntity<Map<String, String>> delete(@PathVariable Long teamId, @RequestParam("requesting_user_id") Long requestingUserId) {
        Map<String, String> body = new HashMap<>();
        try {
            teamService.deleteTeam(teamId, requestingUserId);
            body.put("message", "Team deleted");
            return ResponseEntity.ok(body);
        } catch (IllegalStateException e) {
            body.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(body);
        }
    }

    @PostMapping("/{teamId}/remove")
    public ResponseEntity<Map<String, String>> removeMember(@PathVariable Long teamId,
                                                            @RequestParam("target_user_id") Long targetUserId,
                                                            @RequestParam("requesting_user_id") Long requestingUserId) {
        Map<String, String> body = new HashMap<>();
        try {
            teamService.removeMember(teamId, targetUserId, requestingUserId);
            body.put("message", "Member removed");
            return ResponseEntity.ok(body);
        } catch (IllegalStateException e) {
            body.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(body);
        }
    }
}


