#!/bin/bash
# ABOUTME: Script to configure system prerequisites for Kubernetes
# ABOUTME: Disables swap, loads kernel modules, configures sysctl

set -e

NODES="192.168.0.100 192.168.0.101 192.168.0.102 192.168.0.103 192.168.0.104"

echo "Configuring system prerequisites on all nodes..."

for node in $NODES; do
    echo "=== Configuring $node ==="

    # Disable swap
    ssh root@$node "swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab"
    echo "  - Swap disabled"

    # Load required kernel modules
    ssh root@$node "cat > /etc/modules-load.d/k8s.conf << EOF
overlay
br_netfilter
EOF"

    ssh root@$node "modprobe overlay && modprobe br_netfilter"
    echo "  - Kernel modules loaded"

    # Configure sysctl params
    ssh root@$node "cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF"

    ssh root@$node "sysctl --system > /dev/null 2>&1"
    echo "  - Sysctl parameters configured"

    # Update system packages
    ssh root@$node "apt-get update -qq && apt-get upgrade -y -qq"
    echo "  - System packages updated"

    echo "  - Prerequisites configured successfully"
    echo
done

echo "All nodes configured successfully!"
