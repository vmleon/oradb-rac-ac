package dev.victormartin.rac.repository;

import dev.victormartin.rac.model.Ping;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.sql.DataSource;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class PingRepository {
    private static final Logger logger = LoggerFactory.getLogger(PingRepository.class);
    private final DataSource dataSource;

    public PingRepository(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    public List<Ping> findAll() throws SQLException {
        String sql = "SELECT id, origin, client_timestamp, server_timestamp FROM pings ORDER BY id";
        List<Ping> pings = new ArrayList<>();

        try (Connection conn = dataSource.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                pings.add(mapResultSetToPing(rs));
            }
        }

        logger.debug("Found {} pings", pings.size());
        return pings;
    }

    public Optional<Ping> findById(Long id) throws SQLException {
        String sql = "SELECT id, origin, client_timestamp, server_timestamp FROM pings WHERE id = ?";

        try (Connection conn = dataSource.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, id);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapResultSetToPing(rs));
                }
            }
        }

        return Optional.empty();
    }

    public Ping save(Ping ping) throws SQLException {
        return insert(ping);
    }

    private Ping insert(Ping ping) throws SQLException {
        String sql = "INSERT INTO pings (origin, client_timestamp) VALUES (?, ?)";

        try (Connection conn = dataSource.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql, new String[] { "id" })) {

            stmt.setString(1, ping.origin());
            stmt.setTimestamp(2, Timestamp.from(ping.clientTimestamp()));

            int rowsAffected = stmt.executeUpdate();
            if (rowsAffected == 0) {
                throw new SQLException("Creating ping failed, no rows affected.");
            }

            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    Object idObj = generatedKeys.getObject(1);
                    Long generatedId = null;

                    if (idObj instanceof Number) {
                        generatedId = ((Number) idObj).longValue();
                    } else if (idObj instanceof String) {
                        generatedId = Long.parseLong((String) idObj);
                    } else {
                        throw new SQLException("Unexpected type for generated ID: " + idObj.getClass());
                    }

                    // Now get the server timestamp by querying the inserted record
                    String selectSql = "SELECT server_timestamp FROM pings WHERE id = ?";
                    try (PreparedStatement selectStmt = conn.prepareStatement(selectSql)) {
                        selectStmt.setLong(1, generatedId);
                        try (ResultSet rs = selectStmt.executeQuery()) {
                            if (rs.next()) {
                                Timestamp serverTimestamp = rs.getTimestamp("server_timestamp");
                                Ping savedPing = ping.withId(generatedId)
                                        .withServerTimestamp(serverTimestamp.toInstant());
                                logger.info("Created ping with id: {}", generatedId);
                                return savedPing;
                            } else {
                                throw new SQLException(
                                        "Failed to retrieve server timestamp for ping id: " + generatedId);
                            }
                        }
                    }
                } else {
                    throw new SQLException("Creating ping failed, no ID obtained.");
                }
            }
        }
    }

    private Ping mapResultSetToPing(ResultSet rs) throws SQLException {
        return new Ping(
                rs.getLong("id"),
                rs.getString("origin"),
                rs.getTimestamp("client_timestamp").toInstant(),
                rs.getTimestamp("server_timestamp").toInstant());
    }
}