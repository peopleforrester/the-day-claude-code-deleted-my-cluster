#!/bin/bash
# Step 11: Join Worker Nodes to Kubernetes Cluster

set -e

echo "========================================="
echo "Step 11: Join Worker Nodes"
echo "========================================="

# Worker nodes configuration
WORKERS=("k8s04" "k8s05" "k8s06" "k8s07" "k8s08" "k8s09")
WORKER_IPS=("192.168.0.53" "192.168.0.54" "192.168.0.55" "192.168.0.56" "192.168.0.57" "192.168.0.58")

# Join command (from Step 06)
JOIN_TOKEN="<REDACTED-KUBEADM-TOKEN>"
CA_CERT_HASH="sha256:4b39b4e58fbaddba3424dc38184cb11ee5bd0ae0578ffd763bde00921e8bdd46"
API_SERVER="192.168.0.200:6443"

# Pre-join verification
echo ""
echo "Pre-Join Verification:"
echo "======================"

# Check current cluster state
echo "Current cluster nodes:"
kubectl get nodes

echo ""
echo "Token validation:"
ssh root@192.168.0.50 "kubeadm token list | grep $JOIN_TOKEN"

# Function to join a worker node
join_worker() {
    local NODE=$1
    local NODE_IP=$2

    echo ""
    echo "========================================="
    echo "Joining $NODE ($NODE_IP)"
    echo "========================================="

    # Pre-checks
    echo "Pre-flight checks for $NODE..."
    ssh root@$NODE_IP "systemctl is-active containerd" || {
        echo "ERROR: containerd not active on $NODE"
        return 1
    }

    # Check if already joined
    if kubectl get nodes | grep -q $NODE; then
        echo "WARNING: $NODE appears to already be in the cluster"
        return 0
    fi

    # Create join script on remote node
    echo "Creating join script on $NODE..."
    ssh root@$NODE_IP "cat > /tmp/join-cluster.sh << 'EOF'
#!/bin/bash
kubeadm join $API_SERVER \\
    --token $JOIN_TOKEN \\
    --discovery-token-ca-cert-hash $CA_CERT_HASH \\
    --v=2
EOF"

    ssh root@$NODE_IP "chmod +x /tmp/join-cluster.sh"

    # Execute join
    echo "Executing join command on $NODE..."
    ssh root@$NODE_IP "/tmp/join-cluster.sh"

    # Wait for node to appear
    echo "Waiting for $NODE to appear in cluster..."
    local count=0
    while [ $count -lt 30 ]; do
        if kubectl get nodes | grep -q $NODE; then
            echo "✓ $NODE has joined the cluster"
            break
        fi
        sleep 2
        count=$((count+1))
    done

    if [ $count -eq 30 ]; then
        echo "WARNING: Timeout waiting for $NODE to appear"
        return 1
    fi

    # Wait for node to be ready
    echo "Waiting for $NODE to become Ready..."
    kubectl wait --for=condition=Ready node/$NODE --timeout=120s || true

    # Verify node status
    echo "Node $NODE status:"
    kubectl get node $NODE

    # Check pods on new node
    echo "Checking pods scheduled on $NODE..."
    sleep 10
    kubectl get pods -A -o wide | grep $NODE | head -5

    echo "✓ $NODE successfully joined and configured"

    return 0
}

# Join workers one by one
echo ""
echo "========================================="
echo "Beginning Worker Node Join Process"
echo "========================================="

FAILED_NODES=()

for i in ${!WORKERS[@]}; do
    NODE="${WORKERS[$i]}"
    NODE_IP="${WORKER_IPS[$i]}"

    if join_worker "$NODE" "$NODE_IP"; then
        echo "✓ Successfully joined $NODE"
    else
        echo "✗ Failed to join $NODE"
        FAILED_NODES+=("$NODE")
    fi

    # Brief pause between joins
    sleep 5
done

# Final verification
echo ""
echo "========================================="
echo "Final Cluster Verification"
echo "========================================="

echo "All nodes in cluster:"
kubectl get nodes -o wide

echo ""
echo "Node resource allocation:"
kubectl top nodes || echo "Metrics server not installed"

echo ""
echo "Pods per node:"
kubectl get pods -A -o wide | awk '{print $8}' | sort | uniq -c | sort -rn

echo ""
echo "System pods status:"
kubectl get pods -n kube-system | grep -E "(cilium|multus|coredns|kube-proxy)"

# Check for any issues
echo ""
echo "Checking for any issues..."
kubectl get pods -A | grep -v Running | grep -v Completed || echo "All pods healthy"

# Summary
echo ""
echo "========================================="
echo "Worker Join Summary"
echo "========================================="

if [ ${#FAILED_NODES[@]} -eq 0 ]; then
    echo "✓ All worker nodes successfully joined!"
    echo ""
    echo "Cluster composition:"
    echo "  Control Planes: 3 (k8s01, k8s02, k8s03)"
    echo "  Workers: 6 (k8s04, k8s05, k8s06, k8s07, k8s08, k8s09)"
    echo "  Total: 9 nodes"
else
    echo "⚠ Some nodes failed to join:"
    printf '%s\n' "${FAILED_NODES[@]}"
    echo ""
    echo "Please investigate and retry failed nodes manually"
fi

echo ""
echo "Next steps:"
echo "1. Verify all nodes are Ready"
echo "2. Configure bridge interfaces for KubeVirt"
echo "3. Install Longhorn storage"
echo "4. Install KubeVirt"
