#\!/bin/bash
# Setup kube-vip on control plane nodes

# Create manifests directory
mkdir -p /etc/kubernetes/manifests/

# Get the network interface
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
echo "Using interface: $INTERFACE"

# Download kube-vip container image
ctr image pull ghcr.io/kube-vip/kube-vip:v0.8.3

echo "kube-vip setup complete - manifest will be placed during kubeadm init"
