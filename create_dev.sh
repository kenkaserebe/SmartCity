#!/usr/bin/bash

# =============================================================================
# SmartCity - Dev Infrastructure Deployment
# =============================================================================
#
# Deploys the Dev infrastructure components sequentially:
# 
# 1. VPC
# 2. Security Groups
# 3. S3
# 4. IAM
# 5. EKS
# 6. RDS
# 7. SQS
# 8. Monitoring
# 9. Application Deployment
#
# Features:
#   - Sequential deployment
#   - Stops immediately if a component fails
#   - Coloured terminal output
#   - Timestamps
#   - Per-component deployment duration
#   - Total deployment duration
#   - Full deployment logging
#   - Live output displayed in terminal and written to log
#   - Separate log file for every deployment
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

# =============================================================================
# COLOUR PALETTE
# =============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1M'
NC='\033[0m'

# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEV_DIR="${SCRIPT_DIR}/environments/dev"

# =============================================================================

LOG_DIR="${SCRIPT_DIR}/logs/dev"
TIMESTAMP="$(date '+%Y-%m-%d_%H%M%S')"
LOG_FILE="${LOG_DIR}/deployment-${TIMESTAMP}.log"

# =============================================================================

# Infrastructure components in creation/dependency order.
COMPONENTS=(
    "vpc"
    "security-groups"
    "s3"
    "iam"
    "eks"
    "rds"
    "sqs"
    "monitoring"
    "application-deployment"
)

# =============================================================================
# FUNCTIONS
# =============================================================================

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

print_header() {
    echo
    echo -e "${BLUE}===========================================================${NC}"
    echo -e "{BLUE}$1${NC}"
    echo -e "${BLUE}===========================================================${NC}"
    echo
}

print_section() {
    echo
    echo -e "${CYAN}-----------------------------------------------------------${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}-----------------------------------------------------------${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

format_duration() {
    local seconds="$1"
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local remaining_seconds=$((seconds % 60))

    if [[ "${hours}" -gt 0 ]]; then
        printf "%dh %dm %ds" \
            "${hours}" \
            "${minutes}" \
            "${remaining_seconds}"

    elif [[ "${minutes}" -gt 0 ]]; then
        printf "%dm %ds" \
            "${minutes}" \
            "${remaining_seconds}"

    else
        printf "%ds" "${remaining_seconds}"
    fi
}


# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================

print_header "SmartCity - Dev Infrastructure Deployment"

echo -e "${BOLD}Started:${NC} $(timestamp)"
echo -e "${BOLD}Dev directory:${NC} ${DEV_DIR}"
echo -e "${BOLD}Log file:${NC} ${LOG_FILE}"
echo

# =============================================================================
# CHECK TERRAGRUNT
# =============================================================================

if ! command -v terragrunt >/dev/null 2>&1; then
    print_error "Terragrunt is not installed or not in PATH."

    exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
    print_error "Terraform is not installed or not in PATH."

    exit 1
fi


# =============================================================================
# CHECK DEV DIRECTORY
# =============================================================================


if [[ ! -d "${DEV_DIR}" ]]; then
    print_error "Dev environment directory does not exist:"
    echo " ${DEV_DIR}"
    exit 1
fi


# =============================================================================
# CREATE LOG DIRECTORY
# =============================================================================

mkdir -p "${LOG_DIR}"


# =============================================================================
# START LOGGING
# =============================================================================

{
    echo "===================================================="
    echo " SmartCity - Dev Infrastructure Deployment"
    echo "===================================================="
    echo
    echo "Started:  $(timestamp)"
    echo "Dev directory: ${DEV_DIR}"
    echo "Log file: ${LOG_FILE}"
    echo
    echo "Components:"
    printf ' -%s\n' "${COMPONENTS[0]}"
    echo
    echo "====================================================="
    echo
} | tee -a "${LOG_FILE}"


# =============================================================================
# Deployment
# =============================================================================

DEPLOYMENT_START="$(date +%s)"

TOTAL_COMPONENTS="${#COMPONENTS[0]}"
COMPLETED_COMPONENTS=0

for component in "${COMPONENTS[0]}"; do
    COMPONENT_DIR="${DEV_DIR}/${component}"

    COMPONENT_START="$(date +%s)"

    # -------------------------------------------------------------------------
    # Component header
    # -------------------------------------------------------------------------

    print_section "Deploying: ${component}"

    {
        echo
        echo "-----------------------------------------------------------------"
        echo "Deploying: ${component}"
        echo "Started:   $(timestamp)"
        echo "Directory: ${COMPONENT_DIR}"
        echo "-----------------------------------------------------------------"
        echo
    } | tee -a "${LOG_FILE}"

    # -------------------------------------------------------------------------
    # Check component directory
    # -------------------------------------------------------------------------

    if [[ ! -d "${COMPONENT_DIR}" ]]; then

        print_error "Directory does not exist:"
        echo " ${COMPONENT_DIR}"

        {
            echo
            echo "ERROR: Directory does not exist:"
            echo " ${COMPONENT_DIR}"
            echo
        } | tee -a "${LOG_FILE}"

        print_error "Deployment stopped."

        {
            echo
            echo "DEPLOYMENT FAILED"
            echo "Failed component: ${component}"
            echo "Reason: Component directory does not exist."
            echo "Finished: $(timestamp)"
            echo
        } | tee -a "${LOG_FILE}"

        exit 1
    fi

    # -------------------------------------------------------------------------
    # Check Terragrunt configuration
    # -------------------------------------------------------------------------

    if [[ ! -f "${COMPONENT_DIR}/terragrunt.hcl" ]]; then
        print_error "terragrunt.hcl does not exist:"
        echo " ${COMPONENT_DIR}/terragrunt.hcl"

        {
            echo
            echo "ERROR: terragrunt.hcl does not exist:"
            echo " ${COMPONENT_DIR}/terragrunt.hcl"
            echo
        } | tee -a "${LOG_FILE}"

        print_error "Deployment stopped."

        {
            echo
            echo "DEPLOYMENT FAILED"
            echo "Failed component: ${component}"
            echo "Reason: terragrunt.hcl does not exist."
            echo "Finished: $(timestamp)"
            echo
        } | tee -a "${LOG_FILE}"

        exit 1
    fi


    # -------------------------------------------------------------------------
    # Move into component directory
    # -------------------------------------------------------------------------

    cd "${COMPONENT_DIR}"

    # -------------------------------------------------------------------------
    # Run Terragrunt
    # -------------------------------------------------------------------------

    if [[ "${component}" == "vpc" ]]; then

        COMMAND=(terragrunt --non-interactive apply --backend-bootstrap --auto-approve)
    else
        COMMAND=(terragrunt apply --auto-approve)
    fi

    echo -e "${YELLOW}Running:${NC}"
    echo " ${COMMAND[*]}"
    echo

    {
        echo "Running:"
        echo " ${COMMAND[*]}"
        echo
    } | tee -a "${LOG_FILE}"



    # --------------------------------------------------------------------------
    # Execute Terragrunt
    #
    # pipefail is enabled because of:
    #
    # set -euo pipefail
    #
    # This ensures that if Terragrunt fails, the pipeline also fails even though
    # 'tee' itself suceeds.
    # ---------------------------------------------------------------------------

    if "${COMMAND[0]}" 2>&1 | tee -a "${LOG_FILE}"; then
        
        COMPONENT_END="$(date +%s)"
        COMPONENT_DURATION=$((COMPONENT_END - COMPONENT_START))

        COMPLETED_COMPONENTS=$((COMPLETED_COMPONENTS + 1))

        echo

        print_success "${component} completed successfully."
        echo " Duration: $(format_duration "${COMPONENT_DURATION}")"
        echo " Progress: ${COMPLETED_COMPONENTS}/${TOTAL_COMPONENTS}"

        {
            echo
            echo "✓ ${component} completed successfully."
            echo "  Finished: $(timestamp)"
            echo "  Duration: $(format_duration "${COMPONENT_DURATION}")"
            echo "  Progress: ${COMPLETED_COMPONENTS}/${TOTAL_COMPONENTS}"
            echo
        } | tee -a "${LOG_FILE}"

    else

        COMPONENT_END="$(date +%s)"
        COMPONENT_DURATION=$((COMPONENT_END - COMPONENT_START))

        echo

        print_error "${component} FAILED."
        echo "  Duration: $(format_duration "${COMPONENT_DURATION}")"
        echo "  Deployment has been stopped."
        echo
        echo "  Log: ${LOG_FILE}"

        {
            echo
            echo "============================================================="
            echo "DEPLOYMENT FAILED"
            echo "============================================================="
            echo
            echo "Failed component: ${component}"
            echo "Finished:         ${timestamp}"
            echo "Duration:         $(format_duration "${COMPONENT_DURATION}")"
            echo
            echo "The deployment has been stopped."
            echo
            echo "Log file:"
            echo "  ${LOG_FILE}"
            echo
            echo "============================================================="
        } | tee -a "${LOG_FILE}"

        exit 1
    fi

done

# =====================================================================================
# DEPLOYMENT COMPLETE
# =====================================================================================

DEPLOYMENT_END="$(date +%s)"

TOTAL_DURATION=$((DEPLOYMENT_END - DEPLOYMENT_START))

print_header "DEV DEPLOYMENT COMPLETE"

echo -e "${GREEN}${BOLD}Status:${NC}    SUCCESS"
echo -e "${BOLD}Started:${NC}           ${TIMESTAMP}"
echo -e "${BOLD}Finished:${NC}          $(timestamp)"
echo -e "${BOLD}Duration:${NC}          $(format_duration "${TOTAL_DURATION}")"
echo -e "${BOLD}Components:${NC}        ${COMPLETED_COMPONENTS}/${TOTAL_COMPONENTS}"
echo -e "${BOLD}Log:${NC}               ${LOG_FILE}"

echo

{
    echo
    echo "=============================================================================="
    echo "DEV DEPLOYMENT COMPLETE"
    echo "=============================================================================="
    echo
    echo "Status:       Success"
    echo "Started:      ${TIMESTAMP}"
    echo "Finished:     $(timestamp)"
    echo "Duration:     $(format_duration "${TOTAL_DURATION}")"
    echo "Components:   ${COMPLETED_COMPONENTS}/${TOTAL_COMPONENTS}"
    echo
    echo "Log file:"
    echo " ${LOG_FILE}"
    echo
    echo "==============================================================================="
} | tee -a "${LOG_FILE}"

echo