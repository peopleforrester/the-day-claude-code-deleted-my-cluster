#!/bin/bash
# ABOUTME: Script to install Kubernetes packages on all nodes
# ABOUTME: Installs kubeadm, kubelet, and kubectl with version pinning

set -e

NODES="192.168.0.100 192.168.0.101 192.168.0.102 192.168.0.103 192.168.0.104"
KUBERNETES_VERSION="1.31"

echo "Installing Kubernetes packages on all nodes..."

for node in $NODES; do
    echo "=== Configuring $node ==="

    # Install prerequisites
    ssh root@$node "apt-get update -qq && apt-get install -y apt-transport-https ca-certificates curl gpg"
    echo "  - Prerequisites installed"

    # Add Kubernetes repository key
    ssh root@$node "curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
    echo "  - Repository key added"

    # Add Kubernetes repository
    ssh root@$node "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/ /' > /etc/apt/sources.list.d/kubernetes.list"
    echo "  - Repository configured"

    # Update package list
    ssh root@$node "apt-get update -qq"

    # Install Kubernetes packages
    ssh root@$node "apt-get install -y kubelet kubeadm kubectl"
    echo "  - Kubernetes packages installed"

    # Hold packages to prevent automatic updates
    ssh root@$node "apt-mark hold kubelet kubeadm kubectl"
    echo "  - Package versions locked"

    # Enable kubelet service
    ssh root@$node "systemctl enable kubelet"
    echo "  - Kubelet service enabled"

    # Get installed versions
    echo "  - Installed versions:"
    ssh root@$node "kubeadm version -o short"

    echo
done

echo "Kubernetes packages installed on all nodes!"
