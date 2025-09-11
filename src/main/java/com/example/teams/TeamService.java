package com.example.teams;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class TeamService {

    @Autowired
    private TeamRepository teamRepository;
    @Autowired
    private TeamMemberRepository teamMemberRepository;
    @Autowired
    private TeamInviteRepository teamInviteRepository;

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
        }
        return invite;
    }
}


