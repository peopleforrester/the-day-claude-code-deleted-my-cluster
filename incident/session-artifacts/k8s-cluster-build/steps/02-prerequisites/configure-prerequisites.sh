#!/bin/bash

# Configure system prerequisites for Kubernetes

# Disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Load required kernel modules
cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Set up required sysctl params
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sysctl --system

# Verify configuration
echo "=== Verification ==="
echo "Swap status:"
swapon --show || echo "Swap is disabled"
echo ""
echo "Loaded modules:"
lsmod | grep -E "overlay|br_netfilter"
echo ""
echo "Sysctl settings:"
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
