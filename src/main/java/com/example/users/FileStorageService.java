package com.example.users;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;

@Service
public class FileStorageService {

    private final Path fileStorageLocation;
    private final String baseUrl;

    public FileStorageService(
            @Value("${app.file.upload-dir}") String uploadDir,
            @Value("${app.base-url}") String baseUrl) {
        this.fileStorageLocation = Paths.get(uploadDir)
                .toAbsolutePath().normalize();
        this.baseUrl = baseUrl;

        try {
            Files.createDirectories(this.fileStorageLocation);
        } catch (Exception ex) {
            throw new RuntimeException("Could not create the directory where the uploaded files will be stored.", ex);
        }
    }

    public String storeFile(MultipartFile file, Long userId) {
        try {
            String fileName = userId + "_" + System.currentTimeMillis() + "_profile.jpg";
            Path targetLocation = this.fileStorageLocation.resolve(fileName);
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);

            // Return the full URL
            return baseUrl + "/api/v1/users/profile-picture/" + fileName;
        } catch (IOException ex) {
            throw new RuntimeException("Could not store file. Please try again!", ex);
        }
    }

    public Path getFilePath(String fileName) {
        return fileStorageLocation.resolve(fileName).normalize();
    }
} 