#!/bin/bash
# Discovery script for HA components (HAProxy and Keepalived)
# Check control plane nodes (first 3)

CONTROL_NODES=(50 51 52)  # First 3 nodes will be control plane
VIP="192.168.0.200"
LOG_FILE="discovery-05.log"

echo "===================================" | tee $LOG_FILE
echo "HA Infrastructure Discovery" | tee -a $LOG_FILE
echo "Timestamp: $(date)" | tee -a $LOG_FILE
echo "Target VIP: $VIP" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Check VIP availability
echo "Checking VIP availability ($VIP)..." | tee -a $LOG_FILE
ping -c 1 -W 1 $VIP &>/dev/null
if [ $? -eq 0 ]; then
    echo "  ⚠ WARNING: VIP $VIP is already responding to ping!" | tee -a $LOG_FILE
    ARP_RESULT=$(arp -n | grep "$VIP" | awk '{print $3}')
    echo "  MAC Address: $ARP_RESULT" | tee -a $LOG_FILE
else
    echo "  ✓ VIP $VIP is available (not responding)" | tee -a $LOG_FILE
fi
echo "" | tee -a $LOG_FILE

# Check each control plane node
for node in "${CONTROL_NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    echo "Checking $NODE_NAME ($IP) - Control Plane Node..." | tee -a $LOG_FILE
    echo "----------------------------------------" | tee -a $LOG_FILE

    # Check for HAProxy
    HAPROXY_INSTALLED=$(ssh root@$IP "which haproxy 2>/dev/null || echo 'not installed'" 2>/dev/null)
    HAPROXY_SERVICE=$(ssh root@$IP "systemctl is-active haproxy 2>/dev/null || echo 'not found'" 2>/dev/null)
    echo "  HAProxy binary: $HAPROXY_INSTALLED" | tee -a $LOG_FILE
    echo "  HAProxy service: $HAPROXY_SERVICE" | tee -a $LOG_FILE

    # Check for Keepalived
    KEEPALIVED_INSTALLED=$(ssh root@$IP "which keepalived 2>/dev/null || echo 'not installed'" 2>/dev/null)
    KEEPALIVED_SERVICE=$(ssh root@$IP "systemctl is-active keepalived 2>/dev/null || echo 'not found'" 2>/dev/null)
    echo "  Keepalived binary: $KEEPALIVED_INSTALLED" | tee -a $LOG_FILE
    echo "  Keepalived service: $KEEPALIVED_SERVICE" | tee -a $LOG_FILE

    # Check network interfaces
    INTERFACES=$(ssh root@$IP "ip -br addr show | grep -E 'UP|UNKNOWN' | awk '{print \$1}' | tr '\n' ' '" 2>/dev/null)
    echo "  Active interfaces: $INTERFACES" | tee -a $LOG_FILE

    # Check if any VIP-related configuration exists
    VIP_CONFIG=$(ssh root@$IP "ip addr show | grep '$VIP' 2>/dev/null || echo 'VIP not configured'" 2>/dev/null)
    if [ "$VIP_CONFIG" != "VIP not configured" ]; then
        echo "  ⚠ VIP already configured: $VIP_CONFIG" | tee -a $LOG_FILE
    else
        echo "  VIP status: Not configured" | tee -a $LOG_FILE
    fi

    # Check firewall rules for HA ports
    HA_PORTS="6443 8443 2379 2380"
    echo "  Checking HA-related ports:" | tee -a $LOG_FILE
    for port in $HA_PORTS; do
        RULE_EXISTS=$(ssh root@$IP "iptables -L INPUT -n | grep -q $port && echo 'open' || echo 'not configured'" 2>/dev/null)
        echo "    Port $port: $RULE_EXISTS" | tee -a $LOG_FILE
    done

    # Check for existing config files
    echo "  Checking for existing configs:" | tee -a $LOG_FILE
    HAPROXY_CFG=$(ssh root@$IP "test -f /etc/haproxy/haproxy.cfg && echo 'exists' || echo 'not found'" 2>/dev/null)
    KEEPALIVED_CFG=$(ssh root@$IP "test -f /etc/keepalived/keepalived.conf && echo 'exists' || echo 'not found'" 2>/dev/null)
    echo "    /etc/haproxy/haproxy.cfg: $HAPROXY_CFG" | tee -a $LOG_FILE
    echo "    /etc/keepalived/keepalived.conf: $KEEPALIVED_CFG" | tee -a $LOG_FILE

    echo "" | tee -a $LOG_FILE
done

# Check worker nodes to ensure they don't have HA components
echo "Checking Worker Nodes (should not have HA components)..." | tee -a $LOG_FILE
echo "----------------------------------------" | tee -a $LOG_FILE
WORKER_NODES=(53 54 55 56 57 58)
for node in "${WORKER_NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    HAPROXY=$(ssh root@$IP "which haproxy 2>/dev/null || echo 'not installed'" 2>/dev/null)
    KEEPALIVED=$(ssh root@$IP "which keepalived 2>/dev/null || echo 'not installed'" 2>/dev/null)

    if [ "$HAPROXY" != "not installed" ] || [ "$KEEPALIVED" != "not installed" ]; then
        echo "  ⚠ $NODE_NAME: Unexpected HA components found" | tee -a $LOG_FILE
    else
        echo "  ✓ $NODE_NAME: Clean (no HA components)" | tee -a $LOG_FILE
    fi
done

echo "" | tee -a $LOG_FILE
echo "Discovery complete" | tee -a $LOG_FILE
