package com.example.users;

import java.io.Serializable;
import java.util.Objects;

public class UserStatsKey implements Serializable {
    private Long userId;
    private String sport;

    public UserStatsKey() {}
    public UserStatsKey(Long userId, String sport) { this.userId = userId; this.sport = sport; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        UserStatsKey that = (UserStatsKey) o;
        return Objects.equals(userId, that.userId) && Objects.equals(sport, that.sport);
    }

    @Override
    public int hashCode() {
        return Objects.hash(userId, sport);
    }
}


