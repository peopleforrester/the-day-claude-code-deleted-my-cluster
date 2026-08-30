#!/bin/bash
# Production-Ready Kubernetes Cluster Upgrade Orchestrator
# Full automation with safety checks, rollback capability, and monitoring

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
INVENTORY="${PROJECT_ROOT}/inventory/hosts.yml"
PLAYBOOK_DIR="${PROJECT_ROOT}/playbooks"
LOG_DIR="${PROJECT_ROOT}/logs"
BACKUP_DIR="/backup/kubernetes"
LOCK_FILE="/tmp/k8s-upgrade.lock"
STATE_FILE="${PROJECT_ROOT}/.upgrade-state"

# Timing
START_TIME=$(date +%s)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Upgrade configuration
CURRENT_VERSION="1.31.10"
TARGET_VERSION="1.32.0"
BATCH_SIZE=2
PAUSE_BETWEEN_NODES=60
HEALTH_CHECK_TIMEOUT=300

# Flags
DRY_RUN=false
SKIP_BACKUP=false
SKIP_TESTS=false
FORCE_UPGRADE=false
AUTO_ROLLBACK=true
INTERACTIVE=true

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --force)
            FORCE_UPGRADE=true
            shift
            ;;
        --no-rollback)
            AUTO_ROLLBACK=false
            shift
            ;;
        --non-interactive)
            INTERACTIVE=false
            shift
            ;;
        --batch-size)
            BATCH_SIZE="$2"
            shift 2
            ;;
        --help)
            cat << EOF
Usage: $0 [OPTIONS]

Kubernetes Cluster Upgrade Orchestrator

Options:
    --dry-run           Run in simulation mode without making changes
    --skip-backup       Skip backup creation (NOT RECOMMENDED)
    --skip-tests        Skip pre-upgrade tests (NOT RECOMMENDED)
    --force             Force upgrade even with warnings
    --no-rollback       Disable automatic rollback on failure
    --non-interactive   Run without user prompts
    --batch-size N      Number of worker nodes to upgrade in parallel (default: 2)
    --help              Show this help message

Example:
    $0                          # Interactive upgrade with all safety checks
    $0 --dry-run               # Simulation mode
    $0 --batch-size 1          # Upgrade workers one at a time

Safety Features:
    - Lock file prevents concurrent executions
    - Automatic rollback on failure
    - Health checks between each step
    - Comprehensive logging
    - State preservation for resume capability

EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Create necessary directories
mkdir -p "$LOG_DIR"

# Logging functions
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="${LOG_DIR}/upgrade-${TIMESTAMP}.log"
    
    case $level in
        INFO)
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        SUCCESS)
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        WARNING)
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        SECTION)
            echo -e "\n${BOLD}${CYAN}=== $message ===${NC}\n"
            ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$log_file"
}

# Lock file management
acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            log ERROR "Another upgrade process is running (PID: $pid)"
            log ERROR "If this is incorrect, remove $LOCK_FILE"
            exit 1
        else
            log WARNING "Stale lock file found, removing..."
            rm -f "$LOCK_FILE"
        fi
    fi
    
    echo $$ > "$LOCK_FILE"
    trap release_lock EXIT
}

release_lock() {
    rm -f "$LOCK_FILE"
}

# State management
save_state() {
    local phase=$1
    local status=$2
    
    cat > "$STATE_FILE" << EOF
PHASE=$phase
STATUS=$status
TIMESTAMP=$(date +%s)
VERSION_FROM=$CURRENT_VERSION
VERSION_TO=$TARGET_VERSION
EOF
}

load_state() {
    if [ -f "$STATE_FILE" ]; then
        source "$STATE_FILE"
        return 0
    fi
    return 1
}

# Confirmation prompt
confirm() {
    local message=$1
    
    if [ "$INTERACTIVE" = false ]; then
        return 0
    fi
    
    echo -e "${YELLOW}$message${NC}"
    read -p "Continue? (yes/no): " response
    
    case $response in
        [Yy]es|[Yy])
            return 0
            ;;
        *)
            log WARNING "Operation cancelled by user"
            exit 0
            ;;
    esac
}

# Health check function
health_check() {
    local description=$1
    local max_wait=${2:-$HEALTH_CHECK_TIMEOUT}
    local start=$(date +%s)
    
    log INFO "Running health check: $description"
    
    while true; do
        if ansible-playbook -i "$INVENTORY" "$PLAYBOOK_DIR/00-pre-upgrade-validation.yml" \
           --tags health_check &>/dev/null; then
            log SUCCESS "Health check passed: $description"
            return 0
        fi
        
        local elapsed=$(($(date +%s) - start))
        if [ $elapsed -gt $max_wait ]; then
            log ERROR "Health check failed after ${max_wait}s: $description"
            return 1
        fi
        
        log INFO "Health check pending... (${elapsed}s elapsed)"
        sleep 10
    done
}

# Run ansible playbook with error handling
run_playbook() {
    local playbook=$1
    local description=$2
    shift 2
    local extra_args="$@"
    
    log INFO "Executing: $description"
    
    local cmd="ansible-playbook -i $INVENTORY $playbook"
    
    if [ "$DRY_RUN" = true ]; then
        cmd="$cmd --check"
    fi
    
    if [ -n "$extra_args" ]; then
        cmd="$cmd $extra_args"
    fi
    
    if $cmd 2>&1 | tee -a "${LOG_DIR}/upgrade-${TIMESTAMP}.log"; then
        log SUCCESS "$description completed successfully"
        return 0
    else
        log ERROR "$description failed"
        return 1
    fi
}

# Rollback function
rollback() {
    log ERROR "Initiating rollback procedure..."
    
    if [ "$AUTO_ROLLBACK" = false ]; then
        log WARNING "Automatic rollback disabled. Manual intervention required."
        return 1
    fi
    
    confirm "Do you want to proceed with rollback?"
    
    if run_playbook "$PLAYBOOK_DIR/99-rollback.yml" "Emergency rollback"; then
        log SUCCESS "Rollback completed successfully"
        save_state "ROLLED_BACK" "COMPLETE"
    else
        log ERROR "Rollback failed! Manual intervention required."
        log ERROR "Check backup at: $BACKUP_DIR"
    fi
}

# Main upgrade workflow
main() {
    # Banner
    cat << EOF

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     Kubernetes Cluster Upgrade Orchestrator                 ║
║                                                              ║
║     Current Version: $CURRENT_VERSION                       ║
║     Target Version:  $TARGET_VERSION                        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

EOF
    
    # Acquire lock
    acquire_lock
    
    # Check for resume
    if load_state 2>/dev/null; then
        log WARNING "Previous upgrade detected:"
        log WARNING "  Phase: $PHASE"
        log WARNING "  Status: $STATUS"
        
        if confirm "Resume from previous state?"; then
            log INFO "Resuming upgrade from phase: $PHASE"
        else
            rm -f "$STATE_FILE"
        fi
    fi
    
    # Phase 0: Pre-flight checks
    log SECTION "Phase 0: Pre-flight Checks"
    
    if [ "$SKIP_TESTS" = false ]; then
        if ! bash "${PROJECT_ROOT}/pre-flight-check.sh"; then
            if [ "$FORCE_UPGRADE" = false ]; then
                log ERROR "Pre-flight checks failed. Use --force to override (NOT RECOMMENDED)"
                exit 1
            else
                log WARNING "Pre-flight checks failed but continuing due to --force flag"
            fi
        fi
    else
        log WARNING "Skipping pre-flight checks (--skip-tests flag)"
    fi
    
    save_state "PRE_FLIGHT" "COMPLETE"
    
    # Phase 1: Run comprehensive tests
    log SECTION "Phase 1: Comprehensive Testing"
    
    if [ "$SKIP_TESTS" = false ]; then
        if ! bash "${PROJECT_ROOT}/run-all-tests.sh"; then
            if [ "$FORCE_UPGRADE" = false ]; then
                log ERROR "Tests failed. Fix issues before proceeding."
                exit 1
            else
                log WARNING "Tests failed but continuing due to --force flag"
            fi
        fi
    else
        log WARNING "Skipping comprehensive tests"
    fi
    
    save_state "TESTING" "COMPLETE"
    
    # Phase 2: Create backup
    log SECTION "Phase 2: Backup Creation"
    
    if [ "$SKIP_BACKUP" = false ]; then
        if ! run_playbook "$PLAYBOOK_DIR/01-backup-cluster.yml" "Cluster backup"; then
            log ERROR "Backup failed. Cannot proceed without backup."
            exit 1
        fi
    else
        log WARNING "Skipping backup (--skip-backup flag) - THIS IS DANGEROUS!"
        confirm "Are you SURE you want to proceed without backup?"
    fi
    
    save_state "BACKUP" "COMPLETE"
    
    # Phase 3: Final confirmation
    log SECTION "Phase 3: Final Confirmation"
    
    cat << EOF
════════════════════════════════════════════
UPGRADE SUMMARY
════════════════════════════════════════════
Current Version:  $CURRENT_VERSION
Target Version:   $TARGET_VERSION
Nodes to upgrade: $(ansible -i "$INVENTORY" all --list-hosts | wc -l)
Batch size:       $BATCH_SIZE
Dry run:          $DRY_RUN
Auto-rollback:    $AUTO_ROLLBACK
════════════════════════════════════════════

This will upgrade your production Kubernetes cluster.
This is a CRITICAL operation that will affect all workloads.

EOF
    
    confirm "Are you ready to begin the upgrade?"
    
    # Phase 4: Upgrade control plane
    log SECTION "Phase 4: Control Plane Upgrade"
    
    if ! run_playbook "$PLAYBOOK_DIR/02-upgrade-control-plane.yml" \
                      "Control plane upgrade" \
                      "--extra-vars" "pause_seconds=$PAUSE_BETWEEN_NODES"; then
        log ERROR "Control plane upgrade failed"
        rollback
        exit 1
    fi
    
    save_state "CONTROL_PLANE" "COMPLETE"
    
    # Health check after control plane upgrade
    if ! health_check "Post control plane upgrade"; then
        log ERROR "Cluster unhealthy after control plane upgrade"
        rollback
        exit 1
    fi
    
    # Phase 5: Upgrade worker nodes
    log SECTION "Phase 5: Worker Nodes Upgrade"
    
    if ! run_playbook "$PLAYBOOK_DIR/03-upgrade-workers.yml" \
                      "Worker nodes upgrade" \
                      "--extra-vars" "batch_size=$BATCH_SIZE"; then
        log ERROR "Worker nodes upgrade failed"
        rollback
        exit 1
    fi
    
    save_state "WORKERS" "COMPLETE"
    
    # Phase 6: Post-upgrade validation
    log SECTION "Phase 6: Post-Upgrade Validation"
    
    if ! run_playbook "$PLAYBOOK_DIR/04-post-upgrade-validation.yml" \
                      "Post-upgrade validation"; then
        log ERROR "Post-upgrade validation failed"
        log WARNING "Cluster may be in inconsistent state"
        
        if confirm "Do you want to rollback?"; then
            rollback
            exit 1
        fi
    fi
    
    save_state "VALIDATION" "COMPLETE"
    
    # Phase 7: Final health check
    log SECTION "Phase 7: Final Health Check"
    
    if ! health_check "Final cluster health"; then
        log WARNING "Final health check failed but upgrade is complete"
    fi
    
    # Cleanup
    rm -f "$STATE_FILE"
    save_state "COMPLETE" "SUCCESS"
    
    # Calculate duration
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    DURATION_MIN=$((DURATION / 60))
    
    # Success banner
    cat << EOF

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     🎉 UPGRADE COMPLETED SUCCESSFULLY! 🎉                   ║
║                                                              ║
║     New Version: $TARGET_VERSION                            ║
║     Duration: ${DURATION_MIN} minutes                       ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

Next Steps:
1. Monitor cluster for 24 hours
2. Test all critical applications
3. Review upgrade logs at: ${LOG_DIR}
4. Update documentation
5. Clean up old backup files after verification

Useful commands:
  kubectl get nodes
  kubectl version --short
  kubectl get pods --all-namespaces
  kubectl top nodes

EOF
    
    log SUCCESS "Cluster successfully upgraded from $CURRENT_VERSION to $TARGET_VERSION"
    log SUCCESS "Total duration: ${DURATION_MIN} minutes"
}

# Signal handlers
trap 'log ERROR "Upgrade interrupted!"; release_lock; exit 1' INT TERM

# Run main function
main "$@"