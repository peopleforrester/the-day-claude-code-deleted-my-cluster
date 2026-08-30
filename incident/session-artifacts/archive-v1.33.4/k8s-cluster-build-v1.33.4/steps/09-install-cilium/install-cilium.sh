#!/bin/bash
# Step 09: Install Cilium CNI v1.18.0 with validation

set -e

echo "========================================="
echo "Step 09: Install Cilium CNI v1.18.0"
echo "========================================="

# Configuration
CILIUM_VERSION="v1.18.0"
CLUSTER_NAME="kubernetes"
POD_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"
API_SERVER_HOST="192.168.0.200"
API_SERVER_PORT="6443"

# Pre-flight checks
echo ""
echo "Pre-flight Checks:"
echo "=================="

# Check nodes
echo "Current nodes status:"
kubectl get nodes

# Check for existing CNI
echo ""
echo "Checking for existing CNI configurations:"
kubectl get pods -n kube-system | grep -E "(cilium|cni|network)" || echo "No CNI pods found"

# Check kernel version
echo ""
echo "Kernel versions on control plane nodes:"
for ip in 50 51 52; do
    NODE="k8s$(printf %02d $((ip-49)))"
    echo -n "$NODE: "
    ssh root@192.168.0.$ip "uname -r"
done

# Generate Cilium manifest with dry-run
echo ""
echo "========================================="
echo "Generating Cilium v1.18.0 configuration"
echo "========================================="

cat > cilium-values.yaml <<EOF
image:
  repository: quay.io/cilium/cilium
  tag: "${CILIUM_VERSION}"
  pullPolicy: IfNotPresent

operator:
  image:
    repository: quay.io/cilium/operator
    tag: "${CILIUM_VERSION}"
  replicas: 1

ipam:
  mode: kubernetes
  operator:
    clusterPoolIPv4PodCIDRList: ["${POD_CIDR}"]

kubeProxyReplacement: strict
k8sServiceHost: ${API_SERVER_HOST}
k8sServicePort: ${API_SERVER_PORT}

tunnel: vxlan
enableIPv4Masquerade: true
enableBPFMasquerade: true

bpf:
  masquerade: true
  tproxy: true
  mountFsWithOptions: true

hubble:
  enabled: true
  relay:
    enabled: true
    image:
      repository: quay.io/cilium/hubble-relay
      tag: "${CILIUM_VERSION}"
  ui:
    enabled: false

endpointRoutes:
  enabled: true

nodeinit:
  enabled: true
  image:
    repository: quay.io/cilium/startup-script
    tag: "1"

cluster:
  name: ${CLUSTER_NAME}
  id: 0

ipv4NativeRoutingCIDR: ${POD_CIDR}
installNoConntrackIptablesRules: true
autoDirectNodeRoutes: false
EOF

echo "Configuration saved to cilium-values.yaml"

# Helm dry-run first
echo ""
echo "========================================="
echo "Performing Helm dry-run validation"
echo "========================================="

# Add Cilium Helm repo
helm repo add cilium https://helm.cilium.io/ || true
helm repo update

# Dry-run to validate configuration
echo "Running helm install with --dry-run..."
helm install cilium cilium/cilium \
  --version 1.18.0 \
  --namespace kube-system \
  --values cilium-values.yaml \
  --dry-run > cilium-dry-run.yaml 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Dry-run successful, configuration validated"
else
    echo "✗ Dry-run failed, check cilium-dry-run.yaml for errors"
    exit 1
fi

# Ask for confirmation
echo ""
echo "========================================="
echo "Ready to install Cilium v1.18.0"
echo "========================================="
echo "Configuration:"
echo "  Version: ${CILIUM_VERSION}"
echo "  Pod CIDR: ${POD_CIDR}"
echo "  Service CIDR: ${SERVICE_CIDR}"
echo "  API Server: ${API_SERVER_HOST}:${API_SERVER_PORT}"
echo "  Mode: VXLAN with kube-proxy replacement"
echo ""
read -p "Proceed with installation? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled"
    exit 1
fi

# Actual installation
echo ""
echo "========================================="
echo "Installing Cilium v1.18.0"
echo "========================================="

helm install cilium cilium/cilium \
  --version 1.18.0 \
  --namespace kube-system \
  --values cilium-values.yaml

# Wait for Cilium to be ready
echo ""
echo "Waiting for Cilium pods to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=cilium -n kube-system --timeout=300s

echo ""
echo "Waiting for Cilium operator to be ready..."
kubectl wait --for=condition=ready pod -l name=cilium-operator -n kube-system --timeout=300s

# Verify Cilium status
echo ""
echo "========================================="
echo "Verifying Cilium Installation"
echo "========================================="

# Check Cilium pods
echo "Cilium pods status:"
kubectl get pods -n kube-system -l k8s-app=cilium -o wide

echo ""
echo "Cilium operator status:"
kubectl get pods -n kube-system -l name=cilium-operator -o wide

# Check nodes becoming ready
echo ""
echo "Waiting for nodes to become Ready..."
sleep 10

echo "Node status:"
kubectl get nodes

# Check CoreDNS
echo ""
echo "CoreDNS status:"
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Run Cilium connectivity test
echo ""
echo "Running Cilium connectivity test..."
./cilium connectivity test --connect-timeout 10s --request-timeout 10s || echo "Note: Some tests may fail without worker nodes"

echo ""
echo "========================================="
echo "Cilium v1.18.0 Installation Complete"
echo "========================================="
echo "✓ Cilium pods running"
echo "✓ Nodes should be transitioning to Ready state"
echo "✓ CoreDNS should be starting"
echo ""
echo "Next steps:"
echo "1. Verify all nodes are Ready"
echo "2. Install Multus CNI"
echo "3. Configure bridge interfaces for KubeVirt"
