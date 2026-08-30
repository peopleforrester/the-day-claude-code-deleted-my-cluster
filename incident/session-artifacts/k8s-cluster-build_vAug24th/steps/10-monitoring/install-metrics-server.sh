#!/bin/bash
# ABOUTME: Install metrics-server v0.7.2 for Kubernetes monitoring
# ABOUTME: Enables kubectl top commands and HPA functionality

set -e

METRICS_VERSION="v0.7.2"

echo "=== Installing metrics-server ${METRICS_VERSION} ==="

export KUBECONFIG=/etc/kubernetes/admin.conf

# Download metrics-server manifest
echo "1. Downloading metrics-server ${METRICS_VERSION} manifest..."
curl -fsSL https://github.com/kubernetes-sigs/metrics-server/releases/download/${METRICS_VERSION}/components.yaml -o metrics-server.yaml

# Modify for insecure TLS (needed for self-signed certificates)
echo "2. Configuring metrics-server for self-signed certificates..."
sed -i '/- --secure-port=10250/a\        - --kubelet-insecure-tls' metrics-server.yaml

# Apply the manifest
echo "3. Installing metrics-server..."
kubectl apply -f metrics-server.yaml

# Wait for deployment to be ready
echo "4. Waiting for metrics-server to be ready..."
kubectl -n kube-system rollout status deployment metrics-server --timeout=180s

# Verify metrics-server is running
echo "5. Verifying metrics-server pods..."
kubectl get pods -n kube-system | grep metrics-server

# Wait for metrics to be available
echo "6. Waiting for metrics to be available..."
sleep 30

# Test metrics
echo "7. Testing metrics collection..."
kubectl top nodes || echo "Metrics may take a minute to be available"

echo ""
echo "=== metrics-server ${METRICS_VERSION} Installation Complete ==="
echo ""
echo "To verify metrics-server:"
echo "  kubectl top nodes"
echo "  kubectl top pods -A"
