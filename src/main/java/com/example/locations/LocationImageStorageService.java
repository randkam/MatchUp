package com.example.locations;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;

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
        try {
            String contentType = Files.probeContentType(path);
            return contentType != null && contentType.startsWith("image/");
        } catch (IOException e) {
            return false;
        }
    }
}

