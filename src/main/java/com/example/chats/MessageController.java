package com.example.chats;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/messages")
public class MessageController {

    @Autowired
    private ChatService chatService;

    @GetMapping("/{locationId}")
    public List<ChatMessage> getMessagesByLocation(@PathVariable Long locationId) {
        List<MessageEntity> entities = chatService.getMessageById(locationId);
        return entities.stream()
                .map(ChatMessage::new)
                .collect(Collectors.toList());
    }
}

