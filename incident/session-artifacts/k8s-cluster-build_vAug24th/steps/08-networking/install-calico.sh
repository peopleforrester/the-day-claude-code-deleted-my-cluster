#!/bin/bash
# ABOUTME: Install Calico v3.30.3 CNI for Kubernetes
# ABOUTME: Configures Calico with pod network 10.244.0.0/16

set -e

CALICO_VERSION="v3.30.3"

echo "=== Installing Calico CNI ${CALICO_VERSION} ==="

# Set kubeconfig
export KUBECONFIG=/etc/kubernetes/admin.conf

# Check cluster status
echo "1. Checking cluster status..."
kubectl get nodes
kubectl get pods -n kube-system

# Download Calico operator
echo "2. Downloading Calico operator CRDs..."
curl -fsSL https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml -o tigera-operator.yaml

# Download custom resources
echo "3. Downloading Calico custom resources..."
curl -fsSL https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml -o custom-resources.yaml

# Modify the custom resources to use our pod CIDR
echo "4. Configuring pod network CIDR..."
sed -i 's|cidr: 192.168.0.0/16|cidr: 10.244.0.0/16|g' custom-resources.yaml

# Apply the operator
echo "5. Installing Calico operator..."
kubectl create -f tigera-operator.yaml

# Wait for operator to be ready
echo "6. Waiting for operator to be ready..."
sleep 10
kubectl wait --for=condition=Ready pods -l name=tigera-operator -n tigera-operator --timeout=90s || true

# Apply custom resources
echo "7. Creating Calico custom resources..."
kubectl create -f custom-resources.yaml

# Wait for Calico to be ready
echo "8. Waiting for Calico pods to be ready..."
sleep 30

# Check Calico pods status
echo "9. Checking Calico installation..."
kubectl get pods -n calico-system
kubectl get pods -n calico-apiserver 2>/dev/null || true

# Verify node is ready
echo "10. Verifying node status..."
sleep 20
kubectl get nodes

echo ""
echo "=== Calico ${CALICO_VERSION} Installation Complete ==="
echo "Pod network CIDR: 10.244.0.0/16"
echo ""
echo "To verify Calico is working:"
echo "  kubectl get pods -n calico-system"
echo "  kubectl get nodes"
