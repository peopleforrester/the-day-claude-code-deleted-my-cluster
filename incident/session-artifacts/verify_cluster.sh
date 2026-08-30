#!/bin/bash
# ABOUTME: Script to verify Kubernetes cluster health and functionality
# ABOUTME: Tests deployments, services, and overall cluster operations

set -e

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_test() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Test 1: Check node status
print_test "Checking node status..."
kubectl get nodes
if kubectl get nodes | grep -E "Ready.*master|Ready.*control-plane" && kubectl get nodes | grep -c "Ready" | grep -q "5"; then
    print_pass "All nodes are ready"
else
    print_fail "Some nodes are not ready"
    exit 1
fi

# Test 2: Check system pods
print_test "Checking system pods..."
kubectl get pods -n kube-system
if ! kubectl get pods -n kube-system | grep -v "Running" | grep -v "NAME" | grep -v "Completed"; then
    print_pass "All system pods are running"
else
    print_fail "Some system pods are not running"
    exit 1
fi

# Test 3: Deploy a test application
print_test "Deploying test nginx application..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-test-svc
spec:
  selector:
    app: nginx-test
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
EOF

# Wait for deployment to be ready
print_test "Waiting for test deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/nginx-test

# Test 4: Check pod distribution
print_test "Checking pod distribution across nodes..."
kubectl get pods -o wide | grep nginx-test
POD_COUNT=$(kubectl get pods | grep nginx-test | grep Running | wc -l)
if [ "$POD_COUNT" -eq 3 ]; then
    print_pass "All test pods are running"
else
    print_fail "Expected 3 pods, found $POD_COUNT"
fi

# Test 5: Test service connectivity
print_test "Testing service connectivity..."
kubectl run test-curl --image=curlimages/curl:latest --rm -it --restart=Never -- curl -s nginx-test-svc
if [ $? -eq 0 ]; then
    print_pass "Service connectivity working"
else
    print_fail "Service connectivity failed"
fi

# Test 6: Check cluster DNS
print_test "Testing cluster DNS..."
kubectl run test-dns --image=busybox:latest --rm -it --restart=Never -- nslookup kubernetes.default
if [ $? -eq 0 ]; then
    print_pass "Cluster DNS working"
else
    print_fail "Cluster DNS failed"
fi

# Cleanup
print_test "Cleaning up test resources..."
kubectl delete deployment nginx-test
kubectl delete service nginx-test-svc

echo ""
print_pass "✨ All cluster verification tests passed!"
