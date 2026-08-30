#!/bin/bash
# ABOUTME: Test script for verifying kube-vip setup
# ABOUTME: Validates manifest creation and configuration

set -e

echo "Running kube-vip setup tests..."

MASTER_NODES="192.168.0.100 192.168.0.101 192.168.0.102"
VIP="192.168.0.199"
FAILURES=0

for node in $MASTER_NODES; do
    echo "=== Testing $node ==="

    # Test manifest exists
    echo -n "  - Manifest file exists: "
    if ssh root@$node "test -f /etc/kubernetes/manifests/kube-vip.yaml"; then
        echo "YES ✓"
    else
        echo "NO ✗"
        ((FAILURES++))
    fi

    # Test VIP address is configured
    echo -n "  - VIP address configured: "
    if ssh root@$node "grep -A1 'name: address' /etc/kubernetes/manifests/kube-vip.yaml | grep -q 'value: $VIP'"; then
        echo "$VIP ✓"
    else
        echo "NOT FOUND ✗"
        ((FAILURES++))
    fi

    # Test for ARP mode
    echo -n "  - ARP mode enabled: "
    if ssh root@$node "grep -q 'vip_arp' /etc/kubernetes/manifests/kube-vip.yaml"; then
        echo "YES ✓"
    else
        echo "NO ✗"
        ((FAILURES++))
    fi

    # Test for leader election
    echo -n "  - Leader election enabled: "
    if ssh root@$node "grep -q 'vip_leaderelection' /etc/kubernetes/manifests/kube-vip.yaml"; then
        echo "YES ✓"
    else
        echo "NO ✗"
        ((FAILURES++))
    fi

    # Test kube-vip image is available
    echo -n "  - kube-vip image: "
    if ssh root@$node "ctr -n=k8s.io images check | grep kube-vip" >/dev/null 2>&1; then
        echo "AVAILABLE ✓"
    else
        echo "NOT FOUND ✗"
        ((FAILURES++))
    fi

    echo
done

echo "========================================"
if [[ $FAILURES -eq 0 ]]; then
    echo "All kube-vip tests PASSED"
    echo "Note: VIP will be activated after cluster initialization"
    exit 0
else
    echo "$FAILURES tests FAILED"
    exit 1
fi
