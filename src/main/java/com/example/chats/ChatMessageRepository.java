package com.example.chats;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<MessageEntity, Long> {
    List<MessageEntity> findByLocationId(Long locationId);
}

