#!/bin/bash
# Quick Kubernetes Cluster Health Check
# Shows essential cluster status in a clean, compact format

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

clear
echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}${BOLD}     KUBERNETES CLUSTER QUICK STATUS CHECK${NC}"
echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════${NC}"
echo ""

# 1. Nodes
echo -e "${YELLOW}▶ NODES (Expected: 5 Ready)${NC}"
kubectl get nodes
echo ""

# 2. System Pods
echo -e "${YELLOW}▶ SYSTEM PODS STATUS${NC}"
echo "Namespace: kube-system"
kubectl get pods -n kube-system | grep -E "NAME|coredns|etcd|kube-apiserver|kube-controller|kube-scheduler|kube-proxy|metrics"
echo ""

# 3. Calico Status
echo -e "${YELLOW}▶ CALICO CNI STATUS${NC}"
echo "Namespace: calico-system"
kubectl get pods -n calico-system | grep -E "NAME|calico-node|calico-kube-controllers|typha"
echo ""

# 4. Ingress Status
echo -e "${YELLOW}▶ INGRESS CONTROLLER${NC}"
echo "Namespace: ingress-nginx"
kubectl get pods -n ingress-nginx | grep -E "NAME|controller"
kubectl get svc -n ingress-nginx | grep -E "NAME|controller"
echo ""

# 5. Dashboard Status
echo -e "${YELLOW}▶ KUBERNETES DASHBOARD${NC}"
echo "Namespace: kubernetes-dashboard"
kubectl get pods -n kubernetes-dashboard
echo ""

# 6. Test Application
echo -e "${YELLOW}▶ TEST APPLICATION${NC}"
echo "Namespace: test-app"
kubectl get pods -n test-app -o wide
echo ""
kubectl get hpa -n test-app
echo ""

# 7. Resource Usage
echo -e "${YELLOW}▶ CLUSTER RESOURCE USAGE${NC}"
kubectl top nodes
echo ""

# 8. Quick Health Summary
echo -e "${YELLOW}▶ HEALTH SUMMARY${NC}"
node_count=$(kubectl get nodes --no-headers | wc -l)
ready_nodes=$(kubectl get nodes --no-headers | grep " Ready" | wc -l)
system_pods=$(kubectl get pods -n kube-system --no-headers | grep Running | wc -l)
calico_pods=$(kubectl get pods -n calico-system --no-headers | grep Running | wc -l)

echo -e "Cluster Nodes:    ${GREEN}$ready_nodes/$node_count Ready${NC}"
echo -e "System Pods:      ${GREEN}$system_pods Running${NC}"
echo -e "Calico CNI:       ${GREEN}$calico_pods Running${NC}"

if [ $ready_nodes -eq 5 ] && [ $system_pods -gt 10 ] && [ $calico_pods -gt 5 ]; then
    echo -e "\nOverall Status:   ${GREEN}${BOLD}✓ HEALTHY${NC}"
else
    echo -e "\nOverall Status:   ${RED}${BOLD}✗ ISSUES DETECTED${NC}"
fi

echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
