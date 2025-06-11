package dev.victormartin.rac.service;

import io.prometheus.client.Gauge;
import io.prometheus.client.CollectorRegistry;
import io.prometheus.client.exporter.HTTPServer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import dev.victormartin.rac.config.DatabaseConfig;

import java.util.Properties;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public class DatabaseMonitoringService {
    private static final Logger logger = LoggerFactory.getLogger(DatabaseMonitoringService.class);

    // Prometheus Metrics
    private static final Gauge DATABASE_UP = Gauge.build()
            .name("oracle_database_up")
            .help("Oracle database availability (1 = up, 0 = down)")
            .labelNames("instance", "database_name")
            .register();

    private static final Gauge ACTIVE_CONNECTIONS = Gauge.build()
            .name("oracle_database_active_connections")
            .help("Number of active database connections")
            .labelNames("instance", "database_name")
            .register();

    private final DatabaseConfig dbConfig;
    private final ScheduledExecutorService scheduler;
    private HTTPServer prometheusServer;

    private final Long checkIntervalSeconds;

    public DatabaseMonitoringService(DatabaseConfig dbConfig, Properties config) {
        this.dbConfig = dbConfig;
        this.checkIntervalSeconds = Long.valueOf(config.getProperty("monitoring.checkIntervalSeconds", "5"));
        this.scheduler = Executors.newScheduledThreadPool(2);
    }

    public void start() throws Exception {
        // Start Prometheus HTTP server
        prometheusServer = new HTTPServer(
                new java.net.InetSocketAddress("0.0.0.0", 8080),
                CollectorRegistry.defaultRegistry);

        logger.info("Started Prometheus metrics server on port {}", 8080);

        // Schedule database health checks
        scheduler.scheduleAtFixedRate(
                this::performHealthCheck,
                0,
                checkIntervalSeconds,
                TimeUnit.SECONDS);

        logger.info("Started database health checks every {} seconds", checkIntervalSeconds);
    }

    private void performHealthCheck() {
        boolean isHealthy = false;

        try {
            // Perform actual database check
            isHealthy = dbConfig.isHealthy();

            // Update metrics
            DATABASE_UP.labels(dbConfig.getInstanceName(), dbConfig.getDatabaseName())
                    .set(isHealthy ? 1 : 0);

            // Update active connections metric
            try {
                int activeConnections = dbConfig.getActiveConnectionsCount();
                ACTIVE_CONNECTIONS.labels(dbConfig.getInstanceName(), dbConfig.getDatabaseName())
                        .set(activeConnections);
            } catch (Exception e) {
                logger.warn("Failed to retrieve active connections count", e);
            }

            logger.debug("Database health check completed: {}",
                    isHealthy ? "UP" : "DOWN");

        } catch (Exception e) {
            logger.error("Health check failed with exception", e);

            DATABASE_UP.labels(dbConfig.getInstanceName(), dbConfig.getDatabaseName()).set(0);
        }
    }

    public void shutdown() {
        logger.info("Shutting down database monitoring service");

        if (scheduler != null) {
            scheduler.shutdown();
            try {
                if (!scheduler.awaitTermination(30, TimeUnit.SECONDS)) {
                    scheduler.shutdownNow();
                }
            } catch (InterruptedException e) {
                scheduler.shutdownNow();
                Thread.currentThread().interrupt();
            }
        }

        if (prometheusServer != null) {
            prometheusServer.close();
        }
    }
}