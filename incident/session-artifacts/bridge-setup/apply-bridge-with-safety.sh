#!/bin/bash
# Apply bridge configuration with safety rollback

NODE="k8s04"
NODE_IP="192.168.0.53"

echo "========================================="
echo "Applying Bridge Configuration on $NODE"
echo "========================================="

# First, fix the permissions issue
echo "1. Fixing configuration file permissions..."
ssh root@$NODE_IP "chmod 600 /etc/netplan/60-kubevirt-bridge.yaml"

# Create a rollback script on the node
echo "2. Creating rollback script on node..."
ssh root@$NODE_IP 'cat > /tmp/rollback-network.sh << "EOF"
#!/bin/bash
# This script will run after 60 seconds to rollback if we lose connectivity
sleep 60
if ! ping -c 1 192.168.0.1 > /dev/null 2>&1; then
    rm -f /etc/netplan/60-kubevirt-bridge.yaml
    netplan apply
fi
EOF'

ssh root@$NODE_IP "chmod +x /tmp/rollback-network.sh"

# Start the rollback timer in background
echo "3. Starting safety rollback timer (60 seconds)..."
ssh root@$NODE_IP "nohup /tmp/rollback-network.sh > /tmp/rollback.log 2>&1 &"

# Apply the configuration
echo "4. Applying netplan configuration..."
ssh root@$NODE_IP "netplan apply"

# Quick connectivity check
echo "5. Checking connectivity..."
sleep 3
if ping -c 3 -W 2 $NODE_IP > /dev/null 2>&1; then
    echo "   ✓ Connectivity maintained"

    # Cancel the rollback
    ssh root@$NODE_IP "pkill -f rollback-network.sh 2>/dev/null || true"
    echo "   ✓ Rollback timer cancelled"
else
    echo "   ✗ Connectivity lost! Waiting for automatic rollback..."
    sleep 65
    if ping -c 3 -W 2 $NODE_IP > /dev/null 2>&1; then
        echo "   ✓ Connectivity restored after rollback"
    else
        echo "   ✗ CRITICAL: Cannot reach node!"
        exit 1
    fi
fi

# Verify bridge creation
echo "6. Verifying bridge..."
if ssh root@$NODE_IP "ip link show br0" 2>/dev/null; then
    echo "   ✓ Bridge br0 exists"
else
    echo "   ✗ Bridge br0 not found"
fi

# Check node status
echo "7. Checking Kubernetes node status..."
kubectl get node $NODE

echo ""
echo "========================================="
echo "Configuration Applied"
echo "========================================="
