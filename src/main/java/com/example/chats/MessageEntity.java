package com.example.chats;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import com.fasterxml.jackson.annotation.JsonProperty;

@Entity
@Table(name = "chats")
public class MessageEntity {
    @Id
    @SequenceGenerator(
        name = "chat_sequence",
        sequenceName = "chat_sequence",
        allocationSize = 1
    )
    @GeneratedValue(
        strategy = GenerationType.SEQUENCE,
        generator = "chat_sequence"
    )
    @jakarta.persistence.Column(name = "chat_id")
    @JsonProperty("id")
    private Integer id;
    
    @JsonProperty("locationId")
    private int locationId;
    
    @JsonProperty("senderId")
    private int senderId;
    
    @JsonProperty("senderUserName")
    private String senderUserName;
    
    @JsonProperty("content")
    private String content;
    
    @JsonProperty("timestamp")
    private LocalDateTime timestamp;

    public MessageEntity() {
    }

    public MessageEntity(ChatMessage message) {
        this.id = message.getId();
        this.locationId = message.getLocationId();
        this.senderId = message.getSenderId();
        this.content = message.getContent();
        this.senderUserName = message.getSenderUserName();
        this.timestamp = message.getTimestamp();
    }

    public Integer getId() {
        return id;
    }

    @JsonProperty("locationId")
    public int getLocationId() {
        return locationId;
    }

    @JsonProperty("senderId")
    public int getSenderId() {
        return senderId;
    }

    @JsonProperty("content")
    public String getContent() {
        return content;
    }

    @JsonProperty("senderUserName")
    public String getSenderUserName() {
        return senderUserName;
    }

    @JsonProperty("timestamp")
    public LocalDateTime getTimestamp() {
        return timestamp;
    }
    
    public void setId(Integer id) {
        this.id = id;
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

    public void setSenderUserName(String userName) {
        this.senderUserName = userName;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }

    @Override
    public String toString() {
        return "MessageEntity{" +
               "id='" + id + '\'' +
               ", sender='" + senderId + '\'' +
               ", content='" + content + '\'' +
               ", locationId='" + locationId + '\'' +
               ", senderUserName='" + senderUserName + '\'' +
               ", timestamp=" + timestamp +
               '}';
    }
}

