package com.example.users;
// import java.security.NoSuchAlgorithmException;
// import java.security.MessageDigest;


import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;

@Entity
@Table(name ="users")
public class User {

    @Id
    @SequenceGenerator(
        name = "user_sequence",
        sequenceName = "user_sequence",
        allocationSize = 1
    )

    @GeneratedValue(
        strategy = GenerationType.SEQUENCE,
        generator = "user_sequence"
    )

    private Long userId;
    private String userName;
    private String userNickName;
    private String userEmail;
    private String userPassword;
    private String userPosition;
    private String userRegion;
    private String profilePictureUrl;


    

    public User() {
    }



    // private String hashPassword(String userPassword) {
    // try {
    //     MessageDigest digest = MessageDigest.getInstance("SHA-256");
    //     byte[] hash = digest.digest(userPassword.getBytes());
    //     StringBuilder hexString = new StringBuilder(2 * hash.length);
    //     for (byte b : hash) {
    //         String hex = Integer.toHexString(0xff & b);
    //         if (hex.length() == 1) {
    //             hexString.append('0');
    //         }
    //         hexString.append(hex);
    //     }
    //     return hexString.toString();
    // } catch (NoSuchAlgorithmException e) {
    //     throw new RuntimeException("Error hashing password", e);
    //     }
    // }

    public User(Long userId, String userName, String userNickName, String userEmail, String userPassword, String userPosition, String userRegion) {
        this.userId = userId;
        this.userName = userName;
        this.userNickName = userNickName;
        this.userEmail = userEmail;
        this.userPassword = userPassword;
        this.userPosition = userPosition;
        this.userRegion = userRegion;
        this.profilePictureUrl = null;
        // this.userPassword = hashPassword(userPassword);
        // System.out.println(userPassword);
    }



    public User(String userName, String userNickName, String userEmail, String userPassword, String userPosition, String userRegion) {
        this.userName = userName;
        this.userNickName = userNickName;
        this.userEmail = userEmail;
        this.userPassword = userPassword;
        this.userPosition = userPosition;
        this.userRegion = userRegion;
        this.profilePictureUrl = null;
        // this.userPassword = hashPassword(userPassword);
    }


    public Long getuserId() {
        return userId;
    }



    public String getUserName() {
        return userName;
    }



    public String getUserNickName() {
        return userNickName;
    }

    public String getUserPassword() {
        return userPassword;
    }



    public String getEmail() {
        return userEmail;
    }
    public String getUserPosition() {
        return userPosition;
    }

    public String getUserRegion() {
        return userRegion;
    }
    
    public void setUserPosition(String userPosition) {
        this.userPosition = userPosition;
    }
    

    
    public void setUserRegion(String userRegion) {
        this.userRegion = userRegion;
    }
    



    public void setId(Long userId) {
        this.userId = userId;
    }



    public void setUserName(String userName) {
        this.userName = userName;
    }



    public void setNickName(String userNickName) {
        this.userNickName = userNickName;
    }

    public void setPassword(String userPassword) {
        this.userPassword = userPassword;
        // this.userPassword = hashPassword(userPassword);
    }





    public void setEmail(String userEmail) {
        this.userEmail = userEmail;
    }

    public String getProfilePictureUrl() {
        return profilePictureUrl;
    }

    public void setProfilePictureUrl(String profilePictureUrl) {
        this.profilePictureUrl = profilePictureUrl;
    }

    @Override
    public String toString() {
        return "users [userId=" + userId + ", userName=" + userName + ", userNickName=" + userNickName 
            + ", userEmail=" + userEmail + ", userPassword=" + userPassword 
            + ", userPosition=" + userPosition + ", userRegion=" + userRegion 
            + ", profilePictureUrl=" + profilePictureUrl + "]";
    }
    



}
