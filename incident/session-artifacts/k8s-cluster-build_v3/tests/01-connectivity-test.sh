#!/bin/bash
# ABOUTME: Test script for verifying node connectivity
# ABOUTME: Validates SSH access and system requirements

set -e

echo "Running connectivity tests..."

NODES="192.168.0.100 192.168.0.101 192.168.0.102 192.168.0.103 192.168.0.104"
FAILURES=0

for node in $NODES; do
    echo -n "Testing $node... "

    # Test SSH connectivity
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$node "exit 0" 2>/dev/null; then
        echo -n "SSH OK, "
    else
        echo "SSH FAILED"
        ((FAILURES++))
        continue
    fi

    # Check OS version
    OS_VERSION=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$node "lsb_release -rs 2>/dev/null")
    if [[ "$OS_VERSION" == "24.04" ]]; then
        echo -n "OS OK, "
    else
        echo "OS MISMATCH (expected 24.04, got $OS_VERSION)"
        ((FAILURES++))
        continue
    fi

    # Check memory (minimum 2GB)
    MEM_GB=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$node "free -g | grep Mem | awk '{print \$2}'")
    if [[ $MEM_GB -ge 2 ]]; then
        echo "Memory OK (${MEM_GB}GB)"
    else
        echo "Memory INSUFFICIENT (${MEM_GB}GB < 2GB minimum)"
        ((FAILURES++))
    fi
done

echo "========================================"
if [[ $FAILURES -eq 0 ]]; then
    echo "All connectivity tests PASSED"
    exit 0
else
    echo "$FAILURES tests FAILED"
    exit 1
fi
