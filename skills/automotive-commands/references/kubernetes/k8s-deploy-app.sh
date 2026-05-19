#!/bin/bash
# Kubernetes application deployment command for automotive workloads
# Supports multi-environment deployments with validation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default values
APP_NAME=""
ENVIRONMENT="development"
NAMESPACE=""
DRY_RUN=false
WAIT=true
TIMEOUT="5m"
VALIDATE_ONLY=false
MANIFESTS_DIR="${PROJECT_ROOT}/kubernetes"
HELM_CHART=""
VALUES_FILE=""

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Deploy Kubernetes application for automotive workloads

OPTIONS:
    -a, --app-name NAME          Application name (required)
    -e, --environment ENV        Environment (dev|staging|production) [default: development]
    -n, --namespace NAMESPACE    Kubernetes namespace [default: automotive-ENV]
    -d, --dry-run                Perform dry run only
    -w, --no-wait                Don't wait for deployment completion
    -t, --timeout DURATION       Deployment timeout [default: 5m]
    -v, --validate-only          Validate manifests only
    -m, --manifests-dir DIR      Manifests directory [default: kubernetes/]
    -c, --helm-chart CHART       Use Helm chart instead of manifests
    -f, --values-file FILE       Helm values file
    -h, --help                   Display this help message

EXAMPLES:
    # Deploy ADAS service to development
    $(basename "$0") -a adas-processing-service -e development

    # Deploy to production with custom namespace
    $(basename "$0") -a battery-analytics -e production -n automotive-prod

    # Dry run for staging
    $(basename "$0") -a fleet-management -e staging --dry-run

    # Deploy using Helm chart
    $(basename "$0") -a adas-service -e production -c adas-service -f values-prod.yaml

    # Validate manifests only
    $(basename "$0") -a connectivity-service --validate-only

EOF
    exit 1
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--app-name)
                APP_NAME="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -w|--no-wait)
                WAIT=false
                shift
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -v|--validate-only)
                VALIDATE_ONLY=true
                shift
                ;;
            -m|--manifests-dir)
                MANIFESTS_DIR="$2"
                shift 2
                ;;
            -c|--helm-chart)
                HELM_CHART="$2"
                shift 2
                ;;
            -f|--values-file)
                VALUES_FILE="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo -e "${RED}Error: Unknown option: $1${NC}"
                usage
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$APP_NAME" ]]; then
        echo -e "${RED}Error: Application name is required${NC}"
        usage
    fi

    # Set default namespace if not provided
    if [[ -z "$NAMESPACE" ]]; then
        NAMESPACE="automotive-${ENVIRONMENT}"
    fi
}

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Error: kubectl is not installed${NC}"
        exit 1
    fi

    # Check Helm if using Helm chart
    if [[ -n "$HELM_CHART" ]] && ! command -v helm &> /dev/null; then
        echo -e "${RED}Error: helm is not installed${NC}"
        exit 1
    fi

    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
        exit 1
    fi

    echo -e "${GREEN}Prerequisites check passed${NC}"
}

# Create namespace if not exists
ensure_namespace() {
    echo -e "${BLUE}Ensuring namespace exists: ${NAMESPACE}${NC}"

    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        echo -e "${YELLOW}Creating namespace: ${NAMESPACE}${NC}"

        kubectl create namespace "$NAMESPACE" || exit 1

        # Label namespace based on environment
        kubectl label namespace "$NAMESPACE" \
            environment="$ENVIRONMENT" \
            automotive.io/managed-by=kubernetes-platform \
            --overwrite

        # Set pod security standard
        local pss_level="baseline"
        if [[ "$ENVIRONMENT" == "production" ]]; then
            pss_level="restricted"
        fi

        kubectl label namespace "$NAMESPACE" \
            pod-security.kubernetes.io/enforce="$pss_level" \
            pod-security.kubernetes.io/audit="$pss_level" \
            pod-security.kubernetes.io/warn="$pss_level" \
            --overwrite

        echo -e "${GREEN}Namespace created${NC}"
    else
        echo -e "${GREEN}Namespace already exists${NC}"
    fi
}

# Validate Kubernetes manifests
validate_manifests() {
    echo -e "${BLUE}Validating manifests...${NC}"

    local manifest_path="${MANIFESTS_DIR}/base/${APP_NAME}"
    local overlay_path="${MANIFESTS_DIR}/overlays/${ENVIRONMENT}"

    if [[ ! -d "$manifest_path" ]]; then
        echo -e "${RED}Error: Manifest directory not found: ${manifest_path}${NC}"
        exit 1
    fi

    # Validate base manifests
    for manifest in "${manifest_path}"/*.yaml; do
        if [[ -f "$manifest" ]]; then
            echo "  Validating $(basename "$manifest")..."
            if ! kubectl apply --dry-run=client -f "$manifest" &> /dev/null; then
                echo -e "${RED}Error: Invalid manifest: ${manifest}${NC}"
                exit 1
            fi
        fi
    done

    # Validate overlay if exists
    if [[ -d "$overlay_path" ]]; then
        for manifest in "${overlay_path}"/*.yaml; do
            if [[ -f "$manifest" ]]; then
                echo "  Validating overlay $(basename "$manifest")..."
                if ! kubectl apply --dry-run=client -f "$manifest" &> /dev/null; then
                    echo -e "${RED}Error: Invalid overlay manifest: ${manifest}${NC}"
                    exit 1
                fi
            fi
        done
    fi

    echo -e "${GREEN}Manifest validation passed${NC}"
}

# Deploy using kubectl
deploy_with_kubectl() {
    echo -e "${BLUE}Deploying ${APP_NAME} to ${NAMESPACE}...${NC}"

    local apply_args="-n $NAMESPACE"

    if [[ "$DRY_RUN" == true ]]; then
        apply_args="$apply_args --dry-run=client"
    fi

    # Apply base manifests
    local manifest_path="${MANIFESTS_DIR}/base/${APP_NAME}"
    kubectl apply -f "$manifest_path" $apply_args

    # Apply overlay if exists
    local overlay_path="${MANIFESTS_DIR}/overlays/${ENVIRONMENT}"
    if [[ -d "$overlay_path" ]]; then
        kubectl apply -f "$overlay_path" $apply_args
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${GREEN}Dry run completed successfully${NC}"
        return 0
    fi

    echo -e "${GREEN}Manifests applied${NC}"
}

# Deploy using Helm
deploy_with_helm() {
    echo -e "${BLUE}Deploying ${APP_NAME} using Helm chart: ${HELM_CHART}${NC}"

    local helm_args=(
        "upgrade"
        "--install"
        "$APP_NAME"
        "$HELM_CHART"
        "--namespace" "$NAMESPACE"
        "--create-namespace"
        "--timeout" "$TIMEOUT"
    )

    if [[ -n "$VALUES_FILE" ]]; then
        helm_args+=("--values" "$VALUES_FILE")
    fi

    # Add environment-specific values
    helm_args+=(
        "--set" "environment=$ENVIRONMENT"
        "--set" "automotive.region=us-west-2"
    )

    if [[ "$DRY_RUN" == true ]]; then
        helm_args+=("--dry-run")
    fi

    if [[ "$WAIT" == true ]]; then
        helm_args+=("--wait")
    fi

    helm "${helm_args[@]}"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${GREEN}Helm dry run completed successfully${NC}"
        return 0
    fi

    echo -e "${GREEN}Helm deployment completed${NC}"
}

# Wait for deployment to be ready
wait_for_deployment() {
    if [[ "$WAIT" != true ]] || [[ "$DRY_RUN" == true ]]; then
        return 0
    fi

    echo -e "${BLUE}Waiting for deployment to be ready...${NC}"

    # Wait for deployments
    if kubectl get deployment -n "$NAMESPACE" -l "app.kubernetes.io/name=${APP_NAME}" &> /dev/null; then
        kubectl rollout status deployment \
            -n "$NAMESPACE" \
            -l "app.kubernetes.io/name=${APP_NAME}" \
            --timeout="$TIMEOUT"
    fi

    # Wait for statefulsets
    if kubectl get statefulset -n "$NAMESPACE" -l "app.kubernetes.io/name=${APP_NAME}" &> /dev/null; then
        kubectl rollout status statefulset \
            -n "$NAMESPACE" \
            -l "app.kubernetes.io/name=${APP_NAME}" \
            --timeout="$TIMEOUT"
    fi

    echo -e "${GREEN}Deployment is ready${NC}"
}

# Verify deployment health
verify_deployment() {
    if [[ "$DRY_RUN" == true ]]; then
        return 0
    fi

    echo -e "${BLUE}Verifying deployment health...${NC}"

    # Check pods
    echo "Pods:"
    kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=${APP_NAME}"

    # Check services
    echo -e "\nServices:"
    kubectl get svc -n "$NAMESPACE" -l "app.kubernetes.io/name=${APP_NAME}"

    # Check events for any warnings/errors
    echo -e "\nRecent Events:"
    kubectl get events -n "$NAMESPACE" \
        --field-selector involvedObject.name="${APP_NAME}" \
        --sort-by='.lastTimestamp' | tail -10

    echo -e "${GREEN}Deployment verification completed${NC}"
}

# Main deployment function
main() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Automotive Kubernetes Deployment${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""

    parse_args "$@"

    echo "Configuration:"
    echo "  App Name:    $APP_NAME"
    echo "  Environment: $ENVIRONMENT"
    echo "  Namespace:   $NAMESPACE"
    echo "  Dry Run:     $DRY_RUN"
    echo ""

    check_prerequisites

    if [[ "$VALIDATE_ONLY" == true ]]; then
        validate_manifests
        echo -e "${GREEN}Validation completed successfully${NC}"
        exit 0
    fi

    ensure_namespace

    if [[ -n "$HELM_CHART" ]]; then
        deploy_with_helm
    else
        validate_manifests
        deploy_with_kubectl
    fi

    wait_for_deployment
    verify_deployment

    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}Deployment completed successfully!${NC}"
    echo -e "${GREEN}======================================${NC}"
}

# Run main function
main "$@"
