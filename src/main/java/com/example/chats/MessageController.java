package com.example.chats;

import com.example.config.PaginationConfig;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/messages")
public class MessageController {

    @Autowired
    private ChatService chatService;

    @GetMapping("/{locationId}")
    public ResponseEntity<Page<ChatMessage>> getLocationMessages(
            @PathVariable int locationId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String direction) {
        return ResponseEntity.ok(chatService.getLocationMessages(
            locationId, PaginationConfig.createPageRequest(page, size, sortBy, direction)));
    }
}

