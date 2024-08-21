// package com.example.chats;
// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.messaging.handler.annotation.MessageMapping;
// import org.springframework.messaging.handler.annotation.SendTo;
// import org.springframework.stereotype.Controller;

// @Controller
// public class ChatController {

//     @Autowired
//     private ChatService chatService;

//     @MessageMapping("/chat.sendMessage")
//     @SendTo("/topic/location")
//     public ChatMessage sendMessage(ChatMessage chatMessage) {
//         // Save the chat message to the database
//         return chatService.save(chatMessage);
//     }
// }
