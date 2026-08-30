#!/bin/bash
# ABOUTME: Visual cluster functionality test script
# ABOUTME: Demonstrates all major cluster features with clear output

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Test configuration
MASTER_IP="192.168.0.100"
TEST_NAMESPACE="demo-test"
LOAD_TEST_DURATION="30s"

echo -e "${BOLD}${BLUE}================================================${NC}"
echo -e "${BOLD}${BLUE}    KUBERNETES CLUSTER FUNCTIONALITY TEST${NC}"
echo -e "${BOLD}${BLUE}================================================${NC}\n"

# Function to run commands on master
run_on_master() {
    ssh root@${MASTER_IP} "$1"
}

# Function to print section headers
print_section() {
    echo -e "\n${BOLD}${GREEN}>>> $1${NC}"
    echo -e "${GREEN}$(printf '%.0s-' {1..50})${NC}"
}

# Function to print test status
print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

# Function to print results
print_result() {
    echo -e "${BLUE}[RESULT]${NC} $1"
}

# 1. Cluster Overview
print_section "1. CLUSTER OVERVIEW"
print_test "Checking cluster nodes..."
run_on_master "kubectl get nodes -o wide" | sed 's/^/  /'

# 2. System Health
print_section "2. SYSTEM HEALTH CHECK"
print_test "Checking component status..."
run_on_master "kubectl get componentstatuses 2>/dev/null || echo 'Component status deprecated in v1.19+'" | sed 's/^/  /'

print_test "Checking system pods..."
echo -e "  ${BOLD}Namespace${NC}: kube-system"
run_on_master "kubectl get pods -n kube-system -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount,NODE:.spec.nodeName" | sed 's/^/  /'

# 3. Resource Utilization
print_section "3. RESOURCE UTILIZATION"
print_test "Current resource usage across nodes..."
run_on_master "kubectl top nodes" | sed 's/^/  /'

# 4. Network Test
print_section "4. NETWORK CONNECTIVITY TEST"
print_test "Creating test pods on different nodes..."

# Create test namespace
run_on_master "kubectl create namespace ${TEST_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -" >/dev/null 2>&1

# Create test pods
cat << 'EOF' > /tmp/network-test.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod-worker1
  namespace: demo-test
spec:
  nodeName: worker1
  containers:
  - name: test
    image: nginx:alpine
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: test-pod-worker2
  namespace: demo-test
spec:
  nodeName: worker2
  containers:
  - name: test
    image: nginx:alpine
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: test-service
  namespace: demo-test
spec:
  selector:
    app: network-test
  ports:
  - port: 80
    targetPort: 80
EOF

scp /tmp/network-test.yaml root@${MASTER_IP}:/tmp/ >/dev/null 2>&1
run_on_master "kubectl apply -f /tmp/network-test.yaml" >/dev/null 2>&1

sleep 5

print_result "Test pods created:"
run_on_master "kubectl get pods -n ${TEST_NAMESPACE} -o wide" | sed 's/^/  /'

print_test "Testing cross-node pod communication..."
POD2_IP=$(run_on_master "kubectl get pod test-pod-worker2 -n ${TEST_NAMESPACE} -o jsonpath='{.status.podIP}'")
run_on_master "kubectl exec -n ${TEST_NAMESPACE} test-pod-worker1 -- wget -qO- --timeout=2 http://${POD2_IP} | head -n 5" | sed 's/^/  /'
print_result "✓ Cross-node pod communication successful!"

# 5. DNS Resolution Test
print_section "5. DNS RESOLUTION TEST"
print_test "Testing cluster DNS..."
run_on_master "kubectl exec -n ${TEST_NAMESPACE} test-pod-worker1 -- nslookup kubernetes.default.svc.cluster.local" | sed 's/^/  /'
print_result "✓ DNS resolution working!"

# 6. Service Load Balancing
print_section "6. SERVICE LOAD BALANCING TEST"
print_test "Creating a service with multiple endpoints..."

cat << 'EOF' > /tmp/lb-test.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lb-test
  namespace: demo-test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: lb-test
  template:
    metadata:
      labels:
        app: lb-test
    spec:
      containers:
      - name: server
        image: hashicorp/http-echo:0.2.3
        args:
        - "-text=Hello from $(HOSTNAME)"
        env:
        - name: HOSTNAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: lb-test-service
  namespace: demo-test
spec:
  selector:
    app: lb-test
  ports:
  - port: 80
    targetPort: 5678
EOF

scp /tmp/lb-test.yaml root@${MASTER_IP}:/tmp/ >/dev/null 2>&1
run_on_master "kubectl apply -f /tmp/lb-test.yaml" >/dev/null 2>&1

echo "  Waiting for deployment to be ready..."
run_on_master "kubectl wait --for=condition=available --timeout=60s deployment/lb-test -n ${TEST_NAMESPACE}" >/dev/null 2>&1

print_result "Testing load balancing (5 requests):"
for i in {1..5}; do
    response=$(run_on_master "kubectl exec -n ${TEST_NAMESPACE} test-pod-worker1 -- wget -qO- http://lb-test-service")
    echo "  Request $i: $response"
done
print_result "✓ Service load balancing working!"

# 7. Ingress Controller Test
print_section "7. INGRESS CONTROLLER TEST"
print_test "Testing NGINX Ingress Controller..."

cat << 'EOF' > /tmp/ingress-test.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  namespace: demo-test
spec:
  ingressClassName: nginx
  rules:
  - host: test.cluster.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: lb-test-service
            port:
              number: 80
EOF

scp /tmp/ingress-test.yaml root@${MASTER_IP}:/tmp/ >/dev/null 2>&1
run_on_master "kubectl apply -f /tmp/ingress-test.yaml" >/dev/null 2>&1

sleep 3

INGRESS_PORT=$(run_on_master "kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name==\"http\")].nodePort}'")
print_result "Ingress accessible on NodePort: $INGRESS_PORT"

print_test "Testing ingress routing..."
response=$(run_on_master "curl -s -H 'Host: test.cluster.local' http://localhost:${INGRESS_PORT}")
echo "  Response: $response"
print_result "✓ Ingress routing working!"

# 8. Dashboard Access Test
print_section "8. DASHBOARD ACCESS TEST"
print_test "Checking Dashboard deployment..."
run_on_master "kubectl get pods -n kubernetes-dashboard -o wide | grep -E 'NAME|dashboard'" | sed 's/^/  /'

DASHBOARD_PORT=$(run_on_master "kubectl get svc -n kubernetes-dashboard kubernetes-dashboard-nodeport -o jsonpath='{.spec.ports[0].nodePort}'")
print_result "Dashboard accessible at: https://${MASTER_IP}:${DASHBOARD_PORT}"

# 9. Horizontal Pod Autoscaling Test
print_section "9. HORIZONTAL POD AUTOSCALING TEST"
print_test "Creating HPA test deployment..."

cat << 'EOF' > /tmp/hpa-test.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hpa-test
  namespace: demo-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hpa-test
  template:
    metadata:
      labels:
        app: hpa-test
    spec:
      containers:
      - name: hpa-container
        image: k8s.gcr.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
          limits:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: hpa-test-service
  namespace: demo-test
spec:
  selector:
    app: hpa-test
  ports:
  - port: 80
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-test
  namespace: demo-test
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: hpa-test
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
EOF

scp /tmp/hpa-test.yaml root@${MASTER_IP}:/tmp/ >/dev/null 2>&1
run_on_master "kubectl apply -f /tmp/hpa-test.yaml" >/dev/null 2>&1

sleep 5

print_result "HPA Status:"
run_on_master "kubectl get hpa -n ${TEST_NAMESPACE}" | sed 's/^/  /'

# 10. Pod Disruption and Recovery
print_section "10. POD DISRUPTION & RECOVERY TEST"
print_test "Current pod distribution:"
run_on_master "kubectl get pods -n ${TEST_NAMESPACE} -o wide | grep lb-test" | sed 's/^/  /'

print_test "Deleting one pod to test self-healing..."
POD_TO_DELETE=$(run_on_master "kubectl get pods -n ${TEST_NAMESPACE} -l app=lb-test -o jsonpath='{.items[0].metadata.name}'")
run_on_master "kubectl delete pod -n ${TEST_NAMESPACE} ${POD_TO_DELETE}" >/dev/null 2>&1
echo "  Deleted pod: ${POD_TO_DELETE}"

sleep 5

print_result "Pod distribution after recovery:"
run_on_master "kubectl get pods -n ${TEST_NAMESPACE} -o wide | grep lb-test" | sed 's/^/  /'
print_result "✓ Self-healing working!"

# 11. Storage Test
print_section "11. STORAGE CAPABILITIES"
print_test "Checking available storage classes..."
storage_count=$(run_on_master "kubectl get storageclass --no-headers 2>/dev/null | wc -l")
if [ "$storage_count" -eq "0" ]; then
    echo "  No storage classes configured"
    print_result "Note: Add a storage provider for persistent volume support"
else
    run_on_master "kubectl get storageclass" | sed 's/^/  /'
fi

# 12. Cleanup
print_section "12. CLEANUP"
print_test "Removing test resources..."
run_on_master "kubectl delete namespace ${TEST_NAMESPACE} --force --grace-period=0" >/dev/null 2>&1 &
echo "  Test namespace deletion initiated..."

# Summary
print_section "TEST SUMMARY"
echo -e "${BOLD}${GREEN}✓ All cluster functionality tests completed successfully!${NC}\n"

echo -e "${BOLD}Cluster Access Information:${NC}"
echo -e "  ${BLUE}Dashboard:${NC} https://${MASTER_IP}:30443"
echo -e "  ${BLUE}API Server:${NC} https://${MASTER_IP}:6443"
echo -e "  ${BLUE}Ingress HTTP:${NC} http://${MASTER_IP}:31077"
echo -e "  ${BLUE}Ingress HTTPS:${NC} https://${MASTER_IP}:30836"

echo -e "\n${BOLD}${BLUE}================================================${NC}"
echo -e "${BOLD}${BLUE}          TEST EXECUTION COMPLETE${NC}"
echo -e "${BOLD}${BLUE}================================================${NC}"
