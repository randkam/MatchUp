package com.example.chats;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ChatService {

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    public Page<ChatMessage> getLocationMessages(int locationId, PageRequest pageRequest) {
        Page<MessageEntity> messages = chatMessageRepository.findByLocationId((long) locationId, pageRequest);
        return messages.map(ChatMessage::new);
    }

    @Transactional
    public MessageEntity saveMessage(MessageEntity message) {
        return chatMessageRepository.save(message);
    }
}