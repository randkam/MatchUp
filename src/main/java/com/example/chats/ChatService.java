// package com.example.chats;

// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.stereotype.Service;

// import java.util.List;

// @Service
// public class ChatService {

//     @Autowired
//     private ChatMessageRepository chatMessageRepository;

//     public ChatMessage save(ChatMessage chatMessage) {
//         return chatMessageRepository.save(chatMessage);
//     }

//     public List<ChatMessage> getMessagesForLocation(Long locationId) {
//         return chatMessageRepository.findByLocationId(locationId);
//     }
// }