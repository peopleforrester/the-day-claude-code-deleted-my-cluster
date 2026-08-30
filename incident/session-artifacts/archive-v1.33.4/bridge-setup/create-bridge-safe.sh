#!/bin/bash
# Safe bridge creation script for k8s04
# This script creates a bridge WITHOUT breaking network connectivity

set -e

NODE="k8s04"
NODE_IP="192.168.0.53"

echo "========================================="
echo "Safe Bridge Creation for $NODE"
echo "========================================="

# Step 1: Backup current configuration
echo "1. Backing up current network configuration..."
ssh root@$NODE_IP "cp -v /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.backup.$(date +%Y%m%d-%H%M%S)"

# Step 2: Create bridge configuration that ADDS br0 without changing primary interface
echo "2. Creating safe bridge configuration..."
cat <<'EOF' | ssh root@$NODE_IP 'cat > /etc/netplan/60-kubevirt-bridge.yaml'
# KubeVirt bridge configuration
# This creates br0 without disrupting the primary network
network:
  version: 2
  bridges:
    br0:
      interfaces: []
      dhcp4: false
      dhcp6: false
      parameters:
        stp: false
        forward-delay: 0
EOF

echo "3. Validating configuration syntax..."
ssh root@$NODE_IP "netplan generate" || {
    echo "ERROR: Configuration validation failed!"
    ssh root@$NODE_IP "rm -f /etc/netplan/60-kubevirt-bridge.yaml"
    exit 1
}

echo "4. Testing configuration with automatic rollback (120 second timeout)..."
echo "   If the connection is lost, the configuration will automatically revert."

# Use netplan try which will automatically rollback if we lose connection
ssh root@$NODE_IP "netplan try --timeout 120" &
NETPLAN_PID=$!

echo "   Waiting for netplan to apply..."
sleep 5

# Test connectivity
echo "5. Testing connectivity..."
if ping -c 3 -W 2 $NODE_IP > /dev/null 2>&1; then
    echo "   ✓ Network connectivity maintained"
else
    echo "   ✗ Network connectivity lost! Waiting for automatic rollback..."
    wait $NETPLAN_PID
    exit 1
fi

# Check if bridge was created
echo "6. Verifying bridge creation..."
if ssh root@$NODE_IP "ip link show br0" > /dev/null 2>&1; then
    echo "   ✓ Bridge br0 created successfully"
    ssh root@$NODE_IP "ip link show br0"
else
    echo "   ✗ Bridge creation failed"
    exit 1
fi

# Accept the configuration if everything is working
echo "7. Accepting configuration..."
ssh root@$NODE_IP "killall netplan 2>/dev/null || true"  # This accepts the try
sleep 2

# Apply permanently
echo "8. Applying configuration permanently..."
ssh root@$NODE_IP "netplan apply"

# Final verification
echo "9. Final verification..."
echo "   Node connectivity:"
ping -c 3 $NODE_IP > /dev/null 2>&1 && echo "   ✓ Ping successful" || echo "   ✗ Ping failed"

echo "   Kubernetes node status:"
kubectl get node $NODE || echo "   ✗ Cannot reach node via kubectl"

echo "   Bridge status:"
ssh root@$NODE_IP "ip -br link show br0"

echo ""
echo "========================================="
echo "Bridge Creation Complete"
echo "========================================="
echo "Bridge br0 has been created on $NODE"
echo "Primary network connectivity maintained on enp1s0"
echo ""
echo "Next steps:"
echo "1. Create NetworkAttachmentDefinition for Multus"
echo "2. Test pod connectivity with bridge"
echo "3. If successful, proceed to other nodes"
