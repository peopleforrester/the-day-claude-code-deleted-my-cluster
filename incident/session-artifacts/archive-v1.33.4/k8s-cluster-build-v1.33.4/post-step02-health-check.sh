#!/bin/bash
# Post-Step 02 Health Check - Verify servers are still functional

NODES=(50 51 52 53 54 55 56 57 58)

echo "==================================="
echo "Post-Prerequisites Health Check"
echo "Started: $(date)"
echo "==================================="
echo ""

# 1. Check SSH connectivity
echo "1. SSH Connectivity Test:"
echo "-------------------------"
for node in "${NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    if ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "echo 'SSH OK'" &>/dev/null; then
        echo "  ✓ $NODE_NAME ($IP) - SSH working"
    else
        echo "  ✗ $NODE_NAME ($IP) - SSH FAILED"
    fi
done

# 2. Check network connectivity between nodes
echo ""
echo "2. Inter-node Network Connectivity:"
echo "-----------------------------------"
# Test from first and last node to others
for source in 50 58; do
    SOURCE_IP="192.168.0.$source"
    SOURCE_NAME="k8s$(printf '%02d' $((source - 49)))"
    echo "  From $SOURCE_NAME:"

    for target in 51 54 57; do
        TARGET_IP="192.168.0.$target"
        TARGET_NAME="k8s$(printf '%02d' $((target - 49)))"

        RESULT=$(ssh -o ConnectTimeout=3 root@$SOURCE_IP "ping -c 1 -W 1 $TARGET_IP &>/dev/null && echo 'OK' || echo 'FAIL'" 2>/dev/null)

        if [ "$RESULT" = "OK" ]; then
            LATENCY=$(ssh -o ConnectTimeout=3 root@$SOURCE_IP "ping -c 1 -W 1 $TARGET_IP | grep 'time=' | cut -d'=' -f4" 2>/dev/null)
            echo "    ✓ -> $TARGET_NAME: OK ($LATENCY)"
        else
            echo "    ✗ -> $TARGET_NAME: FAILED"
        fi
    done
done

# 3. Check system services
echo ""
echo "3. System Services Status:"
echo "-------------------------"
for node in 50 53 58; do  # Sample nodes
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"
    echo "  $NODE_NAME:"

    # Check critical services
    SSHD=$(ssh root@$IP "systemctl is-active sshd" 2>/dev/null)
    CHRONY=$(ssh root@$IP "systemctl is-active chrony" 2>/dev/null)
    NETWORK=$(ssh root@$IP "systemctl is-active systemd-networkd" 2>/dev/null)

    echo "    sshd: $SSHD | chrony: $CHRONY | network: $NETWORK"
done

# 4. Check system resources
echo ""
echo "4. System Resources:"
echo "-------------------"
for node in "${NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    # Get basic resource info
    LOAD=$(ssh root@$IP "uptime | awk -F'load average:' '{print \$2}'" 2>/dev/null | xargs)
    MEM_FREE=$(ssh root@$IP "free -m | grep '^Mem:' | awk '{print \$7}'" 2>/dev/null)
    DISK_FREE=$(ssh root@$IP "df -h / | tail -1 | awk '{print \$4}'" 2>/dev/null)

    echo "  $NODE_NAME: Load: $LOAD | Free Mem: ${MEM_FREE}MB | Free Disk: $DISK_FREE"
done

# 5. Check kernel modules still loaded
echo ""
echo "5. Kernel Modules Check:"
echo "-----------------------"
for node in 50 54 58; do  # Sample nodes
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    MODULES_OK=true
    for module in br_netfilter overlay ip_vs; do
        if ! ssh root@$IP "lsmod | grep -q ^$module" 2>/dev/null; then
            MODULES_OK=false
            break
        fi
    done

    if [ "$MODULES_OK" = "true" ]; then
        echo "  ✓ $NODE_NAME: All critical modules loaded"
    else
        echo "  ✗ $NODE_NAME: Some modules missing"
    fi
done

# 6. Check network configuration
echo ""
echo "6. Network Configuration:"
echo "------------------------"
for node in 50 54 58; do  # Sample nodes
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    IP_FORWARD=$(ssh root@$IP "sysctl -n net.ipv4.ip_forward" 2>/dev/null)
    DNS_REACH=$(ssh root@$IP "ping -c 1 -W 1 8.8.8.8 &>/dev/null && echo 'OK' || echo 'FAIL'" 2>/dev/null)

    echo "  $NODE_NAME: IP Forward: $IP_FORWARD | External DNS: $DNS_REACH"
done

# 7. Check for any system errors
echo ""
echo "7. System Errors (last 10 minutes):"
echo "-----------------------------------"
for node in 50 54 58; do  # Sample nodes
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    ERROR_COUNT=$(ssh root@$IP "journalctl --since '10 minutes ago' -p err --no-pager | wc -l" 2>/dev/null)

    if [ "$ERROR_COUNT" -gt "0" ]; then
        echo "  ⚠ $NODE_NAME: $ERROR_COUNT errors in system log"
        ssh root@$IP "journalctl --since '10 minutes ago' -p err --no-pager | head -3" 2>/dev/null | sed 's/^/    /'
    else
        echo "  ✓ $NODE_NAME: No recent errors"
    fi
done

# 8. Verify no swap
echo ""
echo "8. Swap Status:"
echo "--------------"
for node in "${NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    SWAP=$(ssh root@$IP "swapon --show | wc -l" 2>/dev/null)

    if [ "$SWAP" = "0" ]; then
        echo "  ✓ $NODE_NAME: Swap disabled"
    else
        echo "  ✗ $NODE_NAME: Swap ACTIVE (should be disabled)"
    fi
done

echo ""
echo "==================================="
echo "Health Check Complete"
echo "Finished: $(date)"
echo "==================================="
