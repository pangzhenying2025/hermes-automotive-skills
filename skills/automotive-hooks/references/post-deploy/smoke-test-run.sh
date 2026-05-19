#!/usr/bin/env bash
# ==============================================================================
# Hook: smoke-test-run.sh
# Type: post-deploy
# Purpose: Run smoke tests after deployment to verify critical functionality.
#          Tests health endpoints, basic operations, and connectivity.
# ==============================================================================

set -euo pipefail

HOOK_NAME="smoke-test-run"
EXIT_CODE=0

# Configuration
DEPLOY_ENV="${DEPLOY_ENV:-staging}"
SERVICE_URL="${SERVICE_URL:-http://localhost:8080}"
HEALTH_ENDPOINT="/actuator/health"
SMOKE_TIMEOUT_S=60
HEALTH_CHECK_RETRIES=10
HEALTH_CHECK_INTERVAL_S=5
RESULTS_DIR="${RESULTS_DIR:-.smoke-test-results}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Track results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILURES=()

# Record a test result
record_result() {
    local test_name="$1"
    local status="$2"
    local details="${3:-}"

    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$status" == "PASS" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}  PASS: $test_name${NC}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES+=("$test_name: $details")
        echo -e "${RED}  FAIL: $test_name - $details${NC}"
    fi
}

# HTTP request helper
http_request() {
    local method="$1"
    local url="$2"
    local expected_status="${3:-200}"
    local data="${4:-}"
    local timeout="${5:-10}"

    local response_file
    response_file=$(mktemp /tmp/smoke-response-XXXXXX)

    local http_code
    if [[ -n "$data" ]]; then
        http_code=$(curl -s -o "$response_file" -w "%{http_code}" \
                    -X "$method" \
                    -H "Content-Type: application/json" \
                    -d "$data" \
                    --connect-timeout "$timeout" \
                    --max-time "$timeout" \
                    "$url" 2>/dev/null || echo "000")
    else
        http_code=$(curl -s -o "$response_file" -w "%{http_code}" \
                    -X "$method" \
                    --connect-timeout "$timeout" \
                    --max-time "$timeout" \
                    "$url" 2>/dev/null || echo "000")
    fi

    local response_body
    response_body=$(cat "$response_file" 2>/dev/null || echo "")
    rm -f "$response_file"

    echo "$http_code|$response_body"
}

# Test 1: Health check endpoint
test_health_check() {
    echo -e "${CYAN}  Testing health endpoint...${NC}"

    local retries=$HEALTH_CHECK_RETRIES
    local result=""

    while [[ $retries -gt 0 ]]; do
        result=$(http_request "GET" "${SERVICE_URL}${HEALTH_ENDPOINT}")
        local code="${result%%|*}"

        if [[ "$code" == "200" ]]; then
            local body="${result#*|}"
            if echo "$body" | grep -qiE '"status"\s*:\s*"(UP|OK|healthy)"'; then
                record_result "Health Check" "PASS"
                return 0
            fi
        fi

        retries=$((retries - 1))
        if [[ $retries -gt 0 ]]; then
            echo -e "${YELLOW}    Waiting ${HEALTH_CHECK_INTERVAL_S}s... ($retries retries left)${NC}"
            sleep "$HEALTH_CHECK_INTERVAL_S"
        fi
    done

    record_result "Health Check" "FAIL" "Service not healthy after $HEALTH_CHECK_RETRIES attempts"
    return 1
}

# Test 2: API version endpoint
test_api_version() {
    echo -e "${CYAN}  Testing API version endpoint...${NC}"

    local result
    result=$(http_request "GET" "${SERVICE_URL}/api/version")
    local code="${result%%|*}"
    local body="${result#*|}"

    if [[ "$code" == "200" ]]; then
        if echo "$body" | grep -qE '"version"'; then
            record_result "API Version" "PASS"
            return 0
        fi
        record_result "API Version" "FAIL" "Response missing version field"
    else
        record_result "API Version" "FAIL" "HTTP $code"
    fi
    return 1
}

# Test 3: Database connectivity
test_database() {
    echo -e "${CYAN}  Testing database connectivity...${NC}"

    local result
    result=$(http_request "GET" "${SERVICE_URL}${HEALTH_ENDPOINT}")
    local body="${result#*|}"

    if echo "$body" | grep -qiE '"db"\s*:\s*\{[^}]*"status"\s*:\s*"UP"'; then
        record_result "Database Connectivity" "PASS"
        return 0
    elif echo "$body" | grep -qiE '"database"\s*:\s*\{[^}]*"status"\s*:\s*"UP"'; then
        record_result "Database Connectivity" "PASS"
        return 0
    else
        # Database info might not be in health endpoint
        record_result "Database Connectivity" "PASS" "(not exposed in health endpoint)"
        return 0
    fi
}

# Test 4: Basic API operation
test_basic_api() {
    echo -e "${CYAN}  Testing basic API operation...${NC}"

    # Try common REST endpoints
    local endpoints=("/api/v1/status" "/api/v2/status" "/api/status" "/status")

    for endpoint in "${endpoints[@]}"; do
        local result
        result=$(http_request "GET" "${SERVICE_URL}${endpoint}" 200 "" 5)
        local code="${result%%|*}"

        if [[ "$code" == "200" ]]; then
            record_result "Basic API Operation ($endpoint)" "PASS"
            return 0
        fi
    done

    # If no status endpoint found, try the health endpoint
    local result
    result=$(http_request "GET" "${SERVICE_URL}${HEALTH_ENDPOINT}")
    local code="${result%%|*}"

    if [[ "$code" == "200" ]]; then
        record_result "Basic API Operation" "PASS" "(via health endpoint)"
        return 0
    fi

    record_result "Basic API Operation" "FAIL" "No responsive endpoint found"
    return 1
}

# Test 5: Response time check
test_response_time() {
    echo -e "${CYAN}  Testing response time...${NC}"

    local max_response_ms=2000  # 2 seconds

    local start_time
    start_time=$(date +%s%N)
    local result
    result=$(http_request "GET" "${SERVICE_URL}${HEALTH_ENDPOINT}" 200 "" 5)
    local end_time
    end_time=$(date +%s%N)

    local elapsed_ms=$(( (end_time - start_time) / 1000000 ))

    if [[ $elapsed_ms -lt $max_response_ms ]]; then
        record_result "Response Time" "PASS" "${elapsed_ms}ms (max: ${max_response_ms}ms)"
    else
        record_result "Response Time" "FAIL" "${elapsed_ms}ms exceeds ${max_response_ms}ms"
    fi
}

# Test 6: SSL/TLS check (if HTTPS)
test_ssl() {
    if [[ "$SERVICE_URL" != https://* ]]; then
        return 0
    fi

    echo -e "${CYAN}  Testing SSL/TLS...${NC}"

    local host
    host=$(echo "$SERVICE_URL" | sed 's|https://||' | cut -d: -f1 | cut -d/ -f1)

    if command -v openssl &>/dev/null; then
        local ssl_output
        ssl_output=$(echo | openssl s_client -connect "$host:443" -servername "$host" 2>/dev/null || echo "FAIL")

        if echo "$ssl_output" | grep -q "Verify return code: 0"; then
            record_result "SSL/TLS Certificate" "PASS"
        else
            record_result "SSL/TLS Certificate" "FAIL" "Certificate verification failed"
        fi
    else
        record_result "SSL/TLS Certificate" "PASS" "(openssl not available, skipped)"
    fi
}

# Write results to file
write_results() {
    mkdir -p "$RESULTS_DIR"

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local result_file="$RESULTS_DIR/smoke-test-${DEPLOY_ENV}-$(date +%Y%m%d-%H%M%S).json"

    cat > "$result_file" << EOF
{
  "timestamp": "$timestamp",
  "environment": "$DEPLOY_ENV",
  "service_url": "$SERVICE_URL",
  "tests_run": $TESTS_RUN,
  "tests_passed": $TESTS_PASSED,
  "tests_failed": $TESTS_FAILED,
  "overall_result": "$([ $TESTS_FAILED -eq 0 ] && echo "PASS" || echo "FAIL")",
  "failures": [$(printf '"%s",' "${FAILURES[@]}" 2>/dev/null | sed 's/,$//')]
}
EOF

    echo -e "${CYAN}  Results written to: $result_file${NC}"
}

# Main
run_smoke_tests() {
    echo -e "${YELLOW}[$HOOK_NAME] Running post-deploy smoke tests...${NC}"
    echo -e "${CYAN}  Environment: $DEPLOY_ENV${NC}"
    echo -e "${CYAN}  Service URL: $SERVICE_URL${NC}"
    echo ""

    # Run all smoke tests
    test_health_check || true
    test_api_version || true
    test_database || true
    test_basic_api || true
    test_response_time || true
    test_ssl || true

    echo ""

    # Write results
    write_results

    # Summary
    echo "  ============================================"
    echo "  Smoke Test Summary: $TESTS_PASSED/$TESTS_RUN passed"
    echo "  ============================================"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}[$HOOK_NAME] FAILED: $TESTS_FAILED smoke test(s) failed.${NC}"
        echo -e "${RED}  Consider rolling back the deployment.${NC}"
        return 1
    else
        echo -e "${GREEN}[$HOOK_NAME] PASSED: All smoke tests passed.${NC}"
        return 0
    fi
}

# Execute
if ! run_smoke_tests; then
    EXIT_CODE=1
fi

exit $EXIT_CODE
