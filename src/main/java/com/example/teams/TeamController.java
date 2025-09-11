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
    public ResponseEntity<TeamInvite> invite(@PathVariable Long teamId, @RequestBody Map<String, Object> body) {
        Number inviteeNum = (Number) body.get("invitee_user_id");
        if (inviteeNum == null) return ResponseEntity.badRequest().build();
        TeamInvite invite = teamService.inviteUserToTeam(teamId, inviteeNum.longValue());
        return ResponseEntity.ok(invite);
    }

    @GetMapping("/invites/user/{userId}")
    public ResponseEntity<List<Map<String, Object>>> pendingInvites(@PathVariable Long userId) {
        return ResponseEntity.ok(teamService.getPendingInvitesForUserExpanded(userId));
    }

    @PostMapping("/invites/{inviteId}/respond")
    public ResponseEntity<TeamInvite> respond(@PathVariable Long inviteId, @RequestParam("accept") boolean accept) {
        return ResponseEntity.ok(teamService.respondToInvite(inviteId, accept));
    }
}


