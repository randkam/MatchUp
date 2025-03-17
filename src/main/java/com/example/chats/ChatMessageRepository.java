package com.example.chats;

import org.springframework.data.jpa.repository.JpaRepository;
// import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<MessageEntity, Long> {

    // @Query("SELECT new com.example.chats.ChatMessageDTO(m, u) " +
    //        "FROM MessageEntity m JOIN com.example.users.User u ON m.senderId = u.userId " +
    //        "WHERE m.locationId = :locationId")
    // List<ChatMessageDTO> findMessagesWithUserDetailsByLocationId(Long locationId);
    List<MessageEntity> findByLocationId(Long locationId);

}

