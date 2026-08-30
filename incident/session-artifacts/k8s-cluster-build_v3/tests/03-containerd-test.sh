#!/bin/bash
# ABOUTME: Test script for verifying containerd installation
# ABOUTME: Validates service status, configuration, and functionality

set -e

echo "Running containerd tests..."

NODES="192.168.0.100 192.168.0.101 192.168.0.102 192.168.0.103 192.168.0.104"
FAILURES=0

for node in $NODES; do
    echo "=== Testing $node ==="

    # Test containerd service is running
    echo -n "  - Containerd service: "
    if ssh root@$node "systemctl is-active containerd" >/dev/null 2>&1; then
        echo "ACTIVE ✓"
    else
        echo "INACTIVE ✗"
        ((FAILURES++))
    fi

    # Test containerd is enabled
    echo -n "  - Containerd enabled: "
    if ssh root@$node "systemctl is-enabled containerd" >/dev/null 2>&1; then
        echo "ENABLED ✓"
    else
        echo "DISABLED ✗"
        ((FAILURES++))
    fi

    # Test systemd cgroup configuration
    echo -n "  - SystemdCgroup setting: "
    SYSTEMD_CGROUP=$(ssh root@$node "grep 'SystemdCgroup = true' /etc/containerd/config.toml" 2>/dev/null | wc -l)
    if [[ $SYSTEMD_CGROUP -gt 0 ]]; then
        echo "CONFIGURED ✓"
    else
        echo "NOT CONFIGURED ✗"
        ((FAILURES++))
    fi

    # Test containerd version
    echo -n "  - Containerd version: "
    if VERSION=$(ssh root@$node "containerd --version" 2>/dev/null); then
        echo "$VERSION ✓"
    else
        echo "UNABLE TO GET VERSION ✗"
        ((FAILURES++))
    fi

    # Test ctr command
    echo -n "  - CTR command: "
    if ssh root@$node "ctr version" >/dev/null 2>&1; then
        echo "WORKING ✓"
    else
        echo "NOT WORKING ✗"
        ((FAILURES++))
    fi

    echo
done

echo "========================================"
if [[ $FAILURES -eq 0 ]]; then
    echo "All containerd tests PASSED"
    exit 0
else
    echo "$FAILURES tests FAILED"
    exit 1
fi
