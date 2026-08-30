#!/bin/bash
# Generic bridge setup script for any worker node

NODE="$1"
NODE_IP="$2"

if [ -z "$NODE" ] || [ -z "$NODE_IP" ]; then
    echo "Usage: $0 <node-name> <node-ip>"
    echo "Example: $0 k8s05 192.168.0.54"
    exit 1
fi

echo "========================================="
echo "Bridge Setup for $NODE ($NODE_IP)"
echo "========================================="

# Pre-check
echo "Running pre-check..."
./verify-node-health.sh $NODE $NODE_IP
if [ $? -ne 0 ]; then
    echo "ERROR: Node is not healthy before bridge setup!"
    exit 1
fi

# Backup current config
echo ""
echo "1. Backing up current configuration..."
ssh root@$NODE_IP "cp -v /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.backup.$(date +%Y%m%d-%H%M%S)"

# Create bridge configuration
echo "2. Creating bridge configuration..."
ssh root@$NODE_IP 'cat > /etc/netplan/60-kubevirt-bridge.yaml << "EOF"
# KubeVirt bridge configuration
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
EOF'

# Set proper permissions
echo "3. Setting file permissions..."
ssh root@$NODE_IP "chmod 600 /etc/netplan/60-kubevirt-bridge.yaml"

# Create safety rollback
echo "4. Creating safety rollback (60 seconds)..."
ssh root@$NODE_IP 'cat > /tmp/rollback-network.sh << "EOF"
#!/bin/bash
sleep 60
if ! ping -c 1 192.168.0.1 > /dev/null 2>&1; then
    rm -f /etc/netplan/60-kubevirt-bridge.yaml
    netplan apply
    echo "Network rolled back due to connectivity loss" >> /var/log/bridge-rollback.log
fi
EOF'

ssh root@$NODE_IP "chmod +x /tmp/rollback-network.sh"
ssh root@$NODE_IP "nohup /tmp/rollback-network.sh > /tmp/rollback.log 2>&1 &"

# Apply configuration
echo "5. Applying netplan configuration..."
ssh root@$NODE_IP "netplan apply"

# Wait and test
sleep 3

echo "6. Testing connectivity..."
if ping -c 3 -W 2 $NODE_IP > /dev/null 2>&1; then
    echo "   ✓ Connectivity maintained"
    ssh root@$NODE_IP "pkill -f rollback-network.sh 2>/dev/null || true"
    echo "   ✓ Rollback cancelled"
else
    echo "   ✗ Connectivity lost! Waiting for rollback..."
    sleep 65
    if ping -c 3 -W 2 $NODE_IP > /dev/null 2>&1; then
        echo "   ✓ Connectivity restored"
    else
        echo "   ✗ CRITICAL: Node unreachable!"
        exit 1
    fi
fi

# Verify bridge
echo "7. Verifying bridge creation..."
if ssh root@$NODE_IP "ip link show br0" 2>/dev/null; then
    echo "   ✓ Bridge br0 created"
else
    echo "   ✗ Bridge not created"
    exit 1
fi

# Final health check
echo ""
echo "8. Final health check..."
./verify-node-health.sh $NODE $NODE_IP

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "✓ Bridge Setup Complete for $NODE"
    echo "========================================="
else
    echo ""
    echo "========================================="
    echo "✗ Bridge Setup Failed for $NODE"
    echo "========================================="
    exit 1
fi
