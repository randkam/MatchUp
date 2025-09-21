package com.example.teams;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TeamInviteRepository extends JpaRepository<TeamInvite, Long> {
    List<TeamInvite> findByInviteeUserIdAndStatus(Long inviteeUserId, String status);
    Optional<TeamInvite> findByTeamIdAndInviteeUserId(Long teamId, Long inviteeUserId);

    // Format timestamps as ISO 8601 UTC with fractional seconds, to match activities API
    @Query(value = "SELECT ti.id AS id, ti.team_id AS teamId, ti.invitee_user_id AS inviteeUserId, ti.status AS status, ti.token AS token, DATE_FORMAT(ti.expires_at, '%Y-%m-%dT%T.%fZ') AS expiresAt, DATE_FORMAT(ti.created_at, '%Y-%m-%dT%T.%fZ') AS createdAt, t.name AS teamName FROM team_invites ti JOIN teams t ON t.id = ti.team_id WHERE ti.invitee_user_id = :userId AND ti.status = 'PENDING' ORDER BY ti.created_at DESC", nativeQuery = true)
    List<TeamInviteProjection> findPendingInvitesExpanded(Long userId);
}


