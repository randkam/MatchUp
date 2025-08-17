package com.example.locations;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.util.List;

@RestController
@RequestMapping("/api/v1/locations")
public class LocationImageController {

    private final LocationImageStorageService storageService;

    @Autowired
    public LocationImageController(LocationImageStorageService storageService) {
        this.storageService = storageService;
    }

    // List image URLs for a location. Images are discovered from the file system.
    @GetMapping("/{locationId}/images")
    public ResponseEntity<List<String>> listLocationImages(@PathVariable Long locationId) {
        List<String> urls = storageService.listImageUrls(locationId);
        return ResponseEntity.ok(urls);
    }

    // Upload one or more images for a location
    @PostMapping("/{locationId}/images")
    public ResponseEntity<List<String>> uploadLocationImages(
            @PathVariable Long locationId,
            @RequestParam("files") MultipartFile[] files
    ) {
        List<String> urls = storageService.saveImages(locationId, files);
        return ResponseEntity.ok(urls);
    }

    // Serve a specific image file from local storage
    @GetMapping(value = "/images/{locationId}/{fileName:.+}")
    public ResponseEntity<Resource> getLocationImage(
            @PathVariable Long locationId,
            @PathVariable String fileName
    ) {
        Resource resource = storageService.getImageResource(locationId, fileName);
        if (resource == null) {
            return ResponseEntity.notFound().build();
        }
        // Best-effort content type detection
        MediaType mediaType = MediaType.IMAGE_JPEG;
        try {
            String detected = Files.probeContentType(storageService.getImagePath(locationId, fileName));
            if (detected != null) {
                mediaType = MediaType.parseMediaType(detected);
            }
        } catch (Exception ignored) {}

        return ResponseEntity.ok()
                .contentType(mediaType)
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + fileName + "\"")
                .body(resource);
    }
}

