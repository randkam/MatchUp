package com.example.teams;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TeamMemberRepository extends JpaRepository<TeamMember, Long> {
    List<TeamMember> findByTeamId(Long teamId);

    @Query("SELECT tm.id as id, tm.teamId as teamId, tm.userId as userId, tm.role as role, CAST(tm.joinedAt as string) as joinedAt, COALESCE(u.userNickName, u.userName) as username FROM TeamMember tm JOIN com.example.users.User u ON u.userId = tm.userId WHERE tm.teamId = :teamId")
    List<TeamMemberProjection> findExpandedByTeamId(Long teamId);
}


