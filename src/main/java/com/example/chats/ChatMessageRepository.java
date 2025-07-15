package com.example.chats;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ChatMessageRepository extends JpaRepository<MessageEntity, Long> {
    Page<MessageEntity> findByLocationId(Long locationId, Pageable pageable);
}

