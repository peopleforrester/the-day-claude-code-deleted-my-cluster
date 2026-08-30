#!/bin/bash
# Fix Multus CNI configuration to work with Cilium

NODE_IP="$1"
if [ -z "$NODE_IP" ]; then
    echo "Usage: $0 <node-ip>"
    exit 1
fi

echo "========================================="
echo "Fixing Multus CNI on $NODE_IP"
echo "========================================="

# Backup current configuration
echo "1. Backing up current CNI configuration..."
ssh root@$NODE_IP "cp -r /etc/cni/net.d /etc/cni/net.d.backup.$(date +%Y%m%d-%H%M%S)"

# Create proper Multus configuration
echo "2. Creating proper Multus configuration..."
ssh root@$NODE_IP 'cat > /etc/cni/net.d/00-multus.conf << "EOF"
{
  "cniVersion": "0.3.1",
  "name": "multus-cni-network",
  "type": "multus",
  "capabilities": {
    "portMappings": true
  },
  "kubeconfig": "/etc/cni/net.d/multus.d/multus.kubeconfig",
  "delegates": [
    {
      "cniVersion": "0.3.1",
      "name": "cilium",
      "plugins": [
        {
          "type": "cilium-cni",
          "enable-debug": false,
          "log-file": "/var/run/cilium/cilium-cni.log"
        }
      ]
    }
  ]
}
EOF'

# Move Cilium config to backup
echo "3. Moving Cilium config to backup..."
ssh root@$NODE_IP "mv /etc/cni/net.d/05-cilium.conflist /etc/cni/net.d/05-cilium.conflist.bak 2>/dev/null || true"

# Restart kubelet to pick up new CNI config
echo "4. Restarting kubelet..."
ssh root@$NODE_IP "systemctl restart kubelet"

# Wait for kubelet to be ready
echo "5. Waiting for kubelet to be ready..."
sleep 5

# Verify kubelet status
echo "6. Verifying kubelet status..."
ssh root@$NODE_IP "systemctl is-active kubelet"

# Check node status
echo "7. Checking node status..."
kubectl get node $(ssh root@$NODE_IP hostname) --no-headers | awk '{print "Node Status: "$2}'

echo "========================================="
echo "CNI Fix Complete"
echo "========================================="
