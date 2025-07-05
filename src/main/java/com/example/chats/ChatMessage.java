package com.example.chats;

import java.time.LocalDateTime;

public class ChatMessage {
    private int locationId;
    private int senderId;
    private String content;
    private String senderUserName;
    private LocalDateTime timestamp;
    private Integer id;

    public ChatMessage() {
    }

    public ChatMessage(MessageEntity entity) {
        this.id = entity.getChatId();
        this.locationId = entity.getLocationId();
        this.senderId = entity.getSenderId();
        this.content = entity.getContent();
        this.senderUserName = entity.getSenderUserName();
        this.timestamp = entity.getTimestamp();
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public int getLocationId() {
        return locationId;
    }

    public int getSenderId() {
        return senderId;
    }

    public String getContent() {
        return content;
    }

    public String getSenderUserName() {
        return senderUserName;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setLocationId(int locationId) {
        this.locationId = locationId;
    }

    public void setSenderId(int senderId) {
        this.senderId = senderId;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }

    public void setSenderUserName(String userName) {
        this.senderUserName = userName;
    }

    @Override
    public String toString() {
        return "ChatMessage{" +
               "id='" + id + '\'' +
               ", sender='" + senderId + '\'' +
               ", content='" + content + '\'' +
               ", locationId='" + locationId + '\'' +
               ", senderUserName='" + senderUserName + '\'' +
               ", timestamp=" + timestamp +
               '}';
    }
}

