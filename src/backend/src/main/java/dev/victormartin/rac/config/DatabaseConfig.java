package dev.victormartin.rac.config;

import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import dev.victormartin.rac.model.DatabaseInstanceInfo;
import dev.victormartin.rac.model.RACInstanceInfo;

import javax.sql.DataSource;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

public class DatabaseConfig {
    private static final Logger logger = LoggerFactory.getLogger(DatabaseConfig.class);

    private final PoolDataSource poolDataSource;

    private DatabaseInstanceInfo currentInstanceInfo;

    public DatabaseConfig(Properties config) throws SQLException {
        this.poolDataSource = createDataSource(config);
        configureMonitoring();
        this.currentInstanceInfo = getCurrentInstanceInfo();
    }

    private PoolDataSource createDataSource(Properties config) throws SQLException {
        PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();

        // Connection details
        pds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        pds.setURL(config.getProperty("db.url"));
        pds.setUser(config.getProperty("db.username"));
        pds.setPassword(config.getProperty("db.password"));

        // Pool configuration
        pds.setInitialPoolSize(Integer.parseInt(config.getProperty("db.pool.initial", "2")));
        pds.setMinPoolSize(Integer.parseInt(config.getProperty("db.pool.min", "2")));
        pds.setMaxPoolSize(Integer.parseInt(config.getProperty("db.pool.max", "5")));

        // Connection validation
        pds.setValidateConnectionOnBorrow(true);
        pds.setSQLForValidateConnection("SELECT 1 FROM DUAL");

        // Timeouts (in seconds)
        pds.setConnectionWaitTimeout(30);
        pds.setInactiveConnectionTimeout(300);
        pds.setTimeoutCheckInterval(30);

        // Performance tuning
        pds.setFastConnectionFailoverEnabled(true);
        // TODO Enable ONS for RAC notifications
        // pds.setONSConfiguration("nodes=rac1:6200,rac2:6200");
        pds.setConnectionPoolName("main-pool");

        logger.info("Initialized UCP with pool size: {}-{}",
                pds.getMinPoolSize(), pds.getMaxPoolSize());

        return pds;
    }

    private void configureMonitoring() throws SQLException {
        // Enable JMX monitoring
        poolDataSource.setConnectionPoolName("main-pool");

        // Enable statistics collection
        System.setProperty("oracle.ucp.statistics.enabled", "true");
        System.setProperty("oracle.ucp.jmx.enabled", "true");
    }

    public DatabaseInstanceInfo getCurrentInstanceInfo() throws SQLException {
        String query = """
                SELECT
                    sys_context('USERENV', 'INSTANCE_NAME') as instance_name,
                    sys_context('USERENV', 'DB_NAME') as database_name,
                    sys_context('USERENV', 'SERVER_HOST') as host_name,
                    sys_context('USERENV', 'SERVICE_NAME') as service_name
                FROM dual
                """;

        try (Connection conn = poolDataSource.getConnection();
                PreparedStatement stmt = conn.prepareStatement(query);
                ResultSet rs = stmt.executeQuery()) {

            if (rs.next()) {
                return new DatabaseInstanceInfo(
                        rs.getString("instance_name"),
                        rs.getString("database_name"),
                        rs.getString("host_name"),
                        rs.getString("service_name"));
            }
            throw new SQLException("Unable to retrieve instance information");
        }
    }

    public DataSource getDataSource() {
        return poolDataSource;
    }

    public void close() {
        if (poolDataSource != null) {
            logger.info("Connection pool will be automatically closed by UCP shutdown hook");
        }
    }

    // Health check method
    public boolean isHealthy() {
        try {
            return poolDataSource.getAvailableConnectionsCount() > 0;
        } catch (SQLException e) {
            logger.error("Health check failed", e);
            return false;
        }
    }

    public int getActiveConnectionsCount() throws SQLException {
        return poolDataSource.getAvailableConnectionsCount();
    }

    public List<RACInstanceInfo> getRACClusterInfo() throws SQLException {
        String racQuery = """
                SELECT inst_id, instance_name, host_name, status, database_status,
                       startup_time, version, archiver,
                       thread#, active_state
                FROM gv$instance
                ORDER BY inst_id
                """;

        List<RACInstanceInfo> instances = new ArrayList<>();

        try (Connection conn = poolDataSource.getConnection();
                PreparedStatement stmt = conn.prepareStatement(racQuery);
                ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                instances.add(new RACInstanceInfo(
                        rs.getInt("inst_id"),
                        rs.getString("instance_name"),
                        rs.getString("host_name"),
                        rs.getString("status"),
                        rs.getString("database_status"),
                        rs.getTimestamp("startup_time"),
                        rs.getString("version"),
                        rs.getString("archiver"),
                        rs.getInt("thread#"),
                        rs.getString("active_state")));
            }
        }

        return instances;
    }

    public String getInstanceName() {
        // get the database instance name from the connection
        return currentInstanceInfo.instanceName();
    }

    public String getDatabaseName() {
        // get the database instance name from the connection
        return currentInstanceInfo.databaseName();
    }
}