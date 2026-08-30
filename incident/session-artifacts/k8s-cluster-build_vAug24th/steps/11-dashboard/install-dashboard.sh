#!/bin/bash
# ABOUTME: Install Kubernetes Dashboard v7.13.0 using Helm
# ABOUTME: Includes Kong gateway as required by v7.x

set -e

DASHBOARD_VERSION="7.13.0"

echo "=== Installing Kubernetes Dashboard v${DASHBOARD_VERSION} ==="

export KUBECONFIG=/etc/kubernetes/admin.conf

# Install Helm if not already installed
echo "1. Checking Helm installation..."
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Add the dashboard repository
echo "2. Adding Kubernetes Dashboard Helm repository..."
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update

# Create namespace
echo "3. Creating kubernetes-dashboard namespace..."
kubectl create namespace kubernetes-dashboard --dry-run=client -o yaml | kubectl apply -f -

# Install the dashboard with NodePort access
echo "4. Installing Kubernetes Dashboard v${DASHBOARD_VERSION}..."
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
    --namespace kubernetes-dashboard \
    --version ${DASHBOARD_VERSION} \
    --set kong.proxy.type=NodePort \
    --set kong.proxy.http.nodePort=30080 \
    --set kong.proxy.tls.nodePort=30443 \
    --wait --timeout=5m

# Wait for all pods to be ready
echo "5. Waiting for Dashboard pods to be ready..."
kubectl -n kubernetes-dashboard wait --for=condition=ready pod --all --timeout=180s || true

# Check the status
echo "6. Verifying Dashboard installation..."
kubectl get pods -n kubernetes-dashboard
kubectl get svc -n kubernetes-dashboard

# Create admin service account and get token
echo "7. Creating admin service account..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Create token
echo "8. Creating access token..."
kubectl -n kubernetes-dashboard create token admin-user > dashboard-token.txt

echo ""
echo "=== Kubernetes Dashboard v${DASHBOARD_VERSION} Installation Complete ==="
echo ""
echo "Dashboard access:"
echo "  URL: https://192.168.0.100:30443"
echo "  Token saved in: dashboard-token.txt"
echo ""
echo "To access the dashboard:"
echo "  1. Navigate to https://192.168.0.100:30443"
echo "  2. Use the token from dashboard-token.txt"
