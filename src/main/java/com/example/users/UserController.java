package com.example.users;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.nio.file.Path;
import java.util.List;

@RestController
@RequestMapping(path = "api/v1/users")
public class UserController {
    private final UserService userService;
    private final FileStorageService fileStorageService;
    
    @Autowired
    public UserController(UserService userService, FileStorageService fileStorageService) {
        this.userService = userService;
        this.fileStorageService = fileStorageService;
    }

    @GetMapping
	public List<User> getUsers(){
       return userService.getUsers();

	}

    @GetMapping(path = "{email}")
    public User getUser(@PathVariable("email") String userEmail) {
    return userService.getUser(userEmail);
    }

    @PostMapping
    public void registerNewUser( @RequestBody  User user){
        user.setPassword(user.getUserPassword());
        userService.addNewUser(user);
            
    }

    @DeleteMapping(path =  "{userId}")
    public void deleteUser(@PathVariable("userId") Long userId){
        userService.deleteUser(userId);
    }

    @PutMapping(path = "{userId}")
    public void updateUser(@PathVariable("userId") long userId, @RequestParam(required = false) String userName,@RequestParam(required = false) String userEmail,@RequestParam(required = false) String userNickName,@RequestParam(required = false) String userPassword){
        userService.updateUser(userId, userName, userEmail, userNickName, userPassword);
    }

    @PutMapping(path = "{userId}/location")
    public ResponseEntity<String> updateUserLocation(
            @PathVariable("userId") Long userId,
            @RequestParam("latitude") Double latitude,
            @RequestParam("longitude") Double longitude) {
        try {
            userService.updateUserLocation(userId, longitude, latitude);
            return ResponseEntity.ok().build();
        } catch (IllegalStateException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping("/{userId}/profile-picture")
    public ResponseEntity<String> uploadProfilePicture(
            @PathVariable Long userId,
            @RequestParam("file") MultipartFile file) {
        
        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body("Please select a file to upload");
        }

        try {
            String fileUrl = fileStorageService.storeFile(file, userId);
            System.out.println("Generated file URL: " + fileUrl);
            userService.updateProfilePicture(userId, fileUrl);
            
            // Verify the update
            User user = userService.getUserById(userId);
            System.out.println("Updated user profile picture URL: " + user.getProfilePictureUrl());
            
            // Return the URL as plain text
            return ResponseEntity
                .ok()
                .contentType(MediaType.TEXT_PLAIN)
                .body(fileUrl);
        } catch (Exception e) {
            System.err.println("Error uploading profile picture: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError().body("Could not upload file: " + e.getMessage());
        }
    }

    @GetMapping("/profile-picture/{fileName:.+}")
    public ResponseEntity<Resource> getProfilePicture(@PathVariable String fileName) {
        try {
            Path filePath = fileStorageService.getFilePath(fileName);
            Resource resource = new UrlResource(filePath.toUri());

            if (resource.exists()) {
                return ResponseEntity.ok()
                        .contentType(MediaType.IMAGE_JPEG)
                        .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + resource.getFilename() + "\"")
                        .body(resource);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }
} 
    