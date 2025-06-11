package dev.victormartin.rac.model;

import java.time.Instant;
import java.util.Objects;

public record Ping(Long id, String origin, Instant clientTimestamp, Instant serverTimestamp) {

    // Compact constructor for validation
    public Ping {
        Objects.requireNonNull(origin, "Origin cannot be null");
        Objects.requireNonNull(clientTimestamp, "Client timestamp cannot be null");

        if (origin.trim().isEmpty()) {
            throw new IllegalArgumentException("Origin cannot be empty");
        }
    }

    // Constructor for new pings (without ID and server timestamp)
    public Ping(String origin, Instant clientTimestamp) {
        this(null, origin, clientTimestamp, null);
    }

    // Constructor for new pings with current timestamp
    public Ping(String origin) {
        this(null, origin, Instant.now(), null);
    }

    // Utility methods
    public boolean isNew() {
        return id == null;
    }

    public boolean isPersisted() {
        return id != null;
    }

    // Copy methods for immutable updates
    public Ping withId(Long newId) {
        return new Ping(newId, origin, clientTimestamp, serverTimestamp);
    }

    public Ping withOrigin(String newOrigin) {
        return new Ping(id, newOrigin, clientTimestamp, serverTimestamp);
    }

    public Ping withServerTimestamp(Instant newServerTimestamp) {
        return new Ping(id, origin, clientTimestamp, newServerTimestamp);
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (!(obj instanceof Ping other))
            return false;

        // Compare by ID if both have one
        if (id != null && other.id != null) {
            return Objects.equals(id, other.id);
        }

        // Otherwise compare by natural key (origin and client timestamp)
        return Objects.equals(origin, other.origin) && 
               Objects.equals(clientTimestamp, other.clientTimestamp);
    }

    @Override
    public int hashCode() {
        return id != null ? Objects.hash(id) : Objects.hash(origin, clientTimestamp);
    }
}