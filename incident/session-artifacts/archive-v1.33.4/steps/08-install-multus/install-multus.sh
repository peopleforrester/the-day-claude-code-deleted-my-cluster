#!/bin/bash
# Step 08: Install Multus CNI v4.2.2

set -e

echo "========================================="
echo "Step 08: Install Multus CNI v4.2.2"
echo "========================================="

# Check current state
echo ""
echo "Current CNI State:"
echo "=================="
kubectl get nodes
echo ""
echo "Pending pods (waiting for CNI):"
kubectl get pods -n kube-system | grep Pending || echo "No pending pods"

# Apply Multus v4.2.2
echo ""
echo "Applying Multus v4.2.2 manifest..."
kubectl apply -f multus-v4.2.2.yaml

# Wait for Multus to be ready
echo ""
echo "Waiting for Multus DaemonSet to be ready..."
kubectl rollout status daemonset/kube-multus-ds -n kube-system --timeout=300s

# Check Multus pods
echo ""
echo "Multus pods status:"
kubectl get pods -n kube-system -l app=multus -o wide

# Verify Multus installation on each node
echo ""
echo "Verifying Multus binary on nodes:"
for ip in 50 51 52; do
    NODE="k8s$(printf %02d $((ip-49)))"
    echo -n "$NODE: "
    ssh root@192.168.0.$ip "ls -la /opt/cni/bin/multus 2>/dev/null && echo 'Multus installed' || echo 'Multus NOT found'"
done

# Check CNI configuration
echo ""
echo "CNI Configuration on k8s01:"
ssh root@192.168.0.50 "ls -la /etc/cni/net.d/ | grep -v '^total' | grep -v '.kubernetes-cni-keep'"

# Check if nodes are becoming ready (they won't yet without Cilium)
echo ""
echo "Node status after Multus installation:"
kubectl get nodes

echo ""
echo "========================================="
echo "Multus v4.2.2 Installation Complete"
echo "========================================="
echo "Note: Nodes will remain NotReady until Cilium is installed in Step 09"
