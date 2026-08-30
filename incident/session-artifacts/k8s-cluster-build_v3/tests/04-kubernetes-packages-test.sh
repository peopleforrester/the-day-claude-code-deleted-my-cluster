#!/bin/bash
# ABOUTME: Test script for verifying Kubernetes packages installation
# ABOUTME: Validates versions, binaries, and package holds

set -e

echo "Running Kubernetes packages tests..."

NODES="192.168.0.100 192.168.0.101 192.168.0.102 192.168.0.103 192.168.0.104"
EXPECTED_VERSION="v1.31.11"
FAILURES=0

for node in $NODES; do
    echo "=== Testing $node ==="

    # Test kubeadm version
    echo -n "  - Kubeadm version: "
    VERSION=$(ssh root@$node "kubeadm version -o short" 2>/dev/null || echo "NOT FOUND")
    if [[ "$VERSION" == "$EXPECTED_VERSION" ]]; then
        echo "$VERSION ✓"
    else
        echo "$VERSION ✗ (expected $EXPECTED_VERSION)"
        ((FAILURES++))
    fi

    # Test kubectl version
    echo -n "  - Kubectl client: "
    if ssh root@$node "kubectl version --client -o yaml" >/dev/null 2>&1; then
        echo "WORKING ✓"
    else
        echo "NOT WORKING ✗"
        ((FAILURES++))
    fi

    # Test kubelet is enabled
    echo -n "  - Kubelet enabled: "
    if ssh root@$node "systemctl is-enabled kubelet" >/dev/null 2>&1; then
        echo "ENABLED ✓"
    else
        echo "DISABLED ✗"
        ((FAILURES++))
    fi

    # Test packages are held
    echo -n "  - Package holds: "
    HOLDS=$(ssh root@$node "apt-mark showhold | grep -E 'kubeadm|kubelet|kubectl' | wc -l" 2>/dev/null)
    if [[ $HOLDS -eq 3 ]]; then
        echo "CONFIGURED ✓"
    else
        echo "NOT CONFIGURED ✗ ($HOLDS/3 packages held)"
        ((FAILURES++))
    fi

    # Test crictl command
    echo -n "  - Crictl command: "
    if ssh root@$node "crictl --version" >/dev/null 2>&1; then
        echo "WORKING ✓"
    else
        echo "NOT WORKING ✗"
        ((FAILURES++))
    fi

    echo
done

echo "========================================"
if [[ $FAILURES -eq 0 ]]; then
    echo "All Kubernetes packages tests PASSED"
    exit 0
else
    echo "$FAILURES tests FAILED"
    exit 1
fi
