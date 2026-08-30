#!/bin/bash
# ABOUTME: Install Kubernetes Dashboard v2 (stable version that actually works)
# ABOUTME: Replaces the broken v3 alpha with a working dashboard

echo "Installing Kubernetes Dashboard v2 (stable)..."

# Remove the broken v3 dashboard
echo "Removing broken dashboard v3..."
ssh root@192.168.0.100 'kubectl delete ns kubernetes-dashboard --ignore-not-found=true'

sleep 5

# Install working dashboard v2
echo "Installing dashboard v2..."
ssh root@192.168.0.100 'kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml'

# Wait for deployment
echo "Waiting for dashboard to be ready..."
sleep 10

# Create admin user
echo "Creating admin user..."
ssh root@192.168.0.100 'cat > /tmp/dashboard-admin.yaml << EOF
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

kubectl apply -f /tmp/dashboard-admin.yaml'

# Get token
echo ""
echo "Getting admin token..."
TOKEN=$(ssh root@192.168.0.100 'kubectl -n kubernetes-dashboard create token admin-user --duration=87600h')

echo ""
echo "================================================"
echo "DASHBOARD INSTALLED SUCCESSFULLY!"
echo "================================================"
echo ""
echo "To access the dashboard, run:"
echo ""
echo "ssh -L 8443:localhost:8443 root@192.168.0.100 'kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8443:443'"
echo ""
echo "Then open: https://localhost:8443"
echo ""
echo "Admin Token:"
echo "$TOKEN"
echo ""
echo "================================================"
