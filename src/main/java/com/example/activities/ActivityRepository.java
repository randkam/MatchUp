package com.example.activities;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ActivityRepository extends JpaRepository<Activity, Long> {
    @Query(value = "SELECT a.id AS id, at.code AS typeCode, COALESCE(a.team_id, CAST(JSON_UNQUOTE(JSON_EXTRACT(a.payload, '$.team_id')) AS UNSIGNED)) AS teamId, a.tournament_id AS tournamentId, a.actor_user_id AS actorUserId, u.user_name AS actorUsername, COALESCE(NULLIF(a.team_name_snapshot, ''), NULLIF(JSON_UNQUOTE(JSON_EXTRACT(a.payload, '$.team_name')), ''), t.name) AS teamName, trn.name AS tournamentName, at.description AS message, DATE_FORMAT(a.created_at, '%Y-%m-%dT%T.%fZ') AS createdAt FROM activities a JOIN activity_types at ON at.id = a.type_id LEFT JOIN teams t ON a.team_id = t.id LEFT JOIN tournaments trn ON trn.id = a.tournament_id LEFT JOIN users u ON u.user_id = a.actor_user_id WHERE (EXISTS (SELECT 1 FROM team_members tm WHERE tm.team_id = COALESCE(a.team_id, CAST(JSON_UNQUOTE(JSON_EXTRACT(a.payload, '$.team_id')) AS UNSIGNED)) AND tm.user_id = :userId) OR a.actor_user_id = :userId) ORDER BY a.created_at DESC LIMIT 50", nativeQuery = true)
    List<Object[]> findFeedForUser(@Param("userId") Long userId);

    boolean existsByDedupeKey(String dedupeKey);
}


