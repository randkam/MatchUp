package com.example.chats;

import java.util.List;

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
    public List<MessageEntity> getMessagesByLocation(@PathVariable Long locationId) {
        return chatService.getMessageById(locationId);
    }
    // public List<ChatMessageDTO> getMessagesWithUserDetailsByLocation(@PathVariable Long locationId) {
    //     return chatService.getMessagesWithUserDetailsForLocation(locationId);
    // }
}

