#!/bin/bash
# MAC Address Fix Script with Auto-Rollback
# Runs locally on node, survives SSH disconnect

# Log everything
exec 1> >(tee -a /var/log/mac-change.log)
exec 2>&1
echo "====================================="
echo "Starting MAC change at $(date)"
echo "====================================="

# Get node info
NODE_IP=$(hostname -I | awk '{print $1}')
NODE_OCTET=${NODE_IP##*.}
NEW_MAC="52:54:00:00:00:${NODE_OCTET}"
OLD_MAC=$(ip link show br0 | grep ether | awk '{print $2}')
HOSTNAME=$(hostname)

echo "Node: ${HOSTNAME} (${NODE_IP})"
echo "Current MAC: ${OLD_MAC}"
echo "New MAC: ${NEW_MAC}"

# Check if at is installed
if ! command -v at &> /dev/null; then
    echo "ERROR: 'at' command not found. Installing..."
    apt-get update && apt-get install -y at
    systemctl start atd
fi

# Save current network state
echo "Saving current network state..."
ip addr show > /tmp/network-before-${NODE_OCTET}.txt
ip route show > /tmp/routes-before-${NODE_OCTET}.txt
ip link show br0 > /tmp/br0-before-${NODE_OCTET}.txt

# Get the physical interface that's part of br0
PHYSICAL_IF=$(bridge link show master br0 2>/dev/null | head -1 | awk '{print $2}' | cut -d: -f1)
echo "Physical interface in bridge: ${PHYSICAL_IF}"

# Create rollback script
cat > /tmp/rollback-mac.sh << EOF
#!/bin/bash
echo "ROLLBACK: Starting at \$(date)" >> /var/log/mac-change.log
ip link set br0 down
ip link set br0 address ${OLD_MAC}
ip link set br0 up

# Ensure IP is still there
if ! ip addr show br0 | grep -q ${NODE_IP}; then
    ip addr add ${NODE_IP}/24 dev br0
fi

# Ensure default route
if ! ip route | grep -q default; then
    ip route add default via 192.168.0.1 dev br0
fi

echo "ROLLBACK: Completed - restored MAC to ${OLD_MAC}" >> /var/log/mac-change.log
EOF
chmod +x /tmp/rollback-mac.sh

# Schedule rollback in 2 minutes (will be cancelled if successful)
echo "Scheduling rollback in 2 minutes..."
echo "/tmp/rollback-mac.sh" | at now + 2 minutes 2>/dev/null
ROLLBACK_JOB=$(atq | tail -1 | awk '{print $1}')
echo "Rollback job ID: ${ROLLBACK_JOB}"

# Function to check connectivity
check_connectivity() {
    # Check gateway
    ping -c 2 -W 2 192.168.0.1 > /dev/null 2>&1
    return $?
}

echo "====================================="
echo "Applying new MAC address..."
echo "====================================="

# Apply new MAC - all in one command to minimize disruption
ip link set br0 down && \
ip link set br0 address ${NEW_MAC} && \
ip link set br0 up

# Give network time to settle
sleep 3

# Check if IP is still assigned
if ! ip addr show br0 | grep -q "${NODE_IP}/24"; then
    echo "WARNING: IP missing, re-adding..."
    ip addr add ${NODE_IP}/24 dev br0
fi

# Check if default route exists
if ! ip route | grep -q "default via 192.168.0.1"; then
    echo "WARNING: Default route missing, re-adding..."
    ip route add default via 192.168.0.1 dev br0
fi

# Give network time to fully stabilize
sleep 5

# Test connectivity
echo "Testing connectivity..."
if check_connectivity; then
    # Success - cancel rollback
    echo "SUCCESS: Connectivity verified, cancelling rollback..."
    atrm ${ROLLBACK_JOB} 2>/dev/null && echo "Rollback cancelled"

    # Verify new MAC is set
    CURRENT_MAC=$(ip link show br0 | grep ether | awk '{print $2}')
    echo "SUCCESS: MAC changed from ${OLD_MAC} to ${CURRENT_MAC}"

    # Show current state
    echo "Current network state:"
    ip addr show br0 | grep -E "inet |ether"

    # Clear ARP cache for clean start
    echo "Clearing ARP cache..."
    ip neigh flush all

    echo "====================================="
    echo "MAC change completed successfully at $(date)"
    echo "====================================="
    exit 0
else
    echo "FAILED: No connectivity, will auto-rollback in < 2 minutes"
    echo "====================================="
    echo "MAC change failed at $(date)"
    echo "====================================="
    exit 1
fi
