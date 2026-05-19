-- Multi-Region Database Replication Setup
-- PostgreSQL/TimescaleDB Logical Replication Configuration
-- Execute these steps in order across regions

-- ============================================================
-- PART 1: Prerequisites and Configuration
-- ============================================================

-- Enable required extensions (execute on all databases)
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Configure replication settings (postgresql.conf)
-- Requires PostgreSQL restart after these changes
ALTER SYSTEM SET wal_level = 'logical';
ALTER SYSTEM SET max_replication_slots = 10;
ALTER SYSTEM SET max_wal_senders = 10;
ALTER SYSTEM SET max_logical_replication_workers = 10;
ALTER SYSTEM SET shared_preload_libraries = 'timescaledb';

-- After restart, verify settings
SHOW wal_level;  -- Should be 'logical'
SHOW max_replication_slots;  -- Should be >= 10

-- ============================================================
-- PART 2: Create Replication User
-- ============================================================

-- Create dedicated replication user (execute on all regions)
CREATE ROLE replicator WITH
    LOGIN
    REPLICATION
    CONNECTION LIMIT 10
    PASSWORD 'CHANGE_ME_STRONG_PASSWORD';

-- Grant necessary permissions
GRANT CONNECT ON DATABASE automotive TO replicator;
GRANT USAGE ON SCHEMA public TO replicator;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO replicator;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO replicator;

-- For TimescaleDB hypertables
GRANT SELECT ON ALL TABLES IN SCHEMA _timescaledb_internal TO replicator;

-- Update pg_hba.conf to allow replication connections
-- Add these lines to pg_hba.conf on all regions:
-- host replication replicator 10.0.0.0/8 md5
-- host automotive replicator 10.0.0.0/8 md5

-- ============================================================
-- PART 3: Create Tables and Hypertables
-- ============================================================

-- Vehicle telemetry table (time-series data)
CREATE TABLE IF NOT EXISTS vehicle_telemetry (
    time TIMESTAMPTZ NOT NULL,
    vehicle_id UUID NOT NULL,
    region VARCHAR(50) NOT NULL,
    battery_voltage DOUBLE PRECISION,
    battery_current DOUBLE PRECISION,
    battery_temperature DOUBLE PRECISION,
    battery_soc DOUBLE PRECISION,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    odometer BIGINT,
    diagnostic_codes TEXT[],
    metadata JSONB,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_region VARCHAR(50) NOT NULL
);

-- Convert to hypertable (execute on all regions)
SELECT create_hypertable('vehicle_telemetry', 'time',
    chunk_time_interval => INTERVAL '1 day',
    partitioning_column => 'vehicle_id',
    number_partitions => 10,
    if_not_exists => TRUE
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_vehicle_telemetry_vehicle_time
    ON vehicle_telemetry (vehicle_id, time DESC);

CREATE INDEX IF NOT EXISTS idx_vehicle_telemetry_region_time
    ON vehicle_telemetry (region, time DESC);

CREATE INDEX IF NOT EXISTS idx_vehicle_telemetry_updated
    ON vehicle_telemetry (updated_at, updated_region);

-- Vehicle state table (current state, low cardinality)
CREATE TABLE IF NOT EXISTS vehicle_state (
    vehicle_id UUID PRIMARY KEY,
    state JSONB NOT NULL DEFAULT '{}',
    version_vector JSONB NOT NULL DEFAULT '{}',
    last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    region VARCHAR(50) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_region VARCHAR(50) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_vehicle_state_region
    ON vehicle_state (region);

CREATE INDEX IF NOT EXISTS idx_vehicle_state_last_seen
    ON vehicle_state (last_seen DESC);

-- Charging sessions table
CREATE TABLE IF NOT EXISTS charging_sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL,
    station_id VARCHAR(100) NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    energy_delivered_kwh DOUBLE PRECISION,
    cost_usd DOUBLE PRECISION,
    region VARCHAR(50) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_region VARCHAR(50) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_charging_sessions_vehicle
    ON charging_sessions (vehicle_id, start_time DESC);

-- Audit log for compliance
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_id UUID,
    vehicle_id UUID,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id VARCHAR(255),
    region VARCHAR(50) NOT NULL,
    ip_address INET,
    request_data JSONB,
    success BOOLEAN NOT NULL,
    compliance_tags TEXT[]
);

-- Convert audit_log to hypertable
SELECT create_hypertable('audit_log', 'timestamp',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

CREATE INDEX IF NOT EXISTS idx_audit_log_user
    ON audit_log (user_id, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_audit_log_vehicle
    ON audit_log (vehicle_id, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_audit_log_compliance
    ON audit_log USING GIN (compliance_tags);

-- ============================================================
-- PART 4: Conflict Resolution Functions
-- ============================================================

-- Last-Write-Wins (LWW) conflict resolution
CREATE OR REPLACE FUNCTION resolve_vehicle_telemetry_conflict()
RETURNS TRIGGER AS $$
BEGIN
    -- Keep the row with the most recent updated_at timestamp
    IF NEW.updated_at > OLD.updated_at THEN
        RETURN NEW;
    ELSIF NEW.updated_at < OLD.updated_at THEN
        RETURN OLD;
    ELSE
        -- Timestamps equal, use vehicle_id as tiebreaker
        IF NEW.vehicle_id > OLD.vehicle_id THEN
            RETURN NEW;
        ELSE
            RETURN OLD;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Apply conflict resolution to telemetry table
CREATE TRIGGER vehicle_telemetry_conflict_resolver
BEFORE UPDATE ON vehicle_telemetry
FOR EACH ROW
WHEN (pg_trigger_depth() > 0)  -- Only for replicated updates
EXECUTE FUNCTION resolve_vehicle_telemetry_conflict();

-- Version vector based conflict resolution for vehicle state
CREATE OR REPLACE FUNCTION merge_vehicle_state()
RETURNS TRIGGER AS $$
DECLARE
    new_version INT;
    old_version INT;
BEGIN
    -- Get version for the updating region
    new_version := COALESCE((NEW.version_vector->NEW.updated_region)::INT, 0) + 1;
    old_version := COALESCE((OLD.version_vector->NEW.updated_region)::INT, 0);

    -- Check for conflict (concurrent updates from different regions)
    IF old_version >= new_version THEN
        -- Conflict detected, merge states (NEW wins on conflicts)
        NEW.state := OLD.state || NEW.state;
    END IF;

    -- Update version vector
    NEW.version_vector := OLD.version_vector ||
                          jsonb_build_object(NEW.updated_region, new_version);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER vehicle_state_merger
BEFORE UPDATE ON vehicle_state
FOR EACH ROW
EXECUTE FUNCTION merge_vehicle_state();

-- ============================================================
-- PART 5: Set Up Publications (Execute on US-EAST-1)
-- ============================================================

-- Create publication for all tables to replicate
CREATE PUBLICATION vehicle_data_pub FOR TABLE
    vehicle_telemetry,
    vehicle_state,
    charging_sessions,
    audit_log
WITH (publish = 'insert, update, delete');

-- Verify publication
SELECT * FROM pg_publication;
SELECT * FROM pg_publication_tables WHERE pubname = 'vehicle_data_pub';

-- ============================================================
-- PART 6: Set Up Subscriptions (Execute on EU-WEST-1)
-- ============================================================

-- Create subscription to US-EAST-1
CREATE SUBSCRIPTION vehicle_data_from_us_east_1
CONNECTION 'host=automotive-platform-db-us-east-1.xyz.us-east-1.rds.amazonaws.com port=5432 dbname=automotive user=replicator password=CHANGE_ME_STRONG_PASSWORD'
PUBLICATION vehicle_data_pub
WITH (
    copy_data = true,           -- Initial data sync
    create_slot = true,         -- Create replication slot
    enabled = true,             -- Start immediately
    slot_name = 'eu_west_1_slot',
    connect = true,
    synchronous_commit = 'off'  -- Async replication for performance
);

-- Create publication on EU-WEST-1 for bidirectional replication
CREATE PUBLICATION vehicle_data_pub FOR TABLE
    vehicle_telemetry,
    vehicle_state,
    charging_sessions,
    audit_log
WITH (publish = 'insert, update, delete');

-- ============================================================
-- PART 7: Set Up Subscriptions (Execute on US-EAST-1)
-- ============================================================

-- Subscribe US-EAST-1 to EU-WEST-1
CREATE SUBSCRIPTION vehicle_data_from_eu_west_1
CONNECTION 'host=automotive-platform-db-eu-west-1.xyz.eu-west-1.rds.amazonaws.com port=5432 dbname=automotive user=replicator password=CHANGE_ME_STRONG_PASSWORD'
PUBLICATION vehicle_data_pub
WITH (
    copy_data = false,          -- Don't copy data (already have it)
    create_slot = true,
    enabled = true,
    slot_name = 'us_east_1_slot',
    connect = true,
    synchronous_commit = 'off'
);

-- ============================================================
-- PART 8: Monitoring and Management
-- ============================================================

-- View replication status
CREATE OR REPLACE VIEW replication_status AS
SELECT
    application_name,
    client_addr,
    state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    sync_state,
    pg_wal_lsn_diff(sent_lsn, replay_lsn) AS replication_lag_bytes,
    (extract(epoch from now()) - extract(epoch from reply_time))::INT AS lag_seconds
FROM pg_stat_replication;

-- View subscription status
CREATE OR REPLACE VIEW subscription_status AS
SELECT
    subname AS subscription_name,
    pid,
    received_lsn,
    latest_end_lsn,
    last_msg_send_time,
    last_msg_receipt_time,
    pg_wal_lsn_diff(latest_end_lsn, received_lsn) AS lag_bytes
FROM pg_stat_subscription;

-- Function to check replication health
CREATE OR REPLACE FUNCTION check_replication_health()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- Check replication lag
    RETURN QUERY
    SELECT
        'replication_lag'::TEXT,
        CASE
            WHEN MAX(lag_seconds) < 10 THEN 'healthy'
            WHEN MAX(lag_seconds) < 60 THEN 'warning'
            ELSE 'critical'
        END,
        'Max lag: ' || COALESCE(MAX(lag_seconds)::TEXT, 'N/A') || ' seconds'
    FROM replication_status;

    -- Check subscription status
    RETURN QUERY
    SELECT
        'subscription_active'::TEXT,
        CASE
            WHEN COUNT(*) > 0 THEN 'healthy'
            ELSE 'critical'
        END,
        'Active subscriptions: ' || COUNT(*)::TEXT
    FROM pg_stat_subscription
    WHERE pid IS NOT NULL;

    -- Check replication slots
    RETURN QUERY
    SELECT
        'replication_slots'::TEXT,
        CASE
            WHEN COUNT(*) > 0 THEN 'healthy'
            ELSE 'warning'
        END,
        'Active slots: ' || COUNT(*)::TEXT
    FROM pg_replication_slots
    WHERE active = true;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- PART 9: Maintenance Procedures
-- ============================================================

-- Drop inactive replication slots (maintenance)
CREATE OR REPLACE FUNCTION cleanup_inactive_slots(max_age_hours INT DEFAULT 24)
RETURNS TABLE(slot_name TEXT, action TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.slot_name::TEXT,
        'dropped'::TEXT
    FROM pg_replication_slots s
    WHERE s.active = false
      AND (now() - s.restart_lsn::pg_lsn::BIGINT::NUMERIC / 1000000000 * INTERVAL '1 second') > (max_age_hours * INTERVAL '1 hour');

    -- Drop the slots
    FOR slot_name IN
        SELECT s.slot_name
        FROM pg_replication_slots s
        WHERE s.active = false
          AND (now() - s.restart_lsn::pg_lsn::BIGINT::NUMERIC / 1000000000 * INTERVAL '1 second') > (max_age_hours * INTERVAL '1 hour')
    LOOP
        EXECUTE 'SELECT pg_drop_replication_slot($1)' USING slot_name;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- PART 10: Continuous Aggregates for Analytics
-- ============================================================

-- 5-minute aggregate for real-time dashboards
CREATE MATERIALIZED VIEW vehicle_telemetry_5min
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('5 minutes', time) AS bucket,
    vehicle_id,
    region,
    AVG(battery_voltage) AS avg_voltage,
    MAX(battery_voltage) AS max_voltage,
    MIN(battery_voltage) AS min_voltage,
    AVG(battery_temperature) AS avg_temperature,
    MAX(battery_temperature) AS max_temperature,
    AVG(battery_soc) AS avg_soc,
    MIN(battery_soc) AS min_soc,
    AVG(speed) AS avg_speed,
    MAX(speed) AS max_speed,
    COUNT(*) AS sample_count
FROM vehicle_telemetry
GROUP BY bucket, vehicle_id, region
WITH NO DATA;

-- Refresh policy for continuous aggregate
SELECT add_continuous_aggregate_policy('vehicle_telemetry_5min',
    start_offset => INTERVAL '1 hour',
    end_offset => INTERVAL '5 minutes',
    schedule_interval => INTERVAL '5 minutes');

-- Hourly aggregate for historical analysis
CREATE MATERIALIZED VIEW vehicle_telemetry_1h
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    vehicle_id,
    region,
    AVG(battery_voltage) AS avg_voltage,
    AVG(battery_temperature) AS avg_temperature,
    AVG(battery_soc) AS avg_soc,
    AVG(speed) AS avg_speed,
    MAX(odometer) AS max_odometer,
    COUNT(*) AS sample_count
FROM vehicle_telemetry
GROUP BY bucket, vehicle_id, region
WITH NO DATA;

SELECT add_continuous_aggregate_policy('vehicle_telemetry_1h',
    start_offset => INTERVAL '7 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

-- ============================================================
-- PART 11: Data Retention Policies
-- ============================================================

-- Retain raw telemetry for 90 days
SELECT add_retention_policy('vehicle_telemetry', INTERVAL '90 days');

-- Retain audit logs for 7 years (compliance requirement)
SELECT add_retention_policy('audit_log', INTERVAL '7 years');

-- Compress telemetry data older than 7 days
ALTER TABLE vehicle_telemetry SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'vehicle_id, region',
    timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy('vehicle_telemetry', INTERVAL '7 days');

-- ============================================================
-- PART 12: Verification Queries
-- ============================================================

-- Check replication status
SELECT * FROM replication_status;

-- Check subscription status
SELECT * FROM subscription_status;

-- Check replication health
SELECT * FROM check_replication_health();

-- Count records by region
SELECT region, COUNT(*) FROM vehicle_telemetry
WHERE time > NOW() - INTERVAL '1 hour'
GROUP BY region;

-- Check for conflicts (version vector)
SELECT vehicle_id, version_vector, updated_at, updated_region
FROM vehicle_state
WHERE jsonb_object_keys(version_vector)::TEXT[] && ARRAY['us-east-1', 'eu-west-1']
LIMIT 10;

-- Monitor replication lag over time
SELECT
    now() AS check_time,
    application_name,
    lag_seconds,
    replication_lag_bytes / 1024 / 1024 AS lag_mb
FROM replication_status
ORDER BY lag_seconds DESC;

-- ============================================================
-- NOTES:
-- ============================================================
-- 1. Replace 'CHANGE_ME_STRONG_PASSWORD' with actual secure passwords
-- 2. Update database hostnames in CONNECTION strings
-- 3. Ensure network connectivity between regions (VPC peering, VPN, or public with TLS)
-- 4. Monitor replication lag regularly (target < 1 second)
-- 5. Test failover procedures before production deployment
-- 6. Implement alerting on replication lag > 60 seconds
-- 7. For AP-NORTHEAST-1, repeat subscription setup with appropriate connection strings
-- 8. Consider using AWS RDS proxy for connection pooling
-- 9. Enable point-in-time recovery (PITR) for disaster recovery
-- 10. Document runbook for manual failover procedures
