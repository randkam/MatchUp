package com.example.teams;

public class InviteConflictException extends RuntimeException {
    private final Long tournamentId;
    private final String tournamentName;

    public InviteConflictException(Long tournamentId, String tournamentName, String message) {
        super(message);
        this.tournamentId = tournamentId;
        this.tournamentName = tournamentName;
    }

    public Long getTournamentId() {
        return tournamentId;
    }

    public String getTournamentName() {
        return tournamentName;
    }
}


