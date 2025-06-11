package dev.victormartin.rac.model;

import java.sql.Timestamp;

public record RACInstanceInfo(
        int instanceId,
        String instanceName,
        String hostName,
        String status, // STARTED, MOUNTED, OPEN
        String databaseStatus, // ACTIVE, SUSPENDED
        Timestamp startupTime,
        String version,
        String archiver, // STARTED, STOPPED, FAILED
        int threadNumber,
        String activeState // NORMAL, QUIESCING, QUIESCED
) {

    public boolean isHealthy() {
        return "OPEN".equals(status) && "ACTIVE".equals(databaseStatus);
    }

    public boolean isAvailableForConnections() {
        return "OPEN".equals(status) && "NORMAL".equals(activeState);
    }
}
