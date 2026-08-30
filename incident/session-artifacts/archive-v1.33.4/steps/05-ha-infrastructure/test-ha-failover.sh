#!/bin/bash
# Test HA failover functionality

CONTROL_NODES=(50 51 52)
VIP="192.168.0.200"
LOG_FILE="steps/05-ha-infrastructure/failover-test.log"

echo "===================================" | tee $LOG_FILE
echo "HA Failover Test" | tee -a $LOG_FILE
echo "Timestamp: $(date)" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Function to check which node has the VIP
check_vip_holder() {
    for node in "${CONTROL_NODES[@]}"; do
        IP="192.168.0.$node"
        NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

        HAS_VIP=$(ssh root@$IP "ip addr show | grep -q '$VIP' && echo 'yes' || echo 'no'" 2>/dev/null)
        if [ "$HAS_VIP" = "yes" ]; then
            echo "$NODE_NAME"
            return
        fi
    done
    echo "NONE"
}

# Initial state
echo "1. INITIAL STATE:" | tee -a $LOG_FILE
echo "-------------------" | tee -a $LOG_FILE
INITIAL_HOLDER=$(check_vip_holder)
echo "  VIP holder: $INITIAL_HOLDER" | tee -a $LOG_FILE

# Check HAProxy stats are accessible
echo "  Testing HAProxy stats pages:" | tee -a $LOG_FILE
for node in "${CONTROL_NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u admin:admin123 http://$IP:8080/stats 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ]; then
        echo "    ✓ $NODE_NAME ($IP:8080): Accessible" | tee -a $LOG_FILE
    else
        echo "    ✗ $NODE_NAME ($IP:8080): Not accessible (HTTP $HTTP_CODE)" | tee -a $LOG_FILE
    fi
done

# Test load balancer port through VIP
echo "" | tee -a $LOG_FILE
echo "2. VIP CONNECTIVITY TEST:" | tee -a $LOG_FILE
echo "-------------------------" | tee -a $LOG_FILE
nc -zv $VIP 8443 &>/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  ✓ Port 8443 on VIP is accessible" | tee -a $LOG_FILE
else
    echo "  ✗ Port 8443 on VIP is not accessible" | tee -a $LOG_FILE
fi

# Failover test
echo "" | tee -a $LOG_FILE
echo "3. FAILOVER TEST:" | tee -a $LOG_FILE
echo "-----------------" | tee -a $LOG_FILE

if [ "$INITIAL_HOLDER" != "NONE" ]; then
    # Get IP of current VIP holder
    case $INITIAL_HOLDER in
        k8s01) HOLDER_IP="192.168.0.50" ;;
        k8s02) HOLDER_IP="192.168.0.51" ;;
        k8s03) HOLDER_IP="192.168.0.52" ;;
    esac

    echo "  Stopping keepalived on $INITIAL_HOLDER to trigger failover..." | tee -a $LOG_FILE
    ssh root@$HOLDER_IP "systemctl stop keepalived" 2>/dev/null

    echo "  Waiting for failover (10 seconds)..." | tee -a $LOG_FILE
    sleep 10

    NEW_HOLDER=$(check_vip_holder)
    echo "  New VIP holder: $NEW_HOLDER" | tee -a $LOG_FILE

    if [ "$NEW_HOLDER" != "NONE" ] && [ "$NEW_HOLDER" != "$INITIAL_HOLDER" ]; then
        echo "  ✓ Failover successful: $INITIAL_HOLDER -> $NEW_HOLDER" | tee -a $LOG_FILE

        # Test connectivity after failover
        ping -c 2 -W 1 $VIP &>/dev/null
        if [ $? -eq 0 ]; then
            echo "  ✓ VIP still responding after failover" | tee -a $LOG_FILE
        else
            echo "  ✗ VIP not responding after failover" | tee -a $LOG_FILE
        fi
    else
        echo "  ✗ Failover failed" | tee -a $LOG_FILE
    fi

    # Restore service
    echo "" | tee -a $LOG_FILE
    echo "4. RESTORE ORIGINAL STATE:" | tee -a $LOG_FILE
    echo "--------------------------" | tee -a $LOG_FILE
    echo "  Starting keepalived on $INITIAL_HOLDER..." | tee -a $LOG_FILE
    ssh root@$HOLDER_IP "systemctl start keepalived" 2>/dev/null

    echo "  Waiting for restoration (10 seconds)..." | tee -a $LOG_FILE
    sleep 10

    RESTORED_HOLDER=$(check_vip_holder)
    echo "  VIP holder after restoration: $RESTORED_HOLDER" | tee -a $LOG_FILE

    if [ "$RESTORED_HOLDER" = "$INITIAL_HOLDER" ]; then
        echo "  ✓ VIP returned to original master ($INITIAL_HOLDER)" | tee -a $LOG_FILE
    else
        echo "  ℹ VIP remained on $RESTORED_HOLDER (normal if equal priority)" | tee -a $LOG_FILE
    fi
else
    echo "  ✗ No VIP holder found - cannot test failover" | tee -a $LOG_FILE
fi

# Final verification
echo "" | tee -a $LOG_FILE
echo "5. FINAL VERIFICATION:" | tee -a $LOG_FILE
echo "----------------------" | tee -a $LOG_FILE

# Check all services
for node in "${CONTROL_NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    HAPROXY=$(ssh root@$IP "systemctl is-active haproxy" 2>/dev/null)
    KEEPALIVED=$(ssh root@$IP "systemctl is-active keepalived" 2>/dev/null)

    echo "  $NODE_NAME:" | tee -a $LOG_FILE
    echo "    HAProxy: $HAPROXY" | tee -a $LOG_FILE
    echo "    Keepalived: $KEEPALIVED" | tee -a $LOG_FILE
done

FINAL_HOLDER=$(check_vip_holder)
echo "" | tee -a $LOG_FILE
echo "  Final VIP holder: $FINAL_HOLDER" | tee -a $LOG_FILE

# Summary
echo "" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE
echo "Failover Test Complete" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE
