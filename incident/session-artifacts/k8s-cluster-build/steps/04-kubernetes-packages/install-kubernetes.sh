#!/bin/bash

# Install Kubernetes packages (kubeadm, kubelet, kubectl)

# Update package index
apt-get update

# Install required packages
apt-get install -y apt-transport-https ca-certificates curl gpg

# Create keyrings directory
mkdir -p /etc/apt/keyrings

# Add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' > /etc/apt/sources.list.d/kubernetes.list

# Update package index with new repo
apt-get update

# Install Kubernetes packages
apt-get install -y kubelet kubeadm kubectl

# Hold packages to prevent automatic updates
apt-mark hold kubelet kubeadm kubectl

# Enable kubelet service
systemctl enable kubelet

# Verify installation
echo "=== Verification ==="
echo "Installed versions:"
echo -n "kubeadm: " && kubeadm version -o short
echo -n "kubelet: " && kubelet --version
echo -n "kubectl: " && kubectl version --client --short
echo ""
echo "Package status:"
dpkg -l | grep -E "kubelet|kubeadm|kubectl" | awk '{print $2 " - " $3}'
