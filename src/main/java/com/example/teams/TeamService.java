package com.example.teams;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import com.example.activities.ActivityService;
import com.example.users.UserService;

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
    private UserService userService;

    public List<Team> getTeamsForUser(Long userId) {
        return teamRepository.findAllForUser(userId);
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
        TeamInvite invite = new TeamInvite();
        invite.setTeamId(teamId);
        invite.setInviteeUserId(inviteeUserId);
        invite.setStatus("PENDING");
        return teamInviteRepository.save(invite);
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
        invite.setStatus(accept ? "ACCEPTED" : "DECLINED");
        invite = teamInviteRepository.save(invite);
        if (accept) {
            TeamMember member = new TeamMember();
            member.setTeamId(invite.getTeamId());
            member.setUserId(invite.getInviteeUserId());
            member.setRole("PLAYER");
            teamMemberRepository.save(member);

            // Activity for all team members about new member
            Team team = teamRepository.findById(invite.getTeamId()).orElse(null);
            String teamName = team != null ? team.getName() : ("Team #" + invite.getTeamId());
            String username = userService.getUsernameById(invite.getInviteeUserId());
            String message = "team: " + teamName + "\n(" + username + ") has joined the squad!";

            List<Long> allUserIds = teamMemberRepository.findUserIdsByTeamId(invite.getTeamId());
            List<Long> recipients = new java.util.ArrayList<>(allUserIds);
            // Do not notify the user who just joined
            recipients.remove(invite.getInviteeUserId());
            activityService.createActivityForUsers(recipients, "MEMBER_JOINED", message);
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
        List<Long> userIds = teamMemberRepository.findUserIdsByTeamId(teamId);
        activityService.createActivityForUsers(userIds, "MEMBER_LEFT", "A member left your team");
    }

    public void deleteTeam(Long teamId, Long requestingUserId) {
        Team team = teamRepository.findById(teamId).orElseThrow(() -> new IllegalStateException("Team not found"));
        if (!team.getOwnerUserId().equals(requestingUserId)) {
            throw new IllegalStateException("Only captain can delete team");
        }
        List<Long> userIds = teamMemberRepository.findUserIdsByTeamId(teamId);
        teamMemberRepository.deleteAll(teamMemberRepository.findByTeamId(teamId));
        teamRepository.delete(team);
        activityService.createActivityForUsers(userIds, "TEAM_DELETED", "Your team was deleted by the captain");
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
}


