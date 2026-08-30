#!/bin/bash
# Pre-bridge check for k8s04

NODE="k8s04"
NODE_IP="192.168.0.53"

echo "========================================="
echo "Pre-Bridge Check for $NODE"
echo "========================================="

echo ""
echo "1. Current Network Status:"
echo "   ------------------------"
ssh root@$NODE_IP "ip -br addr show enp1s0"

echo ""
echo "2. Current Bridges:"
echo "   ----------------"
ssh root@$NODE_IP "ip link show type bridge 2>/dev/null || echo '   No bridges currently exist'"

echo ""
echo "3. Netplan Files:"
echo "   --------------"
ssh root@$NODE_IP "ls -la /etc/netplan/"

echo ""
echo "4. Node Status in Kubernetes:"
echo "   --------------------------"
kubectl get node $NODE

echo ""
echo "5. Connectivity Tests:"
echo "   -------------------"
echo -n "   Ping test: "
ping -c 1 -W 2 $NODE_IP > /dev/null 2>&1 && echo "✓ Success" || echo "✗ Failed"

echo -n "   SSH test: "
ssh root@$NODE_IP "echo '✓ Success'" 2>/dev/null || echo "✗ Failed"

echo -n "   Kubernetes API: "
kubectl get node $NODE > /dev/null 2>&1 && echo "✓ Success" || echo "✗ Failed"

echo ""
echo "6. Critical Services:"
echo "   -----------------"
ssh root@$NODE_IP "systemctl is-active kubelet containerd | xargs echo '   Services:'"

echo ""
echo "7. Backup Check:"
echo "   -------------"
ssh root@$NODE_IP "ls -la /etc/netplan/*.backup.* 2>/dev/null | wc -l | xargs echo '   Existing backups:'"

echo ""
echo "========================================="
echo "Pre-check complete. Ready to proceed? (y/n)"
echo "========================================="
