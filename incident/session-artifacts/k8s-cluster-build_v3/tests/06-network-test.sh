#!/bin/bash
# ABOUTME: Test script to verify network configuration is suitable for Kubernetes
# ABOUTME: Checks that each node has a unique IP address

set -e

echo "Running network configuration tests..."

NODES="192.168.0.100 192.168.0.101 192.168.0.102 192.168.0.103 192.168.0.104"
declare -A NODE_IPS
FAILURES=0

echo "Collecting IP addresses from all nodes..."
for node in $NODES; do
    echo -n "Node $node: "
    IP=$(ssh root@$node 'hostname -I | awk "{print \$1}"' 2>/dev/null)
    echo "$IP"

    # Check if we've seen this IP before
    if [[ -n "${NODE_IPS[$IP]}" ]]; then
        echo "  ERROR: Duplicate IP! Also used by ${NODE_IPS[$IP]}"
        ((FAILURES++))
    else
        NODE_IPS[$IP]=$node
    fi
done

echo
echo "Testing node-to-node connectivity..."
# Test from master1 to master2
echo -n "master1 -> master2: "
if ssh root@192.168.0.100 'ping -c 1 -W 2 10.0.2.2' >/dev/null 2>&1; then
    echo "REACHABLE ✓"
else
    echo "UNREACHABLE ✗"
    ((FAILURES++))
fi

echo
echo "========================================"
if [[ $FAILURES -eq 0 ]]; then
    echo "Network configuration is suitable for Kubernetes"
    exit 0
else
    echo "$FAILURES issues found with network configuration"
    echo "CRITICAL: VMs need unique IP addresses for Kubernetes to work!"
    echo "Please reconfigure VM networking from NAT to Bridged mode."
    exit 1
fi
