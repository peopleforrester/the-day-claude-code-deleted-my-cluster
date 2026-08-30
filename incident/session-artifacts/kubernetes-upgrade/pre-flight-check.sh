#!/bin/bash
# Pre-flight Check Script for Kubernetes Upgrade
# Comprehensive validation before starting upgrade process

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBECONFIG=${KUBECONFIG:-/etc/kubernetes/admin.conf}
REQUIRED_COMMANDS="kubectl kubeadm etcdctl ansible ansible-playbook"
MIN_DISK_SPACE_GB=10
MIN_MEMORY_GB=2
BACKUP_DIR="/backup/kubernetes"

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Functions
check() {
    local description=$1
    local command=$2
    
    echo -n "Checking: $description... "
    
    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC}"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        return 1
    fi
}

check_warn() {
    local description=$1
    local command=$2
    
    echo -n "Checking: $description... "
    
    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        return 0
    else
        echo -e "${YELLOW}⚠${NC} (Warning)"
        CHECKS_WARNING=$((CHECKS_WARNING + 1))
        return 1
    fi
}

print_header() {
    echo ""
    echo "==============================================="
    echo "$1"
    echo "==============================================="
}

# Main checks
main() {
    print_header "Kubernetes Upgrade Pre-flight Check"
    echo "Time: $(date)"
    echo "Host: $(hostname)"
    echo ""
    
    # Section 1: System Requirements
    print_header "1. System Requirements"
    
    check "Operating System" "[ -f /etc/os-release ]"
    check "Kernel Version" "[ $(uname -r | cut -d. -f1) -ge 5 ]"
    check "CPU Cores (>=2)" "[ $(nproc) -ge 2 ]"
    check "Memory (>=2GB)" "[ $(free -g | awk '/^Mem:/{print $2}') -ge $MIN_MEMORY_GB ]"
    check "Disk Space (>=10GB)" "[ $(df / | awk 'NR==2 {print int($4/1048576)}') -ge $MIN_DISK_SPACE_GB ]"
    check "Swap Disabled" "[ $(swapon -s | wc -l) -eq 0 ]"
    
    # Section 2: Required Commands
    print_header "2. Required Commands"
    
    for cmd in $REQUIRED_COMMANDS; do
        check "Command: $cmd" "command -v $cmd"
    done
    
    # Section 3: Network Configuration
    print_header "3. Network Configuration"
    
    check "Network connectivity" "ping -c 1 8.8.8.8"
    check "DNS resolution" "nslookup kubernetes.io"
    check_warn "Firewall disabled" "! systemctl is-active firewalld"
    check "IP forwarding enabled" "[ $(sysctl net.ipv4.ip_forward | awk '{print $3}') -eq 1 ]"
    check "Bridge netfilter" "[ $(sysctl net.bridge.bridge-nf-call-iptables 2>/dev/null | awk '{print $3}') -eq 1 ]"
    
    # Section 4: Kubernetes Cluster
    print_header "4. Kubernetes Cluster Status"
    
    if [ -f "$KUBECONFIG" ]; then
        export KUBECONFIG
        
        check "Kubernetes API accessible" "kubectl cluster-info"
        check "All nodes ready" "[ $(kubectl get nodes --no-headers | grep -v Ready | wc -l) -eq 0 ]"
        check "System pods healthy" "[ $(kubectl get pods -n kube-system --no-headers | grep -v Running | grep -v Completed | wc -l) -eq 0 ]"
        check_warn "No pending pods" "[ $(kubectl get pods --all-namespaces --field-selector=status.phase=Pending --no-headers | wc -l) -eq 0 ]"
        
        # Check current version
        CURRENT_VERSION=$(kubectl version --short 2>/dev/null | grep Server | awk '{print $3}')
        echo "Current Kubernetes version: $CURRENT_VERSION"
    else
        echo -e "${YELLOW}Warning: kubeconfig not found at $KUBECONFIG${NC}"
    fi
    
    # Section 5: etcd Health
    print_header "5. etcd Cluster Health"
    
    if command -v etcdctl &>/dev/null; then
        export ETCDCTL_API=3
        ETCD_CERTS="--cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt --key=/etc/kubernetes/pki/etcd/healthcheck-client.key"
        
        check "etcd endpoint health" "etcdctl --endpoints=https://127.0.0.1:2379 $ETCD_CERTS endpoint health"
        check_warn "etcd alarm check" "[ -z \"$(etcdctl --endpoints=https://127.0.0.1:2379 $ETCD_CERTS alarm list)\" ]"
    else
        echo -e "${YELLOW}etcdctl not found - skipping etcd checks${NC}"
    fi
    
    # Section 6: Container Runtime
    print_header "6. Container Runtime"
    
    check "Containerd service active" "systemctl is-active containerd"
    check "Containerd socket exists" "[ -S /run/containerd/containerd.sock ]"
    check_warn "Containerd has free space" "[ $(df /var/lib/containerd | awk 'NR==2 {print int($5)}') -lt 80 ]"
    
    # Section 7: Backup Readiness
    print_header "7. Backup Readiness"
    
    check "Backup directory exists" "[ -d $BACKUP_DIR ]"
    check "Backup directory writable" "[ -w $BACKUP_DIR ]"
    check_warn "Sufficient backup space" "[ $(df $BACKUP_DIR | awk 'NR==2 {print int($4/1048576)}') -ge 5 ]"
    
    # Section 8: Ansible Configuration
    print_header "8. Ansible Configuration"
    
    check "Ansible inventory exists" "[ -f $SCRIPT_DIR/inventory/hosts.yml ]"
    check "Ansible.cfg exists" "[ -f $SCRIPT_DIR/ansible.cfg ]"
    check "SSH key exists" "[ -f ~/.ssh/ansible_k8s_ed25519 ] || [ -f ~/.ssh/id_rsa ] || [ -f ~/.ssh/id_ed25519 ]"
    check_warn "Ansible connectivity" "cd $SCRIPT_DIR && ansible all -i inventory/hosts.yml -m ping --one-line"
    
    # Section 9: Certificates
    print_header "9. Certificate Validation"
    
    if command -v kubeadm &>/dev/null; then
        # Check certificate expiration
        CERT_CHECK=$(kubeadm certs check-expiration 2>/dev/null | grep -c "EXPIRED\|WARNING" || true)
        check "Certificates not expired" "[ $CERT_CHECK -eq 0 ]"
    fi
    
    # Section 10: Resource Availability
    print_header "10. Resource Availability"
    
    if [ -f "$KUBECONFIG" ]; then
        # Check cluster resources
        if kubectl top nodes &>/dev/null; then
            AVG_CPU=$(kubectl top nodes --no-headers | awk '{sum+=$3; count++} END {print int(sum/count)}')
            AVG_MEM=$(kubectl top nodes --no-headers | awk '{sum+=$5; count++} END {print int(sum/count)}')
            
            check_warn "CPU usage <80%" "[ ${AVG_CPU%\%} -lt 80 ]"
            check_warn "Memory usage <80%" "[ ${AVG_MEM%\%} -lt 80 ]"
        else
            echo -e "${YELLOW}Metrics server not available${NC}"
        fi
    fi
    
    # Final Summary
    print_header "Pre-flight Check Summary"
    
    echo -e "Checks Passed:  ${GREEN}$CHECKS_PASSED${NC}"
    echo -e "Checks Failed:  ${RED}$CHECKS_FAILED${NC}"
    echo -e "Warnings:       ${YELLOW}$CHECKS_WARNING${NC}"
    echo ""
    
    if [ $CHECKS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ Pre-flight check PASSED!${NC}"
        echo "The system is ready for Kubernetes upgrade."
        echo ""
        echo "Next steps:"
        echo "1. Run the complete test suite: ./run-all-tests.sh"
        echo "2. Create backup: ansible-playbook playbooks/01-backup-cluster.yml"
        echo "3. Start upgrade: ./upgrade-cluster.sh"
        exit 0
    else
        echo -e "${RED}✗ Pre-flight check FAILED!${NC}"
        echo "Please address the failed checks before proceeding with the upgrade."
        echo ""
        echo "Failed items need to be resolved before upgrade can proceed safely."
        exit 1
    fi
}

# Run main function
main "$@"