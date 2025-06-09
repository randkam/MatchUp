package com.example.chats;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class ChatService {

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    public ChatMessage save(ChatMessage message) {
        MessageEntity messageEntity = new MessageEntity();
        messageEntity.setLocationId(message.getLocationId());
        messageEntity.setContent(message.getContent());
        messageEntity.setSenderId(message.getSenderId());
        messageEntity.setSenderUserName(message.getSenderUserName());
        messageEntity.setTimestamp(LocalDateTime.now());
        chatMessageRepository.save(messageEntity);
        message.setTimestamp(messageEntity.getTimestamp());
        return message;
    }

    public List<MessageEntity> getMessageById(Long locationId){
        return chatMessageRepository.findByLocationId(locationId);

    }
    // public List<ChatMessageDTO> getMessagesWithUserDetailsForLocation(Long locationId) {
    //     return chatMessageRepository.findMessagesWithUserDetailsByLocationId(locationId);
    // }
}