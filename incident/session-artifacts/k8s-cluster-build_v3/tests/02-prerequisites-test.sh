#!/bin/bash
# ABOUTME: Test script for verifying system prerequisites
# ABOUTME: Validates swap, kernel modules, and sysctl settings

set -e

echo "Running system prerequisites tests..."

NODES="192.168.0.100 192.168.0.101 192.168.0.102 192.168.0.103 192.168.0.104"
FAILURES=0

for node in $NODES; do
    echo "=== Testing $node ==="

    # Test swap is disabled
    echo -n "  - Swap status: "
    SWAP_STATUS=$(ssh root@$node "swapon --show" 2>/dev/null | wc -l)
    if [[ $SWAP_STATUS -eq 0 ]]; then
        echo "DISABLED ✓"
    else
        echo "STILL ACTIVE ✗"
        ((FAILURES++))
    fi

    # Test kernel modules
    echo -n "  - Kernel modules: "
    MODULES_OK=true
    for module in overlay br_netfilter; do
        if ! ssh root@$node "lsmod | grep -q $module" 2>/dev/null; then
            MODULES_OK=false
            break
        fi
    done
    if $MODULES_OK; then
        echo "LOADED ✓"
    else
        echo "MISSING ✗"
        ((FAILURES++))
    fi

    # Test sysctl settings
    echo -n "  - IP forwarding: "
    IP_FORWARD=$(ssh root@$node "sysctl -n net.ipv4.ip_forward" 2>/dev/null)
    if [[ "$IP_FORWARD" == "1" ]]; then
        echo "ENABLED ✓"
    else
        echo "DISABLED ✗"
        ((FAILURES++))
    fi

    echo -n "  - Bridge netfilter: "
    BRIDGE_NF=$(ssh root@$node "sysctl -n net.bridge.bridge-nf-call-iptables" 2>/dev/null)
    if [[ "$BRIDGE_NF" == "1" ]]; then
        echo "ENABLED ✓"
    else
        echo "DISABLED ✗"
        ((FAILURES++))
    fi

    echo
done

echo "========================================"
if [[ $FAILURES -eq 0 ]]; then
    echo "All prerequisites tests PASSED"
    exit 0
else
    echo "$FAILURES tests FAILED"
    exit 1
fi
