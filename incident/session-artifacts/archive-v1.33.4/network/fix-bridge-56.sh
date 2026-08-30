#!/bin/bash
# Fix bridge on .56 ONLY - careful approach with error checking

NODE="192.168.0.56"
PHYSICAL_IF="enp2s0"  # Different interface name on .56

echo "=== Fixing bridge on $NODE ==="
echo "=== Creating backup first ==="

# Create backup
ssh root@$NODE "
    echo 'Creating network backup...'
    ip addr show > /root/network-backup-before-bridge-$(date +%Y%m%d-%H%M%S).txt
    ip route show >> /root/network-backup-before-bridge-$(date +%Y%m%d-%H%M%S).txt
    echo 'Backup created'
"

echo ""
echo "=== Current state ==="
ssh root@$NODE "ip addr show $PHYSICAL_IF | grep inet"
ssh root@$NODE "ip addr show br0 | head -2"

echo ""
echo "=== Applying bridge configuration ==="

# Apply the fix
ssh root@$NODE "
    set -e  # Exit on error

    echo 'Adding physical interface to bridge...'
    ip link set $PHYSICAL_IF master br0

    echo 'Moving IP to bridge...'
    ip addr del 192.168.0.56/24 dev $PHYSICAL_IF
    ip addr add 192.168.0.56/24 dev br0

    echo 'Bringing bridge up...'
    ip link set br0 up
    ip link set $PHYSICAL_IF up

    echo 'Checking default route...'
    ip route | grep default || ip route add default via 192.168.0.1 dev br0

    echo 'Configuration complete'
"

echo ""
echo "=== Verifying configuration ==="
ssh root@$NODE "
    echo 'Bridge status:'
    ip addr show br0 | grep -E 'state|inet '
    echo ''
    echo 'Physical interface status:'
    ip addr show $PHYSICAL_IF | grep -E 'master|inet '
    echo ''
    echo 'Bridge ports:'
    bridge link show master br0
    echo ''
    echo 'Routing table:'
    ip route | grep default
"

echo ""
echo "=== Testing connectivity ==="
ssh root@$NODE "ping -c 2 192.168.0.1"
ssh root@$NODE "ping -c 2 8.8.8.8"

echo ""
echo "=== Checking node health ==="
kubectl get node k8s07 | grep Ready

echo ""
echo "=== Done with .56 ==="
