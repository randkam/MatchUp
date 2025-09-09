package com.example.tournaments;

import com.example.config.PaginationConfig;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class TournamentService {

    @Autowired
    private TournamentRepository tournamentRepository;

    public Page<Tournament> getUpcomingTournaments(int page, Integer size, String sortBy, String direction) {
        Pageable pageable = PaginationConfig.createPageRequest(page, size, sortBy, direction);
        return tournamentRepository.findUpcoming(LocalDateTime.now(), pageable);
    }
}

