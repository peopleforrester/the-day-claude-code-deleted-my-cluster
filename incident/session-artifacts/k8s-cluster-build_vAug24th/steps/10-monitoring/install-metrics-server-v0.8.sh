#!/bin/bash
# ABOUTME: Install metrics-server v0.8.0 for Kubernetes monitoring
# ABOUTME: Enables kubectl top commands and HPA functionality

set -e

METRICS_VERSION="v0.8.0"

echo "=== Installing metrics-server ${METRICS_VERSION} ==="

export KUBECONFIG=/etc/kubernetes/admin.conf

# Download metrics-server manifest
echo "1. Downloading metrics-server ${METRICS_VERSION} manifest..."
curl -fsSL https://github.com/kubernetes-sigs/metrics-server/releases/download/${METRICS_VERSION}/components.yaml -o metrics-server-v0.8.yaml

# Check if download successful, if not try v0.7.2
if [ ! -s metrics-server-v0.8.yaml ]; then
    echo "v0.8.0 not found, trying v0.7.2..."
    METRICS_VERSION="v0.7.2"
    curl -fsSL https://github.com/kubernetes-sigs/metrics-server/releases/download/${METRICS_VERSION}/components.yaml -o metrics-server-v0.8.yaml
fi

# Modify for insecure TLS (needed for self-signed certificates)
echo "2. Configuring metrics-server for self-signed certificates..."
sed -i '/- --secure-port=10250/a\        - --kubelet-insecure-tls' metrics-server-v0.8.yaml

# Apply the manifest
echo "3. Installing metrics-server..."
kubectl apply -f metrics-server-v0.8.yaml

# Wait for deployment to be ready
echo "4. Waiting for metrics-server to be ready..."
kubectl -n kube-system rollout status deployment metrics-server --timeout=180s

# Verify metrics-server is running
echo "5. Verifying metrics-server pods..."
kubectl get pods -n kube-system | grep metrics-server

# Check the version
echo "6. Checking metrics-server version..."
kubectl get deployment metrics-server -n kube-system -o jsonpath='{.spec.template.spec.containers[0].image}'

# Wait for metrics to be available
echo "7. Waiting for metrics to be available..."
sleep 30

# Test metrics
echo "8. Testing metrics collection..."
kubectl top nodes || echo "Metrics may take a minute to be available"

echo ""
echo "=== metrics-server ${METRICS_VERSION} Installation Complete ==="
echo ""
echo "To verify metrics-server:"
echo "  kubectl top nodes"
echo "  kubectl top pods -A"
