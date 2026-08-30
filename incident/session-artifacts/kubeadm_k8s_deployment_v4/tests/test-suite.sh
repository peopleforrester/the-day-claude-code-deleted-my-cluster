#!/bin/bash
# Comprehensive Kubernetes Cluster Test Suite

echo "=== Kubernetes HA Cluster Validation Suite ==="
echo "Started at: $(date)"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test counters
PASSED=0
FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    echo -n "Testing: $test_name... "
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}FAILED${NC}"
        ((FAILED++))
    fi
}

echo "=== Node Health Tests ==="
run_test "All nodes ready" "kubectl get nodes | grep -v STATUS | grep -c Ready | grep -q 5"
run_test "No nodes NotReady" "! kubectl get nodes | grep NotReady"
run_test "Control plane nodes" "kubectl get nodes | grep control-plane | wc -l | grep -q 3"
run_test "Worker nodes" "kubectl get nodes | grep -v control-plane | grep -v NAME | wc -l | grep -q 2"

echo -e "\n=== Pod Health Tests ==="
run_test "No pods in Error state" "! kubectl get pods -A | grep -E 'Error|CrashLoopBackOff'"
run_test "All system pods Running" "! kubectl get pods -n kube-system | grep -v Running | grep -v NAME"
run_test "CoreDNS pods running" "kubectl get pods -n kube-system | grep coredns | grep -c Running | grep -q 2"

echo -e "\n=== Network Tests ==="
run_test "Calico pods running" "! kubectl get pods -n calico-system | grep -v Running | grep -v Completed | grep -v NAME"
run_test "DNS resolution working" "kubectl run test-dns --image=busybox:1.28 --rm -it --restart=Never -- nslookup kubernetes.default"
run_test "Pod-to-pod communication" "kubectl run test-ping --image=busybox:1.28 --rm -it --restart=Never -- ping -c 1 10.96.0.1"

echo -e "\n=== Storage Tests ==="
run_test "Default storage class exists" "kubectl get storageclass"

echo -e "\n=== API Server Tests ==="
run_test "API server responsive" "kubectl version --short"
run_test "API endpoints healthy" "kubectl get --raw /healthz"

echo -e "\n=== etcd Tests ==="
run_test "etcd cluster healthy" "kubectl exec -n kube-system etcd-master1 -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key member list | grep -c started | grep -q 3"

echo -e "\n=== Metrics Tests ==="
run_test "Metrics server deployed" "kubectl get deployment metrics-server -n kube-system"
run_test "Node metrics available" "kubectl top nodes"
run_test "Pod metrics available" "kubectl top pods -n kube-system"

echo -e "\n=== Ingress Tests ==="
run_test "Ingress controller running" "kubectl get pods -n ingress-nginx | grep -c Running | grep -q 1"
run_test "Ingress class available" "kubectl get ingressclass | grep nginx"

echo -e "\n=== Dashboard Tests ==="
run_test "Dashboard running" "kubectl get pods -n kubernetes-dashboard | grep -c Running | grep -q 2"
run_test "Dashboard service exists" "kubectl get svc -n kubernetes-dashboard | grep kubernetes-dashboard"

echo -e "\n=== Application Tests ==="
run_test "Test app pods running" "kubectl get pods -n test-app | grep -c Running | grep -q 3"
run_test "Test app distributed" "kubectl get pods -n test-app -o wide | awk '{print $7}' | grep -v NODE | sort | uniq | wc -l | grep -q 2"
run_test "Test app service responding" "kubectl exec -n test-app deployment/nginx-test -- curl -s -o /dev/null -w '%{http_code}' http://nginx-test | grep -q 200"

echo -e "\n=== Summary ==="
echo "Total tests: $((PASSED + FAILED))"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo "Completed at: $(date)"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed! Cluster is fully operational.${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed. Please investigate.${NC}"
    exit 1
fi
