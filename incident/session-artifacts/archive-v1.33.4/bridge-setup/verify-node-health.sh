#!/bin/bash
# Comprehensive health check after bridge creation

NODE="$1"
NODE_IP="$2"

if [ -z "$NODE" ] || [ -z "$NODE_IP" ]; then
    echo "Usage: $0 <node-name> <node-ip>"
    exit 1
fi

echo "========================================="
echo "Health Check for $NODE ($NODE_IP)"
echo "========================================="

ISSUES=0

# 1. Network Connectivity
echo ""
echo "1. Network Connectivity:"
echo -n "   Ping test: "
if ping -c 3 -W 2 $NODE_IP > /dev/null 2>&1; then
    echo "✓ Pass"
else
    echo "✗ FAIL"
    ((ISSUES++))
fi

echo -n "   SSH test: "
if ssh root@$NODE_IP "echo 'connected'" > /dev/null 2>&1; then
    echo "✓ Pass"
else
    echo "✗ FAIL"
    ((ISSUES++))
fi

# 2. Bridge Status
echo ""
echo "2. Bridge Configuration:"
ssh root@$NODE_IP "ip -br link show type bridge" || echo "   No bridges found"
echo "   Bridge details:"
ssh root@$NODE_IP "bridge link show 2>/dev/null || echo '   No bridge members'"

# 3. Primary Interface
echo ""
echo "3. Primary Network Interface:"
PRIMARY_INT=$(ssh root@$NODE_IP "ip route | grep default | awk '{print \$5}'")
echo "   Primary interface: $PRIMARY_INT"
ssh root@$NODE_IP "ip -br addr show $PRIMARY_INT"

# 4. Kubernetes Status
echo ""
echo "4. Kubernetes Status:"
echo -n "   Node status: "
if kubectl get node $NODE --no-headers | grep -q Ready; then
    echo "✓ Ready"
else
    echo "✗ Not Ready"
    ((ISSUES++))
fi

echo -n "   Kubelet: "
if ssh root@$NODE_IP "systemctl is-active kubelet" | grep -q active; then
    echo "✓ Active"
else
    echo "✗ Not Active"
    ((ISSUES++))
fi

echo -n "   Containerd: "
if ssh root@$NODE_IP "systemctl is-active containerd" | grep -q active; then
    echo "✓ Active"
else
    echo "✗ Not Active"
    ((ISSUES++))
fi

# 5. CNI Status
echo ""
echo "5. CNI Status:"
echo "   Cilium pod:"
kubectl get pods -n kube-system -o wide | grep cilium | grep $NODE | head -1

echo "   Multus pod:"
kubectl get pods -n kube-system -o wide | grep multus | grep $NODE | head -1

# 6. System Resources
echo ""
echo "6. System Resources:"
ssh root@$NODE_IP "free -h | grep Mem | awk '{print \"   Memory: \"\$3\" used of \"\$2}'"
ssh root@$NODE_IP "df -h / | tail -1 | awk '{print \"   Disk: \"\$3\" used of \"\$2\" (\"\$5\" full)\"}'"
ssh root@$NODE_IP "uptime | awk -F'load average:' '{print \"   Load:\"\$2}'"

# 7. Recent Errors
echo ""
echo "7. Recent System Errors (last 5 min):"
ssh root@$NODE_IP "journalctl -p err --since '5 minutes ago' 2>/dev/null | tail -3 || echo '   No recent errors'"

# Summary
echo ""
echo "========================================="
if [ $ISSUES -eq 0 ]; then
    echo "✓ Health Check PASSED - No issues found"
else
    echo "✗ Health Check FAILED - $ISSUES issue(s) found"
fi
echo "========================================="

exit $ISSUES
