#!/bin/bash
# Pre-join validation for worker nodes

echo "========================================="
echo "Worker Nodes Pre-Join Validation"
echo "========================================="

WORKERS=("k8s04" "k8s05" "k8s06" "k8s07" "k8s08" "k8s09")
WORKER_IPS=("192.168.0.53" "192.168.0.54" "192.168.0.55" "192.168.0.56" "192.168.0.57" "192.168.0.58")

ALL_GOOD=true

for i in ${!WORKERS[@]}; do
    NODE="${WORKERS[$i]}"
    NODE_IP="${WORKER_IPS[$i]}"

    echo ""
    echo "Checking $NODE ($NODE_IP):"
    echo "------------------------"

    # SSH connectivity
    echo -n "  SSH connectivity: "
    if ssh -o ConnectTimeout=2 root@$NODE_IP "true" 2>/dev/null; then
        echo "✓"
    else
        echo "✗ FAILED"
        ALL_GOOD=false
        continue
    fi

    # Hostname
    echo -n "  Hostname: "
    ACTUAL_HOSTNAME=$(ssh root@$NODE_IP "hostname" 2>/dev/null)
    if [ "$ACTUAL_HOSTNAME" == "$NODE" ]; then
        echo "✓ $ACTUAL_HOSTNAME"
    else
        echo "⚠ Expected $NODE, got $ACTUAL_HOSTNAME"
    fi

    # Kubernetes packages
    echo -n "  kubelet version: "
    ssh root@$NODE_IP "kubelet --version 2>/dev/null | awk '{print \$2}'" || echo "✗ Not installed"

    echo -n "  kubeadm version: "
    ssh root@$NODE_IP "kubeadm version -o short 2>/dev/null" || echo "✗ Not installed"

    # Container runtime
    echo -n "  containerd: "
    if ssh root@$NODE_IP "systemctl is-active containerd" 2>/dev/null | grep -q active; then
        echo "✓ active"
    else
        echo "✗ not active"
        ALL_GOOD=false
    fi

    # Network settings
    echo -n "  IP forwarding: "
    if ssh root@$NODE_IP "sysctl net.ipv4.ip_forward" 2>/dev/null | grep -q "= 1"; then
        echo "✓ enabled"
    else
        echo "✗ disabled"
        ALL_GOOD=false
    fi

    # Swap
    echo -n "  Swap: "
    SWAP=$(ssh root@$NODE_IP "swapon --show" 2>/dev/null)
    if [ -z "$SWAP" ]; then
        echo "✓ disabled"
    else
        echo "✗ enabled (must be disabled)"
        ALL_GOOD=false
    fi

    # Already joined?
    echo -n "  Cluster membership: "
    if kubectl get nodes 2>/dev/null | grep -q $NODE; then
        echo "⚠ Already in cluster"
    else
        echo "✓ Not in cluster"
    fi
done

echo ""
echo "========================================="
if [ "$ALL_GOOD" = true ]; then
    echo "✓ All worker nodes ready to join"
else
    echo "✗ Some issues detected - please fix before joining"
fi
echo "========================================="
