#!/bin/bash
# Fix bridge on .58 ONLY - careful approach with error checking
# Note: This is k8s09 where the VM is running

NODE="192.168.0.58"
PHYSICAL_IF="enx5c857e38630f"  # Different interface name on .58

echo "=== Fixing bridge on $NODE (k8s09 - VM host) ==="
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
    ip addr del 192.168.0.58/24 dev $PHYSICAL_IF
    ip addr add 192.168.0.58/24 dev br0

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
kubectl get node k8s09 | grep Ready

echo ""
echo "=== Checking VM status (should still be running) ==="
kubectl get vmi ubuntu-noble -o wide | grep -E "NAME|ubuntu"

echo ""
echo "=== Done with .58 ==="
