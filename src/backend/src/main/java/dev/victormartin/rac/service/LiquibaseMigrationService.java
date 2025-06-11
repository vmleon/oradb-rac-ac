package dev.victormartin.rac.service;

import liquibase.Liquibase;
import liquibase.database.Database;
import liquibase.database.DatabaseFactory;
import liquibase.database.jvm.JdbcConnection;
import liquibase.resource.ClassLoaderResourceAccessor;
import liquibase.resource.CompositeResourceAccessor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.sql.DataSource;
import java.sql.Connection;
import java.util.Properties;

public class LiquibaseMigrationService {
    private static final Logger logger = LoggerFactory.getLogger(LiquibaseMigrationService.class);

    private final DataSource dataSource;
    private final Properties config;

    public LiquibaseMigrationService(DataSource dataSource, Properties config) {
        this.dataSource = dataSource;
        this.config = config;
    }

    public void runMigrations() {
        try (Connection connection = dataSource.getConnection()) {
            logger.info("Running Liquibase migrations...");

            Database database = DatabaseFactory.getInstance()
                    .findCorrectDatabaseImplementation(new JdbcConnection(connection));

            String changeLogFile = config.getProperty("liquibase.changeLog",
                    "db/changelog/db.changelog-master.yaml");
            String contexts = config.getProperty("liquibase.contexts", "default");

            // Use composite resource accessor to try multiple approaches
            ClassLoaderResourceAccessor classLoaderAccessor = new ClassLoaderResourceAccessor();
            ClassLoaderResourceAccessor threadClassLoaderAccessor = new ClassLoaderResourceAccessor(
                    Thread.currentThread().getContextClassLoader());
            CompositeResourceAccessor resourceAccessor = new CompositeResourceAccessor(classLoaderAccessor,
                    threadClassLoaderAccessor);

            Liquibase liquibase = new Liquibase(changeLogFile, resourceAccessor, database);

            liquibase.update(contexts);
            logger.info("Liquibase migrations completed successfully");

        } catch (Exception e) {
            logger.error("Failed to run Liquibase migrations", e);
            throw new RuntimeException("Database migration failed", e);
        }
    }
}