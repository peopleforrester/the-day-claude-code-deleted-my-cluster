#!/bin/bash
# Fix the unnecessary serverTLSBootstrap configuration

echo "========================================="
echo "Fixing serverTLSBootstrap Issue"
echo "========================================="
echo

# Function to fix each node
fix_node() {
    local NODE=$1
    local IP=$2

    echo "Fixing $NODE ($IP)..."

    # Disable serverTLSBootstrap
    ssh root@$IP "sed -i 's/serverTLSBootstrap: true/serverTLSBootstrap: false/' /var/lib/kubelet/config.yaml"

    # Restart kubelet
    ssh root@$IP "systemctl restart kubelet"

    # Wait for kubelet to be ready
    sleep 3

    # Check status
    ssh root@$IP "systemctl is-active kubelet"
}

# Fix all nodes
echo "1. Disabling serverTLSBootstrap on all nodes..."
fix_node "k8s01" "192.168.0.50"
fix_node "k8s02" "192.168.0.51"
fix_node "k8s03" "192.168.0.52"
fix_node "k8s04" "192.168.0.53"
fix_node "k8s05" "192.168.0.54"
fix_node "k8s06" "192.168.0.55"
fix_node "k8s07" "192.168.0.56"
fix_node "k8s08" "192.168.0.57"
fix_node "k8s09" "192.168.0.58"

echo
echo "2. Waiting for nodes to stabilize..."
sleep 10

echo
echo "3. Checking node status..."
kubectl get nodes

echo
echo "4. Cleaning up pending CSRs..."
kubectl get csr -o name | xargs kubectl delete

echo
echo "5. Testing kubectl exec..."
kubectl run test-exec --image=alpine --restart=Never -- sleep 3600 2>/dev/null || true
sleep 5
kubectl exec test-exec -- echo "kubectl exec is working!"
kubectl delete pod test-exec --force --grace-period=0

echo
echo "========================================="
echo "Fix Complete"
echo "========================================="
