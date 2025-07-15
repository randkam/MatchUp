package com.example.config;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;

public class PaginationConfig {
    public static final int DEFAULT_PAGE_SIZE = 20;
    public static final int MAX_PAGE_SIZE = 100;

    public static PageRequest createPageRequest(int page, Integer size, String sortBy, String direction) {
        int pageSize = size != null ? Math.min(size, MAX_PAGE_SIZE) : DEFAULT_PAGE_SIZE;
        Sort.Direction sortDirection = direction != null ? Sort.Direction.valueOf(direction.toUpperCase()) : Sort.Direction.DESC;
        Sort sort = Sort.by(sortDirection, sortBy != null ? sortBy : "id");
        return PageRequest.of(page, pageSize, sort);
    }
} 