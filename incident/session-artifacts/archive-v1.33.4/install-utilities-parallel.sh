#!/bin/bash
# Install essential utilities in parallel on all nodes

NODES=(50 51 52 53 54 55 56 57 58)

# Essential packages - minimal set for speed
PACKAGES="iputils-ping netcat-openbsd dnsutils traceroute tcpdump net-tools iptables htop vim jq curl wget telnet nmap"

echo "Installing utilities in parallel on all nodes..."
echo "Started: $(date)"

# Function to install on a single node
install_node() {
    local ip="192.168.0.$1"
    local name="k8s$(printf '%02d' $(($1 - 49)))"

    echo "Starting $name ($ip)..."

    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$ip "
        apt-get update -qq && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $PACKAGES
    " 2>/dev/null && echo "✓ $name complete" || echo "✗ $name failed"
}

# Run installations in parallel
for node in "${NODES[@]}"; do
    install_node $node &
done

# Wait for all background jobs
echo "Waiting for all nodes to complete..."
wait

echo "Installation complete: $(date)"

# Quick test
echo ""
echo "Testing ping from k8s01 to k8s02:"
ssh root@192.168.0.50 "ping -c 2 192.168.0.51" 2>/dev/null && echo "✓ Network tools working"
