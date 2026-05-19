#!/bin/bash
# Automated Failover Script
# Fails over traffic from primary region to secondary region

set -euo pipefail

# Configuration
PRIMARY_REGION="${1:-us-east-1}"
SECONDARY_REGION="${2:-eu-west-1}"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-}"
DOMAIN_NAME="${DOMAIN_NAME:-automotive.example.com}"
DRY_RUN="${DRY_RUN:-false}"

# Logging
LOG_FILE="/var/log/failover-$(date +%Y%m%d-%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

# Validate environment
if [ -z "$HOSTED_ZONE_ID" ]; then
    error "HOSTED_ZONE_ID environment variable not set"
    exit 1
fi

# ============================================================
# Pre-Flight Checks
# ============================================================

check_region_health() {
    local region=$1
    local health_endpoint="https://api-${region}.${DOMAIN_NAME}/health"

    log "Checking health of ${region}..."

    response=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time 10 \
        --connect-timeout 5 \
        "${health_endpoint}" || echo "000")

    if [ "$response" -eq 200 ]; then
        log "${region} is healthy (HTTP ${response})"
        return 0
    else
        log "${region} is unhealthy (HTTP ${response})"
        return 1
    fi
}

check_database_replication_lag() {
    local region=$1
    local max_lag_seconds=60

    log "Checking database replication lag in ${region}..."

    # Get database endpoint
    db_endpoint=$(aws rds describe-db-instances \
        --region "${region}" \
        --query "DBInstances[?DBInstanceIdentifier=='automotive-platform-db-${region}'].Endpoint.Address" \
        --output text)

    if [ -z "$db_endpoint" ]; then
        error "Could not find database endpoint for ${region}"
        return 1
    fi

    # Check replication lag
    lag=$(psql -h "$db_endpoint" -U admin -d automotive -t -c \
        "SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()))::INT;" 2>/dev/null || echo "999")

    if [ "$lag" -lt "$max_lag_seconds" ]; then
        log "${region} database lag: ${lag}s (acceptable)"
        return 0
    else
        log "${region} database lag: ${lag}s (exceeds ${max_lag_seconds}s threshold)"
        return 1
    fi
}

check_kubernetes_cluster() {
    local region=$1

    log "Checking Kubernetes cluster health in ${region}..."

    # Update kubeconfig
    aws eks update-kubeconfig \
        --region "${region}" \
        --name "automotive-platform-cluster-${region}" \
        --alias "${region}"

    # Check node status
    ready_nodes=$(kubectl get nodes \
        --context="${region}" \
        --no-headers 2>/dev/null | grep -c " Ready " || echo "0")

    if [ "$ready_nodes" -gt 0 ]; then
        log "${region} Kubernetes cluster has ${ready_nodes} ready nodes"
        return 0
    else
        error "${region} Kubernetes cluster has no ready nodes"
        return 1
    fi
}

# ============================================================
# Failover Actions
# ============================================================

update_dns_to_secondary() {
    log "Updating DNS to point to ${SECONDARY_REGION}..."

    # Get secondary region load balancer DNS
    alb_dns=$(aws elbv2 describe-load-balancers \
        --region "${SECONDARY_REGION}" \
        --names "automotive-platform-alb-${SECONDARY_REGION}" \
        --query 'LoadBalancers[0].DNSName' \
        --output text)

    if [ -z "$alb_dns" ]; then
        error "Could not find load balancer in ${SECONDARY_REGION}"
        return 1
    fi

    log "Secondary region load balancer: ${alb_dns}"

    # Create Route 53 change batch
    cat > /tmp/failover-dns-change.json <<EOF
{
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "api.${DOMAIN_NAME}",
            "Type": "A",
            "SetIdentifier": "${SECONDARY_REGION^^}",
            "GeoProximityLocation": {
                "AWSRegion": "${SECONDARY_REGION}",
                "Bias": 100
            },
            "AliasTarget": {
                "HostedZoneId": "$(aws elbv2 describe-load-balancers \
                    --region "${SECONDARY_REGION}" \
                    --names "automotive-platform-alb-${SECONDARY_REGION}" \
                    --query 'LoadBalancers[0].CanonicalHostedZoneId' \
                    --output text)",
                "DNSName": "${alb_dns}",
                "EvaluateTargetHealth": true
            },
            "TTL": 60
        }
    }]
}
EOF

    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY RUN] Would apply DNS changes:"
        cat /tmp/failover-dns-change.json
        return 0
    fi

    # Apply DNS changes
    change_id=$(aws route53 change-resource-record-sets \
        --hosted-zone-id "${HOSTED_ZONE_ID}" \
        --change-batch file:///tmp/failover-dns-change.json \
        --query 'ChangeInfo.Id' \
        --output text)

    log "DNS change initiated: ${change_id}"

    # Wait for DNS propagation
    log "Waiting for DNS propagation..."
    aws route53 wait resource-record-sets-changed --id "${change_id}"

    log "DNS failover complete"
    rm -f /tmp/failover-dns-change.json
}

promote_database_replica() {
    log "Promoting database replica in ${SECONDARY_REGION}..."

    # Check if instance is already a primary
    is_replica=$(aws rds describe-db-instances \
        --region "${SECONDARY_REGION}" \
        --db-instance-identifier "automotive-platform-db-${SECONDARY_REGION}" \
        --query 'DBInstances[0].ReadReplicaSourceDBInstanceIdentifier' \
        --output text)

    if [ "$is_replica" = "None" ]; then
        log "Database in ${SECONDARY_REGION} is already a primary instance"
        return 0
    fi

    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY RUN] Would promote database replica in ${SECONDARY_REGION}"
        return 0
    fi

    # Promote read replica to standalone instance
    aws rds promote-read-replica \
        --region "${SECONDARY_REGION}" \
        --db-instance-identifier "automotive-platform-db-${SECONDARY_REGION}" \
        --backup-retention-period 30

    log "Database promotion initiated. Waiting for completion..."

    # Wait for promotion to complete
    aws rds wait db-instance-available \
        --region "${SECONDARY_REGION}" \
        --db-instance-identifier "automotive-platform-db-${SECONDARY_REGION}"

    log "Database promotion complete"
}

scale_up_secondary_resources() {
    log "Scaling up resources in ${SECONDARY_REGION}..."

    # Scale EKS node group
    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY RUN] Would scale EKS node group in ${SECONDARY_REGION}"
    else
        aws eks update-nodegroup-config \
            --region "${SECONDARY_REGION}" \
            --cluster-name "automotive-platform-cluster-${SECONDARY_REGION}" \
            --nodegroup-name "automotive-platform-general-nodes" \
            --scaling-config "minSize=10,maxSize=50,desiredSize=20"

        log "EKS node group scaling initiated"
    fi

    # Scale application deployments
    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY RUN] Would scale application deployments"
        return 0
    fi

    log "Scaling application deployments..."

    kubectl --context="${SECONDARY_REGION}" \
        scale deployment vehicle-gateway --replicas=10 -n automotive

    kubectl --context="${SECONDARY_REGION}" \
        scale deployment telemetry-processor --replicas=20 -n automotive

    kubectl --context="${SECONDARY_REGION}" \
        scale deployment analytics-api --replicas=5 -n automotive

    log "Application scaling complete"
}

update_configuration() {
    log "Updating application configuration for ${SECONDARY_REGION}..."

    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY RUN] Would update application configuration"
        return 0
    fi

    # Update ConfigMap to mark secondary as primary
    kubectl --context="${SECONDARY_REGION}" patch configmap app-config -n automotive \
        --patch "{\"data\":{\"primary_region\":\"${SECONDARY_REGION}\",\"failover_status\":\"active\"}}"

    # Restart pods to pick up new configuration
    kubectl --context="${SECONDARY_REGION}" rollout restart deployment -n automotive

    log "Configuration update complete"
}

send_alert() {
    local severity=$1
    local message=$2

    log "Sending alert: ${severity} - ${message}"

    # Send to SNS topic
    aws sns publish \
        --region us-east-1 \
        --topic-arn "arn:aws:sns:us-east-1:123456789012:automotive-platform-ops-alerts" \
        --subject "FAILOVER ${severity}: Multi-Region Automotive" \
        --message "${message}" || true

    # Send to PagerDuty (if configured)
    if [ -n "${PAGERDUTY_KEY:-}" ]; then
        curl -s -X POST "https://events.pagerduty.com/v2/enqueue" \
            -H "Content-Type: application/json" \
            -d "{
                \"routing_key\": \"${PAGERDUTY_KEY}\",
                \"event_action\": \"trigger\",
                \"payload\": {
                    \"summary\": \"${message}\",
                    \"severity\": \"${severity}\",
                    \"source\": \"failover-orchestrator\",
                    \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
                }
            }" || true
    fi
}

verify_failover() {
    log "Verifying failover success..."

    sleep 30  # Wait for DNS propagation

    # Test API endpoint
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time 10 \
        "https://api.${DOMAIN_NAME}/health" || echo "000")

    if [ "$response" -eq 200 ]; then
        log "Failover verification successful (HTTP ${response})"
        return 0
    else
        error "Failover verification failed (HTTP ${response})"
        return 1
    fi
}

# ============================================================
# Main Execution
# ============================================================

main() {
    log "=========================================="
    log "Starting automated failover procedure"
    log "Primary: ${PRIMARY_REGION}"
    log "Secondary: ${SECONDARY_REGION}"
    log "Dry Run: ${DRY_RUN}"
    log "=========================================="

    # Pre-flight checks
    log "Running pre-flight checks..."

    if ! check_region_health "${PRIMARY_REGION}"; then
        log "Primary region ${PRIMARY_REGION} failed health check"
    else
        log "WARNING: Primary region ${PRIMARY_REGION} appears healthy"
        if [ "$DRY_RUN" != "true" ]; then
            read -p "Primary region is healthy. Continue with failover? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                log "Failover cancelled by user"
                exit 0
            fi
        fi
    fi

    if ! check_region_health "${SECONDARY_REGION}"; then
        error "Secondary region ${SECONDARY_REGION} is unhealthy. Cannot failover."
        send_alert "critical" "Failover aborted: Secondary region ${SECONDARY_REGION} is unhealthy"
        exit 1
    fi

    if ! check_database_replication_lag "${SECONDARY_REGION}"; then
        error "Database replication lag too high in ${SECONDARY_REGION}"
        send_alert "critical" "Failover aborted: Database replication lag too high"
        exit 1
    fi

    if ! check_kubernetes_cluster "${SECONDARY_REGION}"; then
        error "Kubernetes cluster unhealthy in ${SECONDARY_REGION}"
        send_alert "critical" "Failover aborted: Kubernetes cluster unhealthy"
        exit 1
    fi

    log "Pre-flight checks passed"

    # Send failover initiation alert
    send_alert "critical" "Initiating automatic failover from ${PRIMARY_REGION} to ${SECONDARY_REGION}"

    # Execute failover steps
    log "Executing failover steps..."

    if ! promote_database_replica; then
        error "Database promotion failed"
        send_alert "critical" "Failover failed: Database promotion error"
        exit 1
    fi

    if ! scale_up_secondary_resources; then
        error "Resource scaling failed"
        send_alert "critical" "Failover failed: Resource scaling error"
        exit 1
    fi

    if ! update_configuration; then
        error "Configuration update failed"
        send_alert "critical" "Failover failed: Configuration update error"
        exit 1
    fi

    if ! update_dns_to_secondary; then
        error "DNS update failed"
        send_alert "critical" "Failover failed: DNS update error"
        exit 1
    fi

    # Verify failover
    if verify_failover; then
        log "=========================================="
        log "Failover complete. System running on ${SECONDARY_REGION}"
        log "Log file: ${LOG_FILE}"
        log "=========================================="

        send_alert "warning" "Failover complete. System running on ${SECONDARY_REGION}"
        exit 0
    else
        error "Failover verification failed"
        send_alert "critical" "Failover verification failed. Manual intervention required."
        exit 1
    fi
}

# Handle signals
trap 'error "Failover interrupted"; exit 130' INT TERM

# Execute main function
main "$@"
