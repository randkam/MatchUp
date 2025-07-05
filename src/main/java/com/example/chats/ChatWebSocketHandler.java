package com.example.chats;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import org.springframework.web.socket.CloseStatus;

import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.time.LocalDateTime;

@Component
public class ChatWebSocketHandler extends TextWebSocketHandler {

    // Map of locationId to Set of sessions for that location
    private static final Map<Integer, Set<WebSocketSession>> locationRooms = new HashMap<>();
    private final ObjectMapper objectMapper;
    
    @Autowired
    private ChatService chatService;

    public ChatWebSocketHandler() {
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule());
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        // Location ID will be passed as a URL parameter
        String locationId = session.getUri().getQuery().split("=")[1];
        session.getAttributes().put("locationId", Integer.parseInt(locationId));
        
        // Add session to location room
        locationRooms.computeIfAbsent(Integer.parseInt(locationId), 
            k -> Collections.synchronizedSet(new HashSet<>()))
            .add(session);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        // Parse the incoming message
        ChatMessage chatMessage = objectMapper.readValue(message.getPayload(), ChatMessage.class);
        
        // Set timestamp if not present
        if (chatMessage.getTimestamp() == null) {
            chatMessage.setTimestamp(LocalDateTime.now());
        }
        
        // Save to database
        ChatMessage savedMessage = chatService.save(chatMessage);

        // Convert saved message to JSON and broadcast
        String jsonMessage = objectMapper.writeValueAsString(savedMessage);
        TextMessage outMessage = new TextMessage(jsonMessage);

        // Get the location room and broadcast only to sessions in that room
        int locationId = (Integer) session.getAttributes().get("locationId");
        Set<WebSocketSession> locationSessions = locationRooms.get(locationId);
        
        if (locationSessions != null) {
            for (WebSocketSession s : locationSessions) {
                if (s.isOpen()) {
                    s.sendMessage(outMessage);
                }
            }
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        int locationId = (Integer) session.getAttributes().get("locationId");
        Set<WebSocketSession> locationSessions = locationRooms.get(locationId);
        if (locationSessions != null) {
            locationSessions.remove(session);
            // Clean up empty rooms
            if (locationSessions.isEmpty()) {
                locationRooms.remove(locationId);
            }
        }
    }
}