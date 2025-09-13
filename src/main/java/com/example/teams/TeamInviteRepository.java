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

    @Query("SELECT ti.id as id, ti.teamId as teamId, ti.inviteeUserId as inviteeUserId, ti.status as status, ti.token as token, CAST(ti.expiresAt as string) as expiresAt, CAST(ti.createdAt as string) as createdAt, t.name as teamName FROM TeamInvite ti JOIN Team t ON t.id = ti.teamId WHERE ti.inviteeUserId = :userId AND ti.status = 'PENDING'")
    List<TeamInviteProjection> findPendingInvitesExpanded(Long userId);
}


