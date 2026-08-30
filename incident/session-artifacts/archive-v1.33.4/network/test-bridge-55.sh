#!/bin/bash
# CAREFUL bridge setup test for node .55 ONLY
# This script will backup current config before making changes

NODE="192.168.0.55"
PHYSICAL_IF="enx000000000f8d"

echo "=== Testing bridge setup on $NODE ONLY ==="
echo "=== This will backup current config first ==="

# First, backup current network config
ssh root@$NODE "ip addr show > /root/network-backup-$(date +%Y%m%d-%H%M%S).txt"
ssh root@$NODE "ip route show >> /root/network-backup-$(date +%Y%m%d-%H%M%S).txt"

echo "Current state:"
ssh root@$NODE "ip addr show $PHYSICAL_IF | grep inet"
ssh root@$NODE "ip addr show br0 2>/dev/null | grep -E 'state|inet' || echo 'br0 not configured'"

echo ""
echo "To setup bridge on $NODE, we would need to:"
echo "1. Add $PHYSICAL_IF to br0"
echo "2. Move IP from $PHYSICAL_IF to br0"
echo "3. Ensure routing still works"
echo ""
echo "Commands that would be run:"
echo "  brctl addif br0 $PHYSICAL_IF"
echo "  ip addr del 192.168.0.55/24 dev $PHYSICAL_IF"
echo "  ip addr add 192.168.0.55/24 dev br0"
echo "  ip link set br0 up"
echo "  ip route add default via 192.168.0.1 dev br0 (if needed)"
echo ""
echo "Do you want to proceed? (Type YES to continue)"
