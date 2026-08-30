#!/bin/bash
# Comprehensive cluster health check script
# Discovery only - no changes

echo "========================================="
echo "COMPREHENSIVE CLUSTER HEALTH CHECK"
echo "Date: $(date)"
echo "========================================="
echo

# Function to check node
check_node() {
    local NODE=$1
    local IP=$2

    echo "=== $NODE ($IP) ==="

    # Basic connectivity
    echo -n "  Ping: "
    ping -c 1 -W 2 $IP > /dev/null 2>&1 && echo "✓" || echo "✗"

    # SSH connectivity
    echo -n "  SSH: "
    ssh -o ConnectTimeout=2 root@$IP "echo '✓'" 2>/dev/null || echo "✗"

    # Get system info
    ssh root@$IP "
        echo '  CPU Load:' \$(uptime | awk -F'load average:' '{print \$2}')
        echo '  Memory:' \$(free -h | grep Mem | awk '{print \$3\" used of \"\$2}')
        echo '  Disk /:' \$(df -h / | tail -1 | awk '{print \$3\" used of \"\$2\" (\"\$5\" full)\"}')
        echo '  Uptime:' \$(uptime -p)
    " 2>/dev/null || echo "  Unable to get system info"

    # Check critical services
    echo "  Services:"
    ssh root@$IP "
        echo -n '    kubelet: '
        systemctl is-active kubelet 2>/dev/null || echo 'not found'
        echo -n '    containerd: '
        systemctl is-active containerd 2>/dev/null || echo 'not found'
    " 2>/dev/null

    # Check for recent errors
    echo "  Recent errors (last 5 min):"
    ssh root@$IP "journalctl -p err --since '5 minutes ago' 2>/dev/null | tail -3 | sed 's/^/    /'" 2>/dev/null || echo "    Unable to check logs"

    echo
}

echo "1. CLUSTER OVERVIEW"
echo "==================="
kubectl cluster-info
echo

echo "2. NODE STATUS"
echo "=============="
kubectl get nodes -o wide
echo

echo "3. INDIVIDUAL NODE HEALTH"
echo "========================="
# Control plane nodes
check_node "k8s01" "192.168.0.50"
check_node "k8s02" "192.168.0.51"
check_node "k8s03" "192.168.0.52"

# Worker nodes
check_node "k8s04" "192.168.0.53"
check_node "k8s05" "192.168.0.54"
check_node "k8s06" "192.168.0.55"
check_node "k8s07" "192.168.0.56"
check_node "k8s08" "192.168.0.57"
check_node "k8s09" "192.168.0.58"

echo "4. CONTROL PLANE COMPONENTS"
echo "============================"
kubectl get pods -n kube-system -l tier=control-plane -o wide
echo

echo "5. CRITICAL SYSTEM PODS"
echo "======================="
echo "Kube-vip:"
kubectl get pods -n kube-system | grep kube-vip
echo
echo "CoreDNS:"
kubectl get pods -n kube-system | grep coredns
echo
echo "Cilium:"
kubectl get pods -n kube-system | grep cilium | head -5
echo
echo "Multus:"
kubectl get pods -n kube-system | grep multus | head -5
echo

echo "6. CLUSTER RESOURCES"
echo "===================="
kubectl top nodes 2>/dev/null || echo "Metrics server not available"
echo

echo "7. PERSISTENT VOLUMES"
echo "====================="
kubectl get pv
echo

echo "8. NETWORK POLICIES"
echo "==================="
kubectl get networkpolicies --all-namespaces
echo

echo "9. EVENTS (Warnings/Errors)"
echo "============================"
kubectl get events --all-namespaces --field-selector type=Warning --sort-by='.lastTimestamp' | tail -10
echo

echo "10. CERTIFICATE EXPIRY"
echo "======================"
kubeadm certs check-expiration 2>/dev/null | head -15 || echo "Unable to check certificates"
echo

echo "========================================="
echo "HEALTH CHECK COMPLETE"
echo "========================================="
