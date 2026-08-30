#!/bin/bash
# ABOUTME: Complete cluster teardown script
# ABOUTME: Removes all Kubernetes components and configurations

set -e

echo "=========================================="
echo "KUBERNETES CLUSTER COMPLETE TEARDOWN"
echo "=========================================="
echo ""
echo "This will completely destroy the Kubernetes cluster on nodes:"
echo "- 192.168.0.100 (master1)"
echo "- 192.168.0.101 (master2)"
echo "- 192.168.0.102 (master3)"
echo "- 192.168.0.103 (worker1)"
echo "- 192.168.0.104 (worker2)"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Teardown cancelled."
    exit 1
fi

# Define nodes
MASTERS="192.168.0.100 192.168.0.101 192.168.0.102"
WORKERS="192.168.0.103 192.168.0.104"
ALL_NODES="$MASTERS $WORKERS"

echo ""
echo ">>> Step 1: Draining and deleting nodes from cluster"
echo "=================================================="
# Try to drain nodes if cluster is still accessible
ssh root@192.168.0.100 'kubectl get nodes >/dev/null 2>&1 && {
    for node in worker1 worker2; do
        echo "Draining $node..."
        kubectl drain $node --ignore-daemonsets --force --delete-emptydir-data || true
        kubectl delete node $node || true
    done
}' || echo "Cluster not accessible, skipping node drain"

echo ""
echo ">>> Step 2: Resetting kubeadm on all nodes"
echo "=================================================="
for node in $ALL_NODES; do
    echo "Resetting kubeadm on $node..."
    ssh root@$node 'kubeadm reset -f' || true
done

echo ""
echo ">>> Step 3: Stopping and disabling services"
echo "=================================================="
for node in $ALL_NODES; do
    echo "Stopping services on $node..."
    ssh root@$node '
        systemctl stop kubelet || true
        systemctl disable kubelet || true
        systemctl stop containerd || true
        systemctl disable containerd || true
    '
done

echo ""
echo ">>> Step 4: Removing Kubernetes packages"
echo "=================================================="
for node in $ALL_NODES; do
    echo "Removing packages on $node..."
    ssh root@$node '
        apt-mark unhold kubelet kubeadm kubectl || true
        apt-get remove -y --purge kubelet kubeadm kubectl kubernetes-cni || true
        apt-get autoremove -y || true
    '
done

echo ""
echo ">>> Step 5: Removing containerd"
echo "=================================================="
for node in $ALL_NODES; do
    echo "Removing containerd on $node..."
    ssh root@$node '
        apt-get remove -y --purge containerd.io || true
        rm -rf /etc/containerd
    '
done

echo ""
echo ">>> Step 6: Cleaning up directories and files"
echo "=================================================="
for node in $ALL_NODES; do
    echo "Cleaning up $node..."
    ssh root@$node '
        # Remove Kubernetes directories
        rm -rf /etc/kubernetes
        rm -rf /var/lib/kubelet
        rm -rf /var/lib/etcd
        rm -rf /var/lib/dockershim
        rm -rf /var/lib/cni
        rm -rf /var/lib/calico
        rm -rf /run/flannel
        rm -rf /etc/cni
        rm -rf /opt/cni
        rm -rf /var/run/kubernetes
        rm -rf /home/kubernetes

        # Remove kubeconfig
        rm -rf ~/.kube

        # Remove manifests
        rm -rf /etc/kubernetes/manifests

        # Clean up systemd
        rm -f /etc/systemd/system/kubelet.service
        rm -f /etc/systemd/system/kubelet.service.d
        systemctl daemon-reload
    '
done

echo ""
echo ">>> Step 7: Cleaning up network configurations"
echo "=================================================="
for node in $ALL_NODES; do
    echo "Cleaning network on $node..."
    ssh root@$node '
        # Remove CNI interfaces
        ip link delete cni0 2>/dev/null || true
        ip link delete flannel.1 2>/dev/null || true
        ip link delete calico 2>/dev/null || true
        ip link delete tunl0 2>/dev/null || true
        ip link delete nodelocaldns 2>/dev/null || true

        # Clean up iptables rules
        iptables -F
        iptables -t nat -F
        iptables -t mangle -F
        iptables -X

        # Remove bridge
        modprobe -r bridge || true

        # Clean routing
        ip route flush proto bird || true
    '
done

echo ""
echo ">>> Step 8: Removing repository configurations"
echo "=================================================="
for node in $ALL_NODES; do
    echo "Cleaning repos on $node..."
    ssh root@$node '
        rm -f /etc/apt/sources.list.d/kubernetes.list
        rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        rm -f /etc/apt/sources.list.d/docker.list
        rm -f /etc/apt/keyrings/docker.gpg
        apt-get update
    '
done

echo ""
echo ">>> Step 9: Final cleanup"
echo "=================================================="
for node in $ALL_NODES; do
    echo "Final cleanup on $node..."
    ssh root@$node '
        # Remove any remaining container data
        rm -rf /var/lib/containerd
        rm -rf /var/lib/docker

        # Remove logs
        rm -rf /var/log/pods
        rm -rf /var/log/containers

        # Reset sysctl settings
        rm -f /etc/sysctl.d/99-kubernetes-cri.conf
        rm -f /etc/sysctl.d/k8s.conf
        sysctl --system

        # Remove modules config
        rm -f /etc/modules-load.d/k8s.conf
        rm -f /etc/modules-load.d/containerd.conf

        # Remove crictl config
        rm -f /etc/crictl.yaml

        # Reboot flag
        touch /tmp/needs-reboot
    '
done

echo ""
echo ">>> Step 10: Verification"
echo "=================================================="
for node in $ALL_NODES; do
    echo "Verifying $node..."
    ssh root@$node '
        echo "Checking for remaining k8s processes..."
        ps aux | grep -E "kube|etcd|containerd" | grep -v grep || echo "✓ No k8s processes found"

        echo "Checking for remaining k8s files..."
        ls -la /etc/kubernetes 2>/dev/null && echo "✗ kubernetes directory still exists" || echo "✓ kubernetes directory removed"

        echo "Checking network interfaces..."
        ip link show | grep -E "cni0|flannel|calico|tunl0" || echo "✓ No CNI interfaces found"
    '
    echo ""
done

echo ""
echo "=========================================="
echo "CLUSTER TEARDOWN COMPLETE!"
echo "=========================================="
echo ""
echo "The following has been removed:"
echo "✓ All Kubernetes components"
echo "✓ Container runtime (containerd)"
echo "✓ Network configurations"
echo "✓ All cluster data and configurations"
echo ""
echo "Note: You may want to reboot all nodes to ensure complete cleanup:"
echo "for node in $ALL_NODES; do ssh root@\$node 'reboot'; done"
echo ""
