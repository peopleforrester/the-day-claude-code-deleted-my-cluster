#!/bin/bash
# Deep check of Kubernetes components on ALL nodes

NODES=(50 51 52 53 54 55 56 57 58)
echo "===================================="
echo "DEEP KUBERNETES COMPONENT CHECK"
echo "Timestamp: $(date)"
echo "===================================="
echo ""

# Check each node thoroughly
for node in "${NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "NODE: $NODE_NAME ($IP)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 1. Kubernetes binaries
    echo "1. KUBERNETES BINARIES:"
    KUBEADM=$(ssh root@$IP "kubeadm version -o short 2>/dev/null || echo 'NOT FOUND'")
    KUBELET=$(ssh root@$IP "kubelet --version 2>/dev/null | awk '{print \$2}' || echo 'NOT FOUND'")
    KUBECTL=$(ssh root@$IP "kubectl version --client -o yaml 2>/dev/null | grep gitVersion | awk '{print \$2}' || echo 'NOT FOUND'")
    echo "   kubeadm: $KUBEADM"
    echo "   kubelet: $KUBELET"
    echo "   kubectl: $KUBECTL"

    # 2. Services status
    echo ""
    echo "2. SERVICES STATUS:"
    CONTAINERD=$(ssh root@$IP "systemctl is-active containerd 2>/dev/null")
    KUBELET_SVC=$(ssh root@$IP "systemctl is-active kubelet 2>/dev/null")
    echo "   containerd: $CONTAINERD"
    echo "   kubelet: $KUBELET_SVC"

    # 3. Critical files
    echo ""
    echo "3. CRITICAL FILES:"
    FILES=(
        "/etc/containerd/config.toml"
        "/var/lib/kubelet/config.yaml"
        "/etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
        "/run/containerd/containerd.sock"
    )
    for file in "${FILES[@]}"; do
        EXISTS=$(ssh root@$IP "test -e $file && echo 'EXISTS' || echo 'MISSING'")
        echo "   $file: $EXISTS"
    done

    # 4. CNI plugins
    echo ""
    echo "4. CNI PLUGINS:"
    CNI_COUNT=$(ssh root@$IP "ls /opt/cni/bin 2>/dev/null | wc -l")
    CNI_LIST=$(ssh root@$IP "ls /opt/cni/bin 2>/dev/null | head -5 | tr '\n' ' '")
    echo "   Plugin count: $CNI_COUNT"
    echo "   Sample plugins: $CNI_LIST..."

    # 5. Recent errors in logs
    echo ""
    echo "5. RECENT ERRORS (last 10 mins):"
    CONTAINERD_ERRORS=$(ssh root@$IP "journalctl -u containerd --since '10 minutes ago' 2>/dev/null | grep -i error | wc -l")
    KUBELET_ERRORS=$(ssh root@$IP "journalctl -u kubelet --since '10 minutes ago' 2>/dev/null | grep -i error | wc -l")
    echo "   containerd errors: $CONTAINERD_ERRORS"
    echo "   kubelet errors: $KUBELET_ERRORS"

    if [ "$KUBELET_ERRORS" -gt "0" ]; then
        echo "   Sample kubelet errors:"
        ssh root@$IP "journalctl -u kubelet --since '10 minutes ago' 2>/dev/null | grep -i error | head -3" | sed 's/^/     /'
    fi

    # 6. Package versions from dpkg
    echo ""
    echo "6. INSTALLED PACKAGES (dpkg):"
    ssh root@$IP "dpkg -l | grep -E 'kubeadm|kubelet|kubectl|containerd|cri-tools' | awk '{print \"   \" \$2 \": \" \$3}'"

    # 7. Memory and CPU for services
    echo ""
    echo "7. SERVICE RESOURCE USAGE:"
    CONTAINERD_MEM=$(ssh root@$IP "systemctl show containerd -p MemoryCurrent 2>/dev/null | cut -d= -f2")
    KUBELET_MEM=$(ssh root@$IP "systemctl show kubelet -p MemoryCurrent 2>/dev/null | cut -d= -f2")

    if [ "$CONTAINERD_MEM" != "[not set]" ] && [ -n "$CONTAINERD_MEM" ]; then
        CONTAINERD_MEM_MB=$((CONTAINERD_MEM / 1024 / 1024))
        echo "   containerd memory: ${CONTAINERD_MEM_MB}MB"
    else
        echo "   containerd memory: not running or not measurable"
    fi

    if [ "$KUBELET_MEM" != "[not set]" ] && [ -n "$KUBELET_MEM" ]; then
        KUBELET_MEM_MB=$((KUBELET_MEM / 1024 / 1024))
        echo "   kubelet memory: ${KUBELET_MEM_MB}MB"
    else
        echo "   kubelet memory: not started yet (normal - waiting for init)"
    fi

    echo ""
done

echo "===================================="
echo "CHECK COMPLETE"
echo "===================================="
