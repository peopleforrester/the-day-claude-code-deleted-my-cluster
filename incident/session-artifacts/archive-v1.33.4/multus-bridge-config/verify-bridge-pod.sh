#!/bin/bash
# Verify bridge connectivity for test pod

POD_NAME="${1:-bridge-test-k8s04}"
NODE="${2:-k8s04}"

echo "========================================="
echo "Bridge Pod Verification for $POD_NAME on $NODE"
echo "========================================="
echo

# Check if pod exists and is running
echo "1. Pod Status:"
kubectl get pod $POD_NAME -o wide || {
    echo "   Pod not found or not running"
    exit 1
}

# Wait for pod to be ready
echo
echo "2. Waiting for pod to be ready..."
kubectl wait --for=condition=ready pod/$POD_NAME --timeout=30s || {
    echo "   Pod failed to become ready"
    exit 1
}

# Check pod network interfaces
echo
echo "3. Pod Network Interfaces:"
kubectl exec $POD_NAME -- ip -br addr show

# Check if net1 interface exists (Multus interface)
echo
echo "4. Checking for Multus interface (net1):"
kubectl exec $POD_NAME -- ip link show net1 2>/dev/null && echo "   ✓ Multus interface found" || echo "   ✗ No Multus interface"

# Check pod events
echo
echo "5. Recent Pod Events:"
kubectl get events --field-selector involvedObject.name=$POD_NAME --sort-by='.lastTimestamp' | tail -5

# Check pod logs for any errors
echo
echo "6. Container Logs:"
kubectl logs $POD_NAME --tail=10 2>/dev/null || echo "   No logs available"

# Get pod annotations to verify Multus
echo
echo "7. Multus Annotations:"
kubectl get pod $POD_NAME -o jsonpath='{.metadata.annotations.k8s\.v1\.cni\.cncf\.io/networks-status}' | python3 -m json.tool 2>/dev/null || echo "   No Multus status annotation"

echo
echo "========================================="
echo "Verification Complete"
echo "========================================="
