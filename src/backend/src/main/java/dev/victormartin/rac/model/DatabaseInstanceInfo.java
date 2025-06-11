package dev.victormartin.rac.model;

public record DatabaseInstanceInfo(String instanceName, String databaseName,
        String hostName, String serviceName) {
}
