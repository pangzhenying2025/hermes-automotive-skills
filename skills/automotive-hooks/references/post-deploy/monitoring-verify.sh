#!/usr/bin/env bash
# ==============================================================================
# Hook: monitoring-verify.sh
# Type: post-deploy
# Purpose: Verify monitoring dashboards and alerting are functioning after
#          deployment. Checks metrics endpoints, log aggregation, and alert
#          rules are active for the deployed service.
# ==============================================================================

set -euo pipefail

HOOK_NAME="monitoring-verify"
EXIT_CODE=0

# Configuration
DEPLOY_ENV="${DEPLOY_ENV:-staging}"
SERVICE_NAME="${SERVICE_NAME:-unknown-service}"
METRICS_ENDPOINT="${METRICS_ENDPOINT:-/actuator/prometheus}"
SERVICE_URL="${SERVICE_URL:-http://localhost:8080}"
PROMETHEUS_URL="${PROMETHEUS_URL:-}"
GRAFANA_URL="${GRAFANA_URL:-}"

# Verification settings
CHECK_METRICS_ENDPOINT=true
CHECK_LOG_SHIPPING=true
CHECK_ALERTING=true
VERIFICATION_TIMEOUT_S=30

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Track results
CHECKS_RUN=0
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_SKIPPED=0
ISSUES=()

# Record check result
record_check() {
    local check_name="$1"
    local status="$2"
    local details="${3:-}"

    CHECKS_RUN=$((CHECKS_RUN + 1))
    case "$status" in
        PASS)
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
            echo -e "${GREEN}  PASS: $check_name${NC}"
            [[ -n "$details" ]] && echo -e "${GREEN}        $details${NC}"
            ;;
        FAIL)
            CHECKS_FAILED=$((CHECKS_FAILED + 1))
            ISSUES+=("$check_name: $details")
            echo -e "${RED}  FAIL: $check_name${NC}"
            [[ -n "$details" ]] && echo -e "${RED}        $details${NC}"
            ;;
        SKIP)
            CHECKS_SKIPPED=$((CHECKS_SKIPPED + 1))
            echo -e "${YELLOW}  SKIP: $check_name - $details${NC}"
            ;;
    esac
}

# Check 1: Metrics endpoint accessible
check_metrics_endpoint() {
    if [[ "$CHECK_METRICS_ENDPOINT" != "true" ]]; then
        return 0
    fi

    echo -e "${CYAN}  Checking metrics endpoint...${NC}"

    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" \
               --connect-timeout 10 --max-time "$VERIFICATION_TIMEOUT_S" \
               "${SERVICE_URL}${METRICS_ENDPOINT}" 2>/dev/null || echo "000")

    if [[ "$response" == "200" ]]; then
        # Verify metrics content
        local body
        body=$(curl -s --connect-timeout 10 --max-time "$VERIFICATION_TIMEOUT_S" \
               "${SERVICE_URL}${METRICS_ENDPOINT}" 2>/dev/null || echo "")

        local metric_count
        metric_count=$(echo "$body" | grep -c "^[a-zA-Z]" 2>/dev/null || echo 0)

        if [[ $metric_count -gt 0 ]]; then
            record_check "Metrics Endpoint" "PASS" "$metric_count metrics exposed"

            # Check for critical metrics
            local has_jvm=false has_http=false has_custom=false
            echo "$body" | grep -q "jvm_" && has_jvm=true
            echo "$body" | grep -q "http_" && has_http=true
            echo "$body" | grep -qE "^(app_|service_|bms_|battery_)" && has_custom=true

            [[ "$has_jvm" == "true" ]] && echo -e "${GREEN}        JVM metrics: present${NC}"
            [[ "$has_http" == "true" ]] && echo -e "${GREEN}        HTTP metrics: present${NC}"
            [[ "$has_custom" == "true" ]] && echo -e "${GREEN}        Custom metrics: present${NC}"
        else
            record_check "Metrics Endpoint" "FAIL" "Endpoint returned 200 but no metrics found"
        fi
    elif [[ "$response" == "000" ]]; then
        record_check "Metrics Endpoint" "FAIL" "Connection refused or timeout"
    else
        record_check "Metrics Endpoint" "FAIL" "HTTP $response (expected 200)"
    fi
}

# Check 2: Prometheus scraping
check_prometheus_scraping() {
    if [[ -z "$PROMETHEUS_URL" ]]; then
        record_check "Prometheus Scraping" "SKIP" "PROMETHEUS_URL not configured"
        return 0
    fi

    echo -e "${CYAN}  Checking Prometheus target status...${NC}"

    local targets
    targets=$(curl -s --connect-timeout 10 \
              "${PROMETHEUS_URL}/api/v1/targets" 2>/dev/null || echo "")

    if [[ -z "$targets" ]]; then
        record_check "Prometheus Scraping" "FAIL" "Cannot reach Prometheus API"
        return 1
    fi

    # Check if our service is a target
    if echo "$targets" | grep -qi "$SERVICE_NAME"; then
        # Check if target is UP
        if echo "$targets" | grep -A5 "$SERVICE_NAME" | grep -qi '"health":"up"'; then
            record_check "Prometheus Scraping" "PASS" "Target is UP"
        else
            record_check "Prometheus Scraping" "FAIL" "Target exists but not UP"
        fi
    else
        record_check "Prometheus Scraping" "FAIL" "Service not found in Prometheus targets"
    fi
}

# Check 3: Grafana dashboard
check_grafana_dashboard() {
    if [[ -z "$GRAFANA_URL" ]]; then
        record_check "Grafana Dashboard" "SKIP" "GRAFANA_URL not configured"
        return 0
    fi

    echo -e "${CYAN}  Checking Grafana dashboard availability...${NC}"

    local dashboards
    dashboards=$(curl -s --connect-timeout 10 \
                 "${GRAFANA_URL}/api/search?query=${SERVICE_NAME}" 2>/dev/null || echo "")

    if [[ -z "$dashboards" ]] || [[ "$dashboards" == "[]" ]]; then
        record_check "Grafana Dashboard" "FAIL" "No dashboard found for $SERVICE_NAME"
    else
        local dash_count
        dash_count=$(echo "$dashboards" | grep -c '"title"' 2>/dev/null || echo 0)
        record_check "Grafana Dashboard" "PASS" "$dash_count dashboard(s) found"
    fi
}

# Check 4: Log shipping
check_log_shipping() {
    if [[ "$CHECK_LOG_SHIPPING" != "true" ]]; then
        return 0
    fi

    echo -e "${CYAN}  Checking log shipping...${NC}"

    # Check if logging is configured on the service
    local health_body
    health_body=$(curl -s --connect-timeout 10 \
                  "${SERVICE_URL}/actuator/health" 2>/dev/null || echo "")

    # Check for common log shipping indicators
    local log_configured=false

    # Check if service has structured logging
    local log_sample
    log_sample=$(curl -s --connect-timeout 5 \
                 "${SERVICE_URL}/actuator/loggers" 2>/dev/null || echo "")

    if [[ -n "$log_sample" ]] && echo "$log_sample" | grep -q "loggers"; then
        log_configured=true
    fi

    # Check local log files if accessible
    local log_dirs=("/var/log/${SERVICE_NAME}" "/var/log/cube" "/tmp/${SERVICE_NAME}.log")
    for log_dir in "${log_dirs[@]}"; do
        if [[ -d "$log_dir" ]] || [[ -f "$log_dir" ]]; then
            log_configured=true
            break
        fi
    done

    if [[ "$log_configured" == "true" ]]; then
        record_check "Log Configuration" "PASS" "Logging appears configured"
    else
        record_check "Log Configuration" "SKIP" "Cannot verify log shipping remotely"
    fi
}

# Check 5: Alert rules
check_alert_rules() {
    if [[ "$CHECK_ALERTING" != "true" ]]; then
        return 0
    fi

    if [[ -z "$PROMETHEUS_URL" ]]; then
        record_check "Alert Rules" "SKIP" "PROMETHEUS_URL not configured"
        return 0
    fi

    echo -e "${CYAN}  Checking alert rules...${NC}"

    local rules
    rules=$(curl -s --connect-timeout 10 \
            "${PROMETHEUS_URL}/api/v1/rules" 2>/dev/null || echo "")

    if [[ -z "$rules" ]]; then
        record_check "Alert Rules" "FAIL" "Cannot reach Prometheus rules API"
        return 1
    fi

    # Check for service-specific alert rules
    if echo "$rules" | grep -qi "$SERVICE_NAME"; then
        local rule_count
        rule_count=$(echo "$rules" | grep -ci "$SERVICE_NAME" 2>/dev/null || echo 0)
        record_check "Alert Rules" "PASS" "$rule_count rule(s) found for $SERVICE_NAME"
    else
        record_check "Alert Rules" "FAIL" "No alert rules found for $SERVICE_NAME"
    fi
}

# Check 6: Service uptime
check_service_uptime() {
    echo -e "${CYAN}  Checking service uptime metrics...${NC}"

    local body
    body=$(curl -s --connect-timeout 10 --max-time "$VERIFICATION_TIMEOUT_S" \
           "${SERVICE_URL}${METRICS_ENDPOINT}" 2>/dev/null || echo "")

    if [[ -z "$body" ]]; then
        record_check "Service Uptime" "SKIP" "Metrics endpoint not available"
        return 0
    fi

    # Look for uptime metric
    local uptime
    uptime=$(echo "$body" | grep -E "^(process_uptime|jvm_uptime|app_uptime)" | head -1 || echo "")

    if [[ -n "$uptime" ]]; then
        local uptime_seconds
        uptime_seconds=$(echo "$uptime" | grep -oE "[0-9.]+" | head -1 || echo "0")
        record_check "Service Uptime" "PASS" "Uptime: ${uptime_seconds}s"
    else
        record_check "Service Uptime" "SKIP" "No uptime metric found"
    fi
}

# Write verification report
write_report() {
    local results_dir="${RESULTS_DIR:-.smoke-test-results}"
    mkdir -p "$results_dir"

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local report_file="$results_dir/monitoring-verify-${DEPLOY_ENV}-$(date +%Y%m%d-%H%M%S).json"

    cat > "$report_file" << EOF
{
  "timestamp": "$timestamp",
  "environment": "$DEPLOY_ENV",
  "service": "$SERVICE_NAME",
  "checks_run": $CHECKS_RUN,
  "checks_passed": $CHECKS_PASSED,
  "checks_failed": $CHECKS_FAILED,
  "checks_skipped": $CHECKS_SKIPPED,
  "overall_result": "$([ $CHECKS_FAILED -eq 0 ] && echo "PASS" || echo "FAIL")",
  "issues": [$(printf '"%s",' "${ISSUES[@]}" 2>/dev/null | sed 's/,$//')]
}
EOF

    echo -e "${CYAN}  Report: $report_file${NC}"
}

# Main
run_verification() {
    echo -e "${YELLOW}[$HOOK_NAME] Verifying monitoring for $SERVICE_NAME ($DEPLOY_ENV)...${NC}"
    echo ""

    check_metrics_endpoint
    check_prometheus_scraping
    check_grafana_dashboard
    check_log_shipping
    check_alert_rules
    check_service_uptime

    echo ""
    write_report

    echo ""
    echo "  ================================================"
    echo "  Monitoring Verification: $CHECKS_PASSED passed, $CHECKS_FAILED failed, $CHECKS_SKIPPED skipped"
    echo "  ================================================"

    if [[ $CHECKS_FAILED -gt 0 ]]; then
        echo -e "${RED}[$HOOK_NAME] WARNING: $CHECKS_FAILED monitoring check(s) failed.${NC}"
        echo -e "${YELLOW}  Ensure monitoring is properly configured before going to production.${NC}"
        # Non-blocking - monitoring issues are warnings, not deploy blockers
        return 0
    else
        echo -e "${GREEN}[$HOOK_NAME] PASSED: Monitoring verification complete.${NC}"
        return 0
    fi
}

# Execute
run_verification
exit $EXIT_CODE
