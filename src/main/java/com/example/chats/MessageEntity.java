package com.example.chats;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;

// import java.time.LocalDateTime;

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
    private int chatId;
    private int locationId;
    private int senderId;
    private String content;
    // private LocalDateTime timestamp;
    public int getLocationId() {
        return locationId;
    }
    public int getSenderId() {
        return senderId;
    }
    public String getContent() {
        return content;
    }
    public int getChatId() {
        return chatId;
    }

    // public LocalDateTime getTimestamp() {
    //     return timestamp;
    // }
    public void setChatId(int chatId) {
        this.chatId = chatId;
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
    // public void setTimestamp(LocalDateTime timestamp) {
    //     this.timestamp = timestamp;
    // }

    @Override
    public String toString() {
        return "MessageEntity{" +
               "sender='" + senderId + '\'' +
               ", content='" + content + '\'' +
               ", locationId='" + locationId + '\'' +
               '}';
    }

}

