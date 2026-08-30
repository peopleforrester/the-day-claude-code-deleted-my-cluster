#!/bin/bash
# Gather comprehensive system information from all nodes

NODES=(50 51 52 53 54 55 56 57 58)
INVENTORY_FILE="steps/01-connectivity/inventory.json"
LOG_FILE="steps/01-connectivity/discovery-01.log"

echo "" >> $LOG_FILE
echo "=== System Information Gathering ===" >> $LOG_FILE
echo "Timestamp: $(date)" >> $LOG_FILE
echo "" >> $LOG_FILE

# Start JSON file
echo "{" > $INVENTORY_FILE
echo '  "cluster_name": "k8s-cluster",' >> $INVENTORY_FILE
echo '  "discovery_timestamp": "'$(date -Iseconds)'",' >> $INVENTORY_FILE
echo '  "nodes": {' >> $INVENTORY_FILE

NODE_COUNT=0
for node in "${NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_COUNT=$((NODE_COUNT + 1))

    echo "Gathering info from $IP..." | tee -a $LOG_FILE

    # Determine node name and role
    if [ $node -le 52 ]; then
        ROLE="control-plane"
    else
        ROLE="worker"
    fi
    HOSTNAME="k8s$(printf '%02d' $((node - 49)))"

    # Add comma for previous node if not first
    if [ $NODE_COUNT -gt 1 ]; then
        echo "," >> $INVENTORY_FILE
    fi

    echo "    \"$HOSTNAME\": {" >> $INVENTORY_FILE
    echo "      \"ip\": \"$IP\"," >> $INVENTORY_FILE
    echo "      \"role\": \"$ROLE\"," >> $INVENTORY_FILE

    # Gather system information
    OS_INFO=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"'" 2>/dev/null)
    KERNEL=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "uname -r" 2>/dev/null)
    CPU_MODEL=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "lscpu | grep 'Model name' | cut -d: -f2 | xargs" 2>/dev/null)
    CPU_CORES=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "nproc" 2>/dev/null)
    MEMORY_MB=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "free -m | grep '^Mem:' | awk '{print \$2}'" 2>/dev/null)
    DISK_GB=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "df -BG / | tail -1 | awk '{print \$2}' | tr -d 'G'" 2>/dev/null)
    DISK_AVAIL_GB=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "df -BG / | tail -1 | awk '{print \$4}' | tr -d 'G'" 2>/dev/null)
    SWAP_MB=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "free -m | grep '^Swap:' | awk '{print \$2}'" 2>/dev/null)
    CGROUP_VERSION=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "stat -fc %T /sys/fs/cgroup/ 2>/dev/null | grep -q cgroup2 && echo 'v2' || echo 'v1'" 2>/dev/null)
    IP_FORWARD=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "sysctl -n net.ipv4.ip_forward 2>/dev/null" 2>/dev/null)

    # Network interfaces
    INTERFACES=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "ip -o link show | grep -v 'lo:' | awk '{print \$2}' | tr -d ':' | head -3 | paste -sd ',' -" 2>/dev/null)

    echo "      \"os\": \"$OS_INFO\"," >> $INVENTORY_FILE
    echo "      \"kernel\": \"$KERNEL\"," >> $INVENTORY_FILE
    echo "      \"cpu\": {" >> $INVENTORY_FILE
    echo "        \"model\": \"$CPU_MODEL\"," >> $INVENTORY_FILE
    echo "        \"cores\": $CPU_CORES" >> $INVENTORY_FILE
    echo "      }," >> $INVENTORY_FILE
    echo "      \"memory_mb\": $MEMORY_MB," >> $INVENTORY_FILE
    echo "      \"disk\": {" >> $INVENTORY_FILE
    echo "        \"total_gb\": $DISK_GB," >> $INVENTORY_FILE
    echo "        \"available_gb\": $DISK_AVAIL_GB" >> $INVENTORY_FILE
    echo "      }," >> $INVENTORY_FILE
    echo "      \"swap_mb\": $SWAP_MB," >> $INVENTORY_FILE
    echo "      \"cgroup_version\": \"$CGROUP_VERSION\"," >> $INVENTORY_FILE
    echo "      \"ip_forwarding\": \"$IP_FORWARD\"," >> $INVENTORY_FILE
    echo "      \"network_interfaces\": \"$INTERFACES\"" >> $INVENTORY_FILE
    echo "    }" >> $INVENTORY_FILE

    echo "  ✓ Gathered info for $HOSTNAME" | tee -a $LOG_FILE
done

echo "" >> $INVENTORY_FILE
echo "  }" >> $INVENTORY_FILE
echo "}" >> $INVENTORY_FILE

echo "" >> $LOG_FILE
echo "System information gathering complete" >> $LOG_FILE
echo "Inventory saved to: inventory.json" >> $LOG_FILE
