#!/bin/bash
# Configure system prerequisites for Kubernetes on all nodes

NODES=("192.168.0.183" "192.168.0.194" "192.168.0.196" "192.168.0.197" "192.168.0.198")

echo "=== Configuring System Prerequisites ==="
echo "Start time: $(date)"
echo ""

# Create the sysctl configuration for Kubernetes
cat > /tmp/kubernetes-sysctl.conf << 'EOF'
# Kubernetes prerequisites
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

# Create the modules configuration
cat > /tmp/kubernetes-modules.conf << 'EOF'
overlay
br_netfilter
EOF

for node in "${NODES[@]}"; do
  echo "Configuring node $node..."

  # Disable swap
  echo "  - Disabling swap..."
  ssh root@$node "swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab" 2>&1

  # Load required kernel modules
  echo "  - Loading kernel modules..."
  ssh root@$node "modprobe overlay && modprobe br_netfilter" 2>&1

  # Persist kernel modules
  echo "  - Persisting kernel modules..."
  scp /tmp/kubernetes-modules.conf root@$node:/etc/modules-load.d/kubernetes.conf 2>&1

  # Configure sysctl parameters
  echo "  - Configuring sysctl parameters..."
  scp /tmp/kubernetes-sysctl.conf root@$node:/etc/sysctl.d/99-kubernetes.conf 2>&1
  ssh root@$node "sysctl --system" 2>&1 > /dev/null

  # Update and install basic packages
  echo "  - Installing basic packages..."
  ssh root@$node "apt-get update && apt-get install -y apt-transport-https ca-certificates curl gpg" 2>&1 > /dev/null

  echo "  ✓ Node $node configured"
  echo ""
done

# Cleanup temporary files
rm -f /tmp/kubernetes-sysctl.conf /tmp/kubernetes-modules.conf

echo "=== Prerequisites Configuration Complete ==="
echo "End time: $(date)"
