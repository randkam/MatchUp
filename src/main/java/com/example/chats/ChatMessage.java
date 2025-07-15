package com.example.chats;

import java.time.LocalDateTime;
import com.fasterxml.jackson.annotation.JsonProperty;

public class ChatMessage {
    @JsonProperty("locationId")
    private int locationId;
    @JsonProperty("senderId")
    private int senderId;
    @JsonProperty("content")
    private String content;
    @JsonProperty("senderUserName")
    private String senderUserName;
    @JsonProperty("timestamp")
    private LocalDateTime timestamp;
    @JsonProperty("id")
    private Integer id;

    public ChatMessage() {
    }

    public ChatMessage(MessageEntity entity) {
        this.id = entity.getId();
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

