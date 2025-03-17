// package com.example.chats;

// import com.example.users.User;

// public class ChatMessageDTO {
//     private int chatId;
//     private int locationId;
//     private int senderId;
//     private String content;
//     private String userName;
//     private String userNickName;

//     public ChatMessageDTO(MessageEntity message, User user) {
//         this.chatId = message.getChatId();
//         this.locationId = message.getLocationId();
//         this.senderId = message.getSenderId();
//         this.content = message.getContent();
//         this.userName = user.getUserName();
//         this.userNickName = user.getUserNickName();
//     }

//     // Getters
//     public int getChatId() {
//         return chatId;
//     }

//     public int getLocationId() {
//         return locationId;
//     }

//     public int getSenderId() {
//         return senderId;
//     }

//     public String getContent() {
//         return content;
//     }

//     public String getUserName() {
//         return userName;
//     }

//     public String getUserNickName() {
//         return userNickName;
//     }



//     // Setters
//     public void setChatId(int chatId) {
//         this.chatId = chatId;
//     }

//     public void setLocationId(int locationId) {
//         this.locationId = locationId;
//     }

//     public void setSenderId(int senderId) {
//         this.senderId = senderId;
//     }

//     public void setContent(String content) {
//         this.content = content;
//     }

//     public void setUserName(String userName) {
//         this.userName = userName;
//     }

//     public void setUserNickName(String userNickName) {
//         this.userNickName = userNickName;
//     }

    
// } 