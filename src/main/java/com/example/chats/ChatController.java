package com.example.chats;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.stereotype.Controller;
import org.springframework.messaging.simp.SimpMessagingTemplate;

@Controller
public class ChatController {

    @Autowired
    private ChatService chatService;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @MessageMapping("/chat.sendMessage/{locationId}")
    public void sendMessage(@Payload ChatMessage chatMessage, @DestinationVariable String locationId) {
        // Log and save the chat message
        System.out.println("Message received: " + chatMessage.toString());
        chatService.save(chatMessage);

        // Dynamically send the message to the topic
        messagingTemplate.convertAndSend("/topic/location/" + locationId, chatMessage);
    }
}
