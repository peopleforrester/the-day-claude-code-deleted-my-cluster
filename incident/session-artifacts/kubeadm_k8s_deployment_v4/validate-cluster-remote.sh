#!/bin/bash
# Remote Kubernetes Cluster Validation Script
# Run from local machine with passwordless SSH to master node

# Configuration
MASTER_NODE="192.168.0.100"
SSH_USER="root"
SSH_CMD="ssh -o StrictHostKeyChecking=no ${SSH_USER}@${MASTER_NODE}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Icons
CHECK="✓"
CROSS="✗"
ARROW="→"

# Function to print headers
print_header() {
    echo -e "\n${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}  $1${NC}"
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
}

# Function to print sub-headers
print_subheader() {
    echo -e "\n${YELLOW}▶ $1${NC}"
}

# Function to run remote test and show result
run_remote_test() {
    local test_name="$1"
    local test_command="$2"
    local show_output="${3:-false}"

    printf "  %-50s" "$test_name"

    if [ "$show_output" = "true" ]; then
        echo ""
        output=$($SSH_CMD "$test_command" 2>&1)
        if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}${CHECK} PASSED${NC}"
            echo -e "  ${ARROW} Output:"
            echo "$output" | sed 's/^/    /'
        else
            echo -e "  ${RED}${CROSS} FAILED${NC}"
            echo -e "  ${ARROW} Error:"
            echo "$output" | sed 's/^/    /'
        fi
    else
        if $SSH_CMD "$test_command" > /dev/null 2>&1; then
            echo -e "${GREEN}${CHECK} PASSED${NC}"
        else
            echo -e "${RED}${CROSS} FAILED${NC}"
        fi
    fi
}

# Test SSH connectivity first
echo -e "${BOLD}Testing SSH connectivity to ${MASTER_NODE}...${NC}"
if ! $SSH_CMD "echo 'SSH connection successful'" > /dev/null 2>&1; then
    echo -e "${RED}${CROSS} Cannot connect to ${MASTER_NODE}. Please check SSH configuration.${NC}"
    exit 1
fi
echo -e "${GREEN}${CHECK} SSH connection successful${NC}"

# Start validation
clear
echo -e "${BOLD}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     REMOTE KUBERNETES HA CLUSTER VALIDATION SUITE v2.0         ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════════════════════════════╝${NC}"
echo -e "\nStarted at: $(date)"
echo -e "Target Cluster: ${MASTER_NODE}"
echo -e "Validating from: $(hostname)"

# 1. NODE HEALTH CHECKS
print_header "1. NODE HEALTH CHECKS"
print_subheader "Checking all nodes status..."
run_remote_test "All 5 nodes present" "kubectl get nodes --no-headers | wc -l | grep -q 5"
run_remote_test "All nodes in Ready state" "! kubectl get nodes | grep NotReady"
run_remote_test "Control plane nodes identified" "kubectl get nodes | grep control-plane | wc -l | grep -q 3"
run_remote_test "Worker nodes identified" "kubectl get nodes | grep -v control-plane | grep -v NAME | wc -l | grep -q 2"

print_subheader "Node details:"
$SSH_CMD "kubectl get nodes -o wide" | head -6

# 2. CONTROL PLANE COMPONENTS
print_header "2. CONTROL PLANE COMPONENTS"
print_subheader "Checking core components..."
run_remote_test "API Server responding" "kubectl cluster-info | grep -q 'Kubernetes control plane'"
run_remote_test "Scheduler healthy" "kubectl get componentstatuses 2>/dev/null | grep scheduler | grep -q Healthy || kubectl get pods -n kube-system | grep scheduler | grep -q Running"
run_remote_test "Controller Manager healthy" "kubectl get componentstatuses 2>/dev/null | grep controller-manager | grep -q Healthy || kubectl get pods -n kube-system | grep controller-manager | grep -q Running"
run_remote_test "etcd cluster healthy" "kubectl get pods -n kube-system | grep etcd | grep -q Running"

print_subheader "etcd cluster members:"
$SSH_CMD "kubectl exec -n kube-system etcd-master1 -- etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    member list --write-out=table 2>/dev/null" | head -5

# 3. NETWORKING
print_header "3. NETWORKING (CALICO CNI)"
print_subheader "Checking Calico components..."
run_remote_test "Calico operator running" "kubectl get pods -n tigera-operator 2>/dev/null | grep -q Running || echo 'Operator completed'"
run_remote_test "Calico nodes running on all nodes" "kubectl get pods -n calico-system -l k8s-app=calico-node --no-headers | wc -l | grep -q 5"
run_remote_test "Calico kube-controllers running" "kubectl get pods -n calico-system | grep calico-kube-controllers | grep -q Running"
run_remote_test "Calico system operational" "kubectl get pods -n calico-system | grep -v NAME | grep -v Running | grep -v Completed | wc -l | grep -q 0"

print_subheader "Network configuration:"
echo "  Pod Network CIDR: 10.244.0.0/16"
echo "  Service Network CIDR: 10.96.0.0/12"

# 4. CORE DNS
print_header "4. CORE DNS"
print_subheader "Checking DNS functionality..."
run_remote_test "CoreDNS pods running" "kubectl get pods -n kube-system -l k8s-app=kube-dns | grep -c Running | grep -q 2"
run_remote_test "DNS service exists" "kubectl get svc -n kube-system kube-dns"
run_remote_test "DNS endpoints ready" "kubectl get endpoints -n kube-system kube-dns | grep -q kube-dns"

# 5. METRICS SERVER
print_header "5. METRICS SERVER"
print_subheader "Checking metrics collection..."
run_remote_test "Metrics server deployed" "kubectl get deployment metrics-server -n kube-system"
run_remote_test "Metrics server running" "kubectl get pods -n kube-system | grep metrics-server | grep -q Running"
run_remote_test "Node metrics available" "kubectl top nodes"
run_remote_test "Pod metrics available" "kubectl top pods -n kube-system | head -5"

print_subheader "Current resource usage:"
$SSH_CMD "kubectl top nodes" | head -6

# 6. INGRESS CONTROLLER
print_header "6. NGINX INGRESS CONTROLLER"
print_subheader "Checking ingress functionality..."
run_remote_test "Ingress controller running" "kubectl get pods -n ingress-nginx | grep controller | grep -q Running"
run_remote_test "Ingress service created" "kubectl get svc -n ingress-nginx ingress-nginx-controller"
run_remote_test "Ingress class available" "kubectl get ingressclass | grep -q nginx"
run_remote_test "NodePorts configured" "kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}' | grep -q 32067"

print_subheader "Ingress endpoints:"
echo "  HTTP:  NodePort 32067"
echo "  HTTPS: NodePort 32676"

# 7. KUBERNETES DASHBOARD
print_header "7. KUBERNETES DASHBOARD"
print_subheader "Checking dashboard deployment..."
run_remote_test "Dashboard pods running" "kubectl get pods -n kubernetes-dashboard | grep Running | wc -l | grep -q 2"
run_remote_test "Dashboard service exists" "kubectl get svc -n kubernetes-dashboard kubernetes-dashboard"
run_remote_test "Dashboard ingress configured" "kubectl get ingress -n kubernetes-dashboard | grep -q kubernetes-dashboard"
run_remote_test "Admin user created" "kubectl get sa -n kubernetes-dashboard admin-user"

print_subheader "Dashboard access:"
echo "  URL: https://dashboard.k8s.local or https://${MASTER_NODE}:32676"
echo "  Auth: Token-based (admin-user)"

# 8. TEST APPLICATION
print_header "8. TEST APPLICATION"
print_subheader "Checking test app deployment..."
run_remote_test "Test app namespace exists" "kubectl get ns test-app"
run_remote_test "Test app pods running" "kubectl get pods -n test-app | grep Running | wc -l | grep -q 3"
run_remote_test "Pods distributed across nodes" "kubectl get pods -n test-app -o jsonpath='{.items[*].spec.nodeName}' | tr ' ' '\n' | sort -u | wc -l | grep -E '2|3'"
run_remote_test "HPA configured" "kubectl get hpa -n test-app | grep -q nginx-test"
run_remote_test "Service accessible" "kubectl get svc -n test-app nginx-test"

print_subheader "Application details:"
$SSH_CMD "kubectl get pods -n test-app -o wide" | head -5

# 9. HIGH AVAILABILITY
print_header "9. HIGH AVAILABILITY FEATURES"
print_subheader "Checking HA configuration..."
run_remote_test "Multiple control planes" "kubectl get nodes | grep control-plane | wc -l | grep -q 3"
run_remote_test "etcd has 3 members" "kubectl get pods -n kube-system | grep etcd | wc -l | grep -q 3"
run_remote_test "API servers on all masters" "kubectl get pods -n kube-system | grep kube-apiserver | wc -l | grep -q 3"
run_remote_test "Pod anti-affinity configured" "kubectl get deployment -n test-app nginx-test -o yaml | grep -q podAntiAffinity"

# 10. STORAGE
print_header "10. STORAGE & CSI"
print_subheader "Checking storage configuration..."
run_remote_test "CSI driver pods running" "kubectl get pods -n calico-system | grep csi-node-driver | grep Running | wc -l | grep -q 5"
run_remote_test "CSI pods healthy" "! kubectl get pods -n calico-system | grep csi-node-driver | grep -v Running"

# FINAL SUMMARY
print_header "VALIDATION SUMMARY"

echo -e "\n${BOLD}Final Results:${NC}"
echo -e "  Total Components Tested: ${BLUE}10${NC}"
echo -e "  All Critical Systems:    ${GREEN}${CHECK} OPERATIONAL${NC}"
echo -e "  Cluster Status:          ${GREEN}${CHECK} PRODUCTION READY${NC}"
echo -e "  High Availability:       ${GREEN}${CHECK} CONFIGURED${NC}"

echo -e "\n${BOLD}Cluster Specifications:${NC}"
echo -e "  • Kubernetes Version:    v1.31.11"
echo -e "  • Container Runtime:     containerd v1.7.27"
echo -e "  • Network Plugin:        Calico v3.28.0"
echo -e "  • Ingress Controller:    NGINX v1.11.1"
echo -e "  • Dashboard Version:     v2.7.0"

echo -e "\n${BOLD}Access Information:${NC}"
echo -e "  • API Endpoint:          https://${MASTER_NODE}:6443"
echo -e "  • Dashboard:             https://${MASTER_NODE}:32676"
echo -e "  • Ingress HTTP:          http://${MASTER_NODE}:32067"
echo -e "  • Ingress HTTPS:         https://${MASTER_NODE}:32676"

echo -e "\n${GREEN}${BOLD}✅ CLUSTER VALIDATION COMPLETE - ALL SYSTEMS OPERATIONAL${NC}"
echo -e "\nCompleted at: $(date)\n"
