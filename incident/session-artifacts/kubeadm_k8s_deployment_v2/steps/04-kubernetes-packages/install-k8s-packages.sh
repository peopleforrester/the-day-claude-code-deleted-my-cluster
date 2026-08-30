#!/bin/bash
# Install Kubernetes packages on all nodes

NODES=("192.168.0.183" "192.168.0.194" "192.168.0.196" "192.168.0.197" "192.168.0.198")
K8S_VERSION="1.31"

echo "=== Installing Kubernetes Packages ==="
echo "Start time: $(date)"
echo "Kubernetes version: $K8S_VERSION"
echo ""

for node in "${NODES[@]}"; do
  echo "Installing Kubernetes packages on node $node..."

  # Add Kubernetes apt repository
  echo "  - Adding Kubernetes apt repository..."
  ssh root@$node "mkdir -p /etc/apt/keyrings" 2>&1
  ssh root@$node "curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg" 2>&1
  ssh root@$node "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /' > /etc/apt/sources.list.d/kubernetes.list" 2>&1

  # Update apt cache
  echo "  - Updating apt cache..."
  ssh root@$node "apt-get update" 2>&1 > /dev/null

  # Install kubelet, kubeadm, kubectl
  echo "  - Installing kubelet, kubeadm, kubectl..."
  ssh root@$node "apt-get install -y kubelet kubeadm kubectl" 2>&1 > /dev/null

  # Hold packages to prevent automatic updates
  echo "  - Marking packages to prevent automatic updates..."
  ssh root@$node "apt-mark hold kubelet kubeadm kubectl" 2>&1

  # Enable kubelet service
  echo "  - Enabling kubelet service..."
  ssh root@$node "systemctl enable kubelet" 2>&1

  echo "  ✓ Kubernetes packages installed on node $node"
  echo ""
done

echo "=== Kubernetes Packages Installation Complete ==="
echo "End time: $(date)"
