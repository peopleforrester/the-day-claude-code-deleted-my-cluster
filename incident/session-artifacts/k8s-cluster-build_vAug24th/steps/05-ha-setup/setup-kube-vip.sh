#!/bin/bash
# ABOUTME: Setup kube-vip v1.0.0 for HA control plane
# ABOUTME: Configures VIP 192.168.0.199 for Kubernetes API server

set -e

KVVERSION="v1.0.0"
VIP="192.168.0.199"
INTERFACE="eth0"  # Will be detected automatically

echo "=== Setting up kube-vip ${KVVERSION} for HA ==="

# Discovery phase - detect network interface
echo "1. Detecting primary network interface..."
# Get the interface that has the 192.168.0.x IP
INTERFACE=$(ip -4 addr show | grep "192.168.0" | awk '{print $NF}' | head -1)
if [ -z "$INTERFACE" ]; then
    echo "ERROR: Could not detect network interface with 192.168.0.x IP"
    exit 1
fi
echo "   Detected interface: $INTERFACE"

# Check if running on a control plane node
HOSTNAME=$(hostname)
if [[ ! "$HOSTNAME" =~ ^master[0-9]+$ ]]; then
    echo "WARNING: This script should only run on control plane nodes (master1, master2, master3)"
    echo "Current hostname: $HOSTNAME"
fi

# Create manifests directory if it doesn't exist
echo "2. Creating Kubernetes manifests directory..."
mkdir -p /etc/kubernetes/manifests

# Pull kube-vip image using containerd
echo "3. Pulling kube-vip image ${KVVERSION}..."
ctr image pull ghcr.io/kube-vip/kube-vip:${KVVERSION}

# Generate static pod manifest
echo "4. Generating kube-vip static pod manifest..."
ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:${KVVERSION} vip \
    /kube-vip manifest pod \
    --interface ${INTERFACE} \
    --address ${VIP} \
    --controlplane \
    --services \
    --arp \
    --leaderElection | tee /etc/kubernetes/manifests/kube-vip.yaml

# Verify the manifest was created
if [ ! -f /etc/kubernetes/manifests/kube-vip.yaml ]; then
    echo "ERROR: Failed to create kube-vip manifest"
    exit 1
fi

echo "5. kube-vip manifest created successfully"
echo "   VIP: ${VIP}"
echo "   Interface: ${INTERFACE}"
echo "   Mode: ARP with leader election"
echo "   Location: /etc/kubernetes/manifests/kube-vip.yaml"

# Create a copy for reference
cp /etc/kubernetes/manifests/kube-vip.yaml /etc/kubernetes/kube-vip-backup.yaml

echo ""
echo "=== kube-vip ${KVVERSION} Setup Complete ==="
echo "The static pod will be automatically started by kubelet after kubeadm init"
echo "VIP ${VIP} will become active once the first control plane is initialized"
