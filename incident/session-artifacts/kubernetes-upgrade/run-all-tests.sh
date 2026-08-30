#!/bin/bash
# Master Test Runner for Kubernetes Upgrade
# Run all tests and generate comprehensive report

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
INVENTORY="${PROJECT_ROOT}/inventory/hosts.yml"
TEST_DIR="${PROJECT_ROOT}/tests"
REPORT_DIR="${PROJECT_ROOT}/test-reports"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="${REPORT_DIR}/test-report-${TIMESTAMP}.html"
LOG_FILE="${REPORT_DIR}/test-log-${TIMESTAMP}.log"

# Test configuration
PARALLEL_TESTS=false
STOP_ON_FAILURE=true
VERBOSE=false
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --parallel)
            PARALLEL_TESTS=true
            shift
            ;;
        --continue-on-failure)
            STOP_ON_FAILURE=false
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --parallel             Run tests in parallel where possible"
            echo "  --continue-on-failure  Continue testing even if a test fails"
            echo "  --verbose, -v          Enable verbose output"
            echo "  --dry-run              Run tests in check mode"
            echo "  --help, -h             Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create report directory
mkdir -p "$REPORT_DIR"

# Initialize report
cat > "$REPORT_FILE" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Kubernetes Upgrade Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .header { background: #2196F3; color: white; padding: 20px; border-radius: 5px; }
        .summary { background: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .test-section { background: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .pass { color: #4CAF50; font-weight: bold; }
        .fail { color: #F44336; font-weight: bold; }
        .warning { color: #FF9800; font-weight: bold; }
        .test-result { padding: 10px; margin: 5px 0; border-left: 4px solid #ddd; }
        .test-pass { border-left-color: #4CAF50; background: #f1f8f4; }
        .test-fail { border-left-color: #F44336; background: #fef1f1; }
        .test-skip { border-left-color: #FF9800; background: #fff8f1; }
        .metrics { display: flex; justify-content: space-around; }
        .metric { text-align: center; padding: 20px; }
        .metric-value { font-size: 2em; font-weight: bold; }
        .metric-label { color: #666; margin-top: 10px; }
        pre { background: #f4f4f4; padding: 10px; border-radius: 3px; overflow-x: auto; }
        .timestamp { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Kubernetes Upgrade Test Report</h1>
        <p>Generated: TIMESTAMP_PLACEHOLDER</p>
    </div>
EOF

echo "TIMESTAMP_PLACEHOLDER" | sed "s/TIMESTAMP_PLACEHOLDER/$(date '+%Y-%m-%d %H:%M:%S')/" >> "$REPORT_FILE"

# Function to log messages
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
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
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Function to run a test playbook
run_test() {
    local test_name=$1
    local test_file=$2
    local test_description=$3
    local start_time=$(date +%s)
    
    log INFO "Running test: $test_name"
    log INFO "Description: $test_description"
    
    # Build ansible-playbook command
    local cmd="ansible-playbook -i $INVENTORY $test_file"
    
    if [ "$VERBOSE" = true ]; then
        cmd="$cmd -vv"
    fi
    
    if [ "$DRY_RUN" = true ]; then
        cmd="$cmd --check"
    fi
    
    # Run the test
    if $cmd >> "$LOG_FILE" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log SUCCESS "Test $test_name PASSED (${duration}s)"
        
        # Add to HTML report
        cat >> "$REPORT_FILE" << EOF
    <div class="test-result test-pass">
        <h3>✓ $test_name</h3>
        <p>$test_description</p>
        <p class="timestamp">Duration: ${duration}s</p>
    </div>
EOF
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log ERROR "Test $test_name FAILED (${duration}s)"
        
        # Add to HTML report
        cat >> "$REPORT_FILE" << EOF
    <div class="test-result test-fail">
        <h3>✗ $test_name</h3>
        <p>$test_description</p>
        <p class="timestamp">Duration: ${duration}s</p>
        <p>Check log file for details: $LOG_FILE</p>
    </div>
EOF
        
        if [ "$STOP_ON_FAILURE" = true ]; then
            log ERROR "Stopping test execution due to failure"
            exit 1
        fi
        
        return 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    log INFO "Checking prerequisites..."
    
    # Check for Ansible
    if ! command -v ansible &> /dev/null; then
        log ERROR "Ansible is not installed"
        exit 1
    fi
    
    # Check for kubectl
    if ! command -v kubectl &> /dev/null; then
        log WARNING "kubectl is not installed - some tests may fail"
    fi
    
    # Check inventory file
    if [ ! -f "$INVENTORY" ]; then
        log ERROR "Inventory file not found: $INVENTORY"
        exit 1
    fi
    
    # Test ansible connectivity
    if ! ansible all -i "$INVENTORY" -m ping --one-line &> /dev/null; then
        log ERROR "Cannot connect to all hosts. Please check SSH configuration."
        exit 1
    fi
    
    log SUCCESS "Prerequisites check passed"
}

# Main test execution
main() {
    echo "==============================================="
    echo "Kubernetes Upgrade Test Suite"
    echo "==============================================="
    echo "Timestamp: $(date)"
    echo "Test Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "LIVE")"
    echo "Inventory: $INVENTORY"
    echo "Report: $REPORT_FILE"
    echo "==============================================="
    echo ""
    
    # Initialize counters
    TOTAL_TESTS=0
    PASSED_TESTS=0
    FAILED_TESTS=0
    SKIPPED_TESTS=0
    
    # Check prerequisites
    check_prerequisites
    
    # Start test summary in report
    cat >> "$REPORT_FILE" << EOF
    <div class="summary">
        <h2>Test Execution Summary</h2>
        <div class="metrics">
EOF
    
    # Phase 1: Prerequisites and Environment Tests
    echo ""
    echo "=== PHASE 1: Prerequisites and Environment ==="
    echo ""
    
    if [ -f "$TEST_DIR/01-test-prerequisites.yml" ]; then
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        if run_test "Prerequisites Test" \
                    "$TEST_DIR/01-test-prerequisites.yml" \
                    "Verify all prerequisites are met"; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    fi
    
    # Phase 2: Cluster Health Tests
    echo ""
    echo "=== PHASE 2: Cluster Health ==="
    echo ""
    
    if [ -f "$TEST_DIR/02-test-cluster-health.yml" ]; then
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        if run_test "Cluster Health Test" \
                    "$TEST_DIR/02-test-cluster-health.yml" \
                    "Comprehensive cluster health verification"; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    fi
    
    # Phase 3: Upgrade Simulation Tests
    echo ""
    echo "=== PHASE 3: Upgrade Simulation ==="
    echo ""
    
    if [ -f "$TEST_DIR/03-test-upgrade-simulation.yml" ]; then
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        if run_test "Upgrade Simulation Test" \
                    "$TEST_DIR/03-test-upgrade-simulation.yml" \
                    "Dry-run upgrade process validation"; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    fi
    
    # Phase 4: Component Tests
    echo ""
    echo "=== PHASE 4: Component Tests ==="
    echo ""
    
    # Test connectivity
    if [ -f "$TEST_DIR/test_connectivity.yml" ]; then
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        if run_test "Connectivity Test" \
                    "$TEST_DIR/test_connectivity.yml" \
                    "Test network connectivity between nodes"; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    fi
    
    # Test workloads
    if [ -f "$TEST_DIR/test_workloads.yml" ]; then
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        if run_test "Workload Test" \
                    "$TEST_DIR/test_workloads.yml" \
                    "Test sample workload deployment"; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    fi
    
    # Complete the HTML report
    cat >> "$REPORT_FILE" << EOF
            <div class="metric">
                <div class="metric-value">$TOTAL_TESTS</div>
                <div class="metric-label">Total Tests</div>
            </div>
            <div class="metric">
                <div class="metric-value pass">$PASSED_TESTS</div>
                <div class="metric-label">Passed</div>
            </div>
            <div class="metric">
                <div class="metric-value fail">$FAILED_TESTS</div>
                <div class="metric-label">Failed</div>
            </div>
            <div class="metric">
                <div class="metric-value warning">$SKIPPED_TESTS</div>
                <div class="metric-label">Skipped</div>
            </div>
        </div>
        <p>Success Rate: $(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)%</p>
    </div>
    
    <div class="test-section">
        <h2>Recommendations</h2>
EOF
    
    # Generate recommendations based on results
    if [ $FAILED_TESTS -eq 0 ]; then
        cat >> "$REPORT_FILE" << EOF
        <p class="pass">✓ All tests passed! The cluster is ready for upgrade.</p>
        <ul>
            <li>Run the backup playbook before proceeding</li>
            <li>Schedule a maintenance window</li>
            <li>Notify stakeholders</li>
            <li>Execute upgrade during low-traffic period</li>
        </ul>
EOF
    else
        cat >> "$REPORT_FILE" << EOF
        <p class="fail">✗ Some tests failed. Please address the issues before upgrading.</p>
        <ul>
            <li>Review the failed tests in detail</li>
            <li>Check the log file: $LOG_FILE</li>
            <li>Fix identified issues</li>
            <li>Re-run the test suite</li>
        </ul>
EOF
    fi
    
    cat >> "$REPORT_FILE" << EOF
    </div>
</body>
</html>
EOF
    
    # Final summary
    echo ""
    echo "==============================================="
    echo "Test Execution Complete"
    echo "==============================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    echo -e "Skipped: ${YELLOW}$SKIPPED_TESTS${NC}"
    echo "Success Rate: $(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)%"
    echo ""
    echo "Reports:"
    echo "  HTML Report: $REPORT_FILE"
    echo "  Log File: $LOG_FILE"
    echo "==============================================="
    
    # Exit with appropriate code
    if [ $FAILED_TESTS -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"