package com.example.locations;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
public class LocationImageStorageService {

    private final Path locationImagesRoot;
    private final String baseUrl;

    public LocationImageStorageService(
            @Value("${app.location.upload-dir}") String uploadDir,
            @Value("${app.base-url}") String baseUrl
    ) {
        this.locationImagesRoot = Paths.get(uploadDir).toAbsolutePath().normalize();
        this.baseUrl = baseUrl;

        try {
            Files.createDirectories(this.locationImagesRoot);
        } catch (IOException e) {
            throw new RuntimeException("Could not create directory for location images.", e);
        }
    }

    public List<String> listImageUrls(Long locationId) {
        Path locationDir = locationImagesRoot.resolve(String.valueOf(locationId));
        if (!Files.exists(locationDir) || !Files.isDirectory(locationDir)) {
            return new ArrayList<>();
        }

        try (Stream<Path> paths = Files.list(locationDir)) {
            return paths
                    .filter(Files::isRegularFile)
                    .filter(this::isImageFile)
                    .filter(path -> !path.getFileName().toString().startsWith("."))
                    .sorted(Comparator.comparing(path -> path.getFileName().toString()))
                    .map(path -> baseUrl + "/api/v1/locations/images/" + locationId + "/" + path.getFileName())
                    .collect(Collectors.toList());
        } catch (IOException e) {
            throw new RuntimeException("Could not list images for location " + locationId, e);
        }
    }

    public Resource getImageResource(Long locationId, String fileName) {
        try {
            Path filePath = getImagePath(locationId, fileName);
            if (filePath == null) {
                return null;
            }
            Resource resource = new UrlResource(filePath.toUri());
            if (resource.exists() && resource.isReadable()) {
                return resource;
            }
            return null;
        } catch (MalformedURLException e) {
            return null;
        }
    }

    public Path getImagePath(Long locationId, String fileName) {
        Path locationDir = locationImagesRoot.resolve(String.valueOf(locationId)).normalize();
        Path filePath = locationDir.resolve(fileName).normalize();
        // Prevent path traversal
        if (!filePath.startsWith(locationDir)) {
            return null;
        }
        if (!Files.exists(filePath) || !Files.isRegularFile(filePath) || !isImageFile(filePath)) {
            return null;
        }
        return filePath;
    }

    private boolean isImageFile(Path path) {
        String fileName = path.getFileName().toString().toLowerCase();
        // Fast path: check by known extensions
        if (fileName.endsWith(".jpg") || fileName.endsWith(".jpeg") || fileName.endsWith(".png")
                || fileName.endsWith(".webp") || fileName.endsWith(".gif") || fileName.endsWith(".bmp")
                || fileName.endsWith(".heic")) {
            return true;
        }
        // Fallback: check content type when available
        try {
            String contentType = Files.probeContentType(path);
            return contentType != null && contentType.startsWith("image/");
        } catch (IOException e) {
            return false;
        }
    }

    public List<String> saveImages(Long locationId, MultipartFile[] files) {
        if (files == null || files.length == 0) {
            return new ArrayList<>();
        }

        Path locationDir = locationImagesRoot.resolve(String.valueOf(locationId));
        try {
            Files.createDirectories(locationDir);
        } catch (IOException e) {
            throw new RuntimeException("Could not create directory for location " + locationId, e);
        }

        List<String> savedUrls = new ArrayList<>();

        for (MultipartFile file : files) {
            if (file.isEmpty()) {
                continue;
            }
            String original = file.getOriginalFilename();
            String sanitized = sanitizeFileName(original);
            if (sanitized == null) {
                sanitized = "image_" + System.currentTimeMillis() + ".jpg";
            }

            Path target = locationDir.resolve(sanitized).normalize();
            try {
                Files.copy(file.getInputStream(), target, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                if (isImageFile(target)) {
                    savedUrls.add(baseUrl + "/api/v1/locations/images/" + locationId + "/" + target.getFileName());
                } else {
                    Files.deleteIfExists(target);
                }
            } catch (IOException e) {
                // skip this file and continue
            }
        }

        // Return current listing to reflect final order
        return listImageUrls(locationId);
    }

    private String sanitizeFileName(String fileName) {
        if (fileName == null) return null;
        String lower = fileName.toLowerCase();
        lower = lower.replaceAll("[^a-z0-9._-]", "-");
        // Prevent hidden files
        lower = lower.replaceAll("^\\.+", "");
        if (lower.isBlank()) return null;
        return lower;
    }
}

