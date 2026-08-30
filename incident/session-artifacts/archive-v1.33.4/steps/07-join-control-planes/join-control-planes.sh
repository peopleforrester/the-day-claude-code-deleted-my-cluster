#!/bin/bash
# Step 07: Join Control Plane Nodes (k8s02 and k8s03)

set -e

echo "========================================="
echo "Step 07: Join Control Plane Nodes"
echo "========================================="

# Configuration
KUBE_VIP_MANIFEST="../06-initialize-first-master/kube-vip-manifest-fixed.yaml"
CONTROL_PLANE_JOIN="../06-initialize-first-master/control-plane-join.sh"

# Control plane nodes to join
CONTROL_NODES=("k8s02" "k8s03")
CONTROL_IPS=("192.168.0.51" "192.168.0.52")
INTERFACES=("enp2s0" "enp1s0")  # Network interfaces for each node

echo "Prerequisites check..."
if [ ! -f "$KUBE_VIP_MANIFEST" ]; then
    echo "ERROR: kube-vip manifest not found at $KUBE_VIP_MANIFEST"
    exit 1
fi

if [ ! -f "$CONTROL_PLANE_JOIN" ]; then
    echo "ERROR: Control plane join script not found at $CONTROL_PLANE_JOIN"
    exit 1
fi

# Function to prepare kube-vip manifest for each node
prepare_kube_vip_for_node() {
    local node=$1
    local interface=$2
    local temp_manifest="/tmp/kube-vip-${node}.yaml"

    echo "Preparing kube-vip manifest for $node with interface $interface..."
    cp "$KUBE_VIP_MANIFEST" "$temp_manifest"

    # Update interface name if different
    sed -i "s/value: enp2s0/value: ${interface}/" "$temp_manifest"

    echo "Manifest prepared at $temp_manifest"
    return 0
}

# Join each control plane node
for i in ${!CONTROL_NODES[@]}; do
    NODE="${CONTROL_NODES[$i]}"
    NODE_IP="${CONTROL_IPS[$i]}"
    INTERFACE="${INTERFACES[$i]}"

    echo ""
    echo "========================================="
    echo "Joining control plane node: $NODE ($NODE_IP)"
    echo "========================================="

    # Test SSH connectivity
    echo "Testing SSH connectivity to $NODE..."
    if ! ssh root@$NODE_IP "hostname" >/dev/null 2>&1; then
        echo "ERROR: Cannot connect to $NODE via SSH"
        echo "Please ensure SSH key authentication is set up"
        exit 1
    fi

    # Prepare kube-vip manifest
    prepare_kube_vip_for_node "$NODE" "$INTERFACE"

    # Copy kube-vip manifest to node
    echo "Copying kube-vip manifest to $NODE..."
    ssh root@$NODE_IP "mkdir -p /etc/kubernetes/manifests"
    scp "/tmp/kube-vip-${NODE}.yaml" root@$NODE_IP:/etc/kubernetes/manifests/kube-vip.yaml

    # Copy and execute join command
    echo "Copying join script to $NODE..."
    scp "$CONTROL_PLANE_JOIN" root@$NODE_IP:/tmp/join-control-plane.sh
    ssh root@$NODE_IP "chmod +x /tmp/join-control-plane.sh"

    echo "Executing join command on $NODE..."
    ssh root@$NODE_IP "/tmp/join-control-plane.sh"

    # Wait for node to be ready
    echo "Waiting for $NODE to be ready..."
    sleep 30

    # Verify node joined
    echo "Verifying $NODE joined the cluster..."
    kubectl get nodes | grep $NODE

    # Check control plane components
    echo "Checking control plane pods on $NODE..."
    kubectl get pods -n kube-system -o wide | grep $NODE

    echo "✓ $NODE successfully joined as control plane"
done

echo ""
echo "========================================="
echo "Verifying HA Control Plane Setup"
echo "========================================="

# Check all control plane nodes
echo "Control plane nodes status:"
kubectl get nodes -l node-role.kubernetes.io/control-plane

# Check kube-vip on all masters
echo ""
echo "kube-vip status on all control plane nodes:"
kubectl get pods -n kube-system -l name=kube-vip -o wide

# Check leader election
echo ""
echo "Current kube-vip leader:"
kubectl get lease -n kube-system plndr-cp-lock -o jsonpath='{.spec.holderIdentity}'
echo ""

# Test API server via VIP
echo ""
echo "Testing API server access via VIP (192.168.0.200):"
kubectl --server=https://192.168.0.200:6443 get nodes

echo ""
echo "========================================="
echo "Step 07 Complete: Control Plane HA Ready"
echo "========================================="
echo "✓ All control plane nodes joined"
echo "✓ kube-vip running on all masters"
echo "✓ Leader election working"
echo "✓ API server accessible via VIP"
