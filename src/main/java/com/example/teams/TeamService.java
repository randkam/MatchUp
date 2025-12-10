package com.example.teams;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import com.example.activities.ActivityService;
import com.example.tournaments.Tournament;
import com.example.tournaments.TournamentRepository;
import com.example.tournaments.TournamentRegistrationRepository;
import com.example.tournaments.TournamentStatus;

@Service
public class TeamService {

    @Autowired
    private TeamRepository teamRepository;
    @Autowired
    private TeamMemberRepository teamMemberRepository;
    @Autowired
    private TeamInviteRepository teamInviteRepository;
    @Autowired
    private ActivityService activityService;
    @Autowired
    private TournamentRegistrationRepository tournamentRegistrationRepository;
    @Autowired
    private TournamentRepository tournamentRepository;
    // userService no longer needed for activity messages

    public List<Team> getTeamsForUser(Long userId) {
        return teamRepository.findAllForUser(userId);
    }

    public Team getTeamById(Long teamId) {
        return teamRepository.findById(teamId)
                .orElseThrow(() -> new IllegalStateException("Team not found"));
    }

    public Team createTeam(String name, Long ownerUserId, String logoUrl) {
        Team t = new Team();
        t.setName(name);
        t.setSport("basketball");
        t.setOwnerUserId(ownerUserId);
        t.setLogoUrl(logoUrl);
        Team saved = teamRepository.save(t);
        // Add creator as CAPTAIN
        TeamMember captain = new TeamMember();
        captain.setTeamId(saved.getId());
        captain.setUserId(ownerUserId);
        captain.setRole("CAPTAIN");
        teamMemberRepository.save(captain);
        return saved;
    }

    public List<TeamMember> getMembers(Long teamId) {
        return teamMemberRepository.findByTeamId(teamId);
    }

    public List<Map<String, Object>> getMembersWithUsernames(Long teamId) {
        List<TeamMemberProjection> mems = teamMemberRepository.findExpandedByTeamId(teamId);
        List<Map<String, Object>> out = new java.util.ArrayList<>();
        for (TeamMemberProjection m : mems) {
            Map<String, Object> row = new java.util.HashMap<>();
            row.put("id", m.getId());
            row.put("team_id", m.getTeamId());
            row.put("user_id", m.getUserId());
            row.put("role", m.getRole());
            row.put("joined_at", m.getJoinedAt());
            row.put("username", m.getUsername());
            out.add(row);
        }
        return out;
    }

    public TeamInvite inviteUserToTeam(Long teamId, Long inviteeUserId) {
        // If user is already a member, block inviting
        if (teamMemberRepository.existsByTeamIdAndUserId(teamId, inviteeUserId)) {
            throw new IllegalStateException("User is already a team member");
        }
        // Prevent inviting a user who is already participating in any tournament this team is registered in
        validateUserNotAlreadyInRegisteredTournament(teamId, inviteeUserId);
        // If an invite already exists for this team/user, reuse or reset it instead of violating unique constraints
        java.util.Optional<TeamInvite> existingOpt = teamInviteRepository.findByTeamIdAndInviteeUserId(teamId, inviteeUserId);
        if (existingOpt.isPresent()) {
            TeamInvite existing = existingOpt.get();
            // Regardless of prior status (ACCEPTED/DECLINED/PENDING/EXPIRED), reset to PENDING and extend expiry.
            existing.setStatus("PENDING");
            existing.setExpiresAt(java.time.LocalDateTime.now().plusDays(7));
            return teamInviteRepository.save(existing);
        }
        TeamInvite invite = new TeamInvite();
        invite.setTeamId(teamId);
        invite.setInviteeUserId(inviteeUserId);
        invite.setStatus("PENDING");
        try {
            return teamInviteRepository.save(invite);
        } catch (org.springframework.dao.DataIntegrityViolationException ex) {
            // In case of race conditions or lingering unique row, reset existing invite
            TeamInvite existing = teamInviteRepository.findByTeamIdAndInviteeUserId(teamId, inviteeUserId)
                    .orElseThrow(() -> ex);
            existing.setStatus("PENDING");
            existing.setExpiresAt(java.time.LocalDateTime.now().plusDays(7));
            return teamInviteRepository.save(existing);
        }
    }

    public List<Map<String, Object>> getPendingInvitesForUserExpanded(Long userId) {
        List<TeamInviteProjection> list = teamInviteRepository.findPendingInvitesExpanded(userId);
        List<Map<String, Object>> out = new java.util.ArrayList<>();
        for (TeamInviteProjection p : list) {
            Map<String, Object> row = new java.util.HashMap<>();
            row.put("id", p.getId());
            row.put("team_id", p.getTeamId());
            row.put("invitee_user_id", p.getInviteeUserId());
            row.put("status", p.getStatus());
            row.put("token", p.getToken());
            row.put("expires_at", p.getExpiresAt());
            row.put("created_at", p.getCreatedAt());
            row.put("team_name", p.getTeamName());
            out.add(row);
        }
        return out;
    }

    public TeamInvite respondToInvite(Long inviteId, boolean accept) {
        TeamInvite invite = teamInviteRepository.findById(inviteId)
                .orElseThrow(() -> new IllegalStateException("Invite not found"));
        if (!"PENDING".equals(invite.getStatus())) {
            return invite;
        }
        // If accepting, ensure the user isn't already on another team registered in any same tournament(s)
        if (accept) {
            // Block accepting invites while the team is in a live tournament
            boolean teamInLiveTournament = tournamentRegistrationRepository.teamHasLiveTournament(invite.getTeamId());
            if (teamInLiveTournament) {
                throw new IllegalStateException("Cannot accept invite while this team is in a live tournament. Try again after it ends.");
            }
            validateUserNotAlreadyInRegisteredTournament(invite.getTeamId(), invite.getInviteeUserId());
        }
        invite.setStatus(accept ? "ACCEPTED" : "DECLINED");
        invite = teamInviteRepository.save(invite);
        if (accept) {
            TeamMember member = new TeamMember();
            member.setTeamId(invite.getTeamId());
            member.setUserId(invite.getInviteeUserId());
            member.setRole("PLAYER");
            teamMemberRepository.save(member);

            // Activity for all team members about new member
            String teamName = teamRepository.findById(invite.getTeamId()).map(Team::getName).orElse(null);
            activityService.createTeamEvent("TEAM_MEMBER_ADDED", invite.getTeamId(), invite.getInviteeUserId(), teamName, null, null);
        }
        return invite;
    }

    public void leaveTeam(Long teamId, Long userId) {
        List<TeamMember> members = teamMemberRepository.findByTeamId(teamId);
        TeamMember target = null;
        for (TeamMember m : members) {
            if (m.getUserId().equals(userId)) { target = m; break; }
        }
        if (target == null) throw new IllegalStateException("Not a team member");
        if ("CAPTAIN".equals(target.getRole())) {
            throw new IllegalStateException("Captain cannot leave; delete team instead");
        }
        teamMemberRepository.delete(target);
        String teamName = teamRepository.findById(teamId).map(Team::getName).orElse(null);
        activityService.createTeamEvent("TEAM_MEMBER_LEFT", teamId, userId, teamName, null, null);
    }

    public List<Team> listAllTeams() {
        return teamRepository.findAll();
    }

    @Transactional
    public void deleteTeam(Long teamId, Long requestingUserId) {
        Team team = teamRepository.findById(teamId).orElseThrow(() -> new IllegalStateException("Team not found"));
        if (!team.getOwnerUserId().equals(requestingUserId)) {
            throw new IllegalStateException("Only captain can delete team");
        }
        String teamName = team.getName();
        // Prevent deletion if team is registered for any upcoming tournament
        java.util.List<Tournament> upcoming = tournamentRegistrationRepository.findUpcomingTournamentsForTeam(teamId);
        if (upcoming != null && !upcoming.isEmpty()) {
            Tournament t = upcoming.get(0);
            String msg = "Cannot delete team: registered for upcoming tournament '" + t.getName() + "' (id: " + t.getId() + ")";
            throw new IllegalStateException(msg);
        }

        // Snapshot and payload before delete
        activityService.createTeamDeletedEvent(teamId, requestingUserId, teamName);
        // Capture impacted tournaments before removing registrations
        List<Tournament> impacted = tournamentRegistrationRepository.findUpcomingTournamentsForTeam(teamId);

        // Delete team
        teamRepository.delete(team);

        // Recalculate tournament status for impacted tournaments
        for (Tournament t : impacted) {
            long count = tournamentRegistrationRepository.countRegisteredByTournamentId(t.getId());
            if (t.getStatus() == TournamentStatus.FULL && count < t.getMaxTeams()) {
                t.setStatus(TournamentStatus.SIGNUPS_OPEN);
                tournamentRepository.save(t);
            }
        }
    }

    public void removeMember(Long teamId, Long targetUserId, Long requestingUserId) {
        boolean isCaptain = teamMemberRepository.isCaptain(teamId, requestingUserId);
        if (!isCaptain) {
            throw new IllegalStateException("Only captain can remove members");
        }
        // Do not allow removing captain
        boolean isTargetCaptain = teamMemberRepository.isCaptain(teamId, targetUserId);
        if (isTargetCaptain) {
            throw new IllegalStateException("Cannot remove team captain");
        }
        List<TeamMember> members = teamMemberRepository.findByTeamId(teamId);
        TeamMember target = null;
        for (TeamMember m : members) {
            if (m.getUserId().equals(targetUserId)) { target = m; break; }
        }
        if (target == null) {
            throw new IllegalStateException("User is not a member of this team");
        }
        teamMemberRepository.delete(target);
    }

    private void validateUserNotAlreadyInRegisteredTournament(Long teamId, Long userId) {
        // Consider conflicts for both upcoming and live tournaments; past tournaments are allowed
        java.util.List<com.example.tournaments.Tournament> upcoming = tournamentRegistrationRepository.findUpcomingTournamentsForTeam(teamId);
        java.util.List<com.example.tournaments.Tournament> live = tournamentRegistrationRepository.findLiveTournamentsForTeam(teamId);
        java.util.Map<Long, com.example.tournaments.Tournament> byId = new java.util.HashMap<>();
        for (com.example.tournaments.Tournament t : upcoming) { byId.put(t.getId(), t); }
        for (com.example.tournaments.Tournament t : live) { byId.put(t.getId(), t); }
        for (com.example.tournaments.Tournament t : byId.values()) {
            java.util.List<Long> userIdsAlreadyInTournament = tournamentRegistrationRepository.findAllUserIdsAlreadyInTournament(t.getId());
            if (userIdsAlreadyInTournament.contains(userId)) {
                String msg = "User is already on another team registered for an upcoming or live tournament '" + t.getName() + "' (id: " + t.getId() + ")";
                throw new InviteConflictException(t.getId(), t.getName(), msg);
            }
        }
    }
}


