#!/bin/bash
# Verify system prerequisites were applied correctly

NODES=(50 51 52 53 54 55 56 57 58)
RESULTS_FILE="steps/02-prerequisites/verification-results.json"
LOG_FILE="steps/02-prerequisites/outputs-02.log"

echo "Verifying System Prerequisites" | tee $LOG_FILE
echo "Started: $(date)" | tee -a $LOG_FILE
echo "==============================" | tee -a $LOG_FILE

# Start JSON results file
echo "{" > $RESULTS_FILE
echo '  "verification_timestamp": "'$(date -Iseconds)'",' >> $RESULTS_FILE
echo '  "nodes": {' >> $RESULTS_FILE

NODE_COUNT=0
ALL_PASS=true

for node in "${NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"
    NODE_COUNT=$((NODE_COUNT + 1))

    echo "" | tee -a $LOG_FILE
    echo "Verifying $NODE_NAME ($IP)..." | tee -a $LOG_FILE

    # Add comma if not first node
    if [ $NODE_COUNT -gt 1 ]; then
        echo "," >> $RESULTS_FILE
    fi

    echo "    \"$NODE_NAME\": {" >> $RESULTS_FILE

    # Check swap
    SWAP_STATUS=$(ssh root@$IP "swapon --show | wc -l" 2>/dev/null)
    if [ "$SWAP_STATUS" = "0" ]; then
        echo "  ✓ Swap disabled" | tee -a $LOG_FILE
        echo '      "swap_disabled": true,' >> $RESULTS_FILE
    else
        echo "  ✗ Swap still active" | tee -a $LOG_FILE
        echo '      "swap_disabled": false,' >> $RESULTS_FILE
        ALL_PASS=false
    fi

    # Check IP forwarding
    IP_FORWARD=$(ssh root@$IP "sysctl -n net.ipv4.ip_forward" 2>/dev/null)
    if [ "$IP_FORWARD" = "1" ]; then
        echo "  ✓ IP forwarding enabled" | tee -a $LOG_FILE
        echo '      "ip_forwarding": true,' >> $RESULTS_FILE
    else
        echo "  ✗ IP forwarding disabled" | tee -a $LOG_FILE
        echo '      "ip_forwarding": false,' >> $RESULTS_FILE
        ALL_PASS=false
    fi

    # Check kernel modules
    MODULES_OK=true
    echo '      "kernel_modules": {' >> $RESULTS_FILE
    for module in br_netfilter overlay ip_vs ip_vs_rr ip_vs_wrr ip_vs_sh; do
        if ssh root@$IP "lsmod | grep -q ^$module" 2>/dev/null; then
            echo '        "'$module'": true,' >> $RESULTS_FILE
        else
            echo '        "'$module'": false,' >> $RESULTS_FILE
            MODULES_OK=false
            ALL_PASS=false
        fi
    done
    echo '        "all_loaded": '$MODULES_OK >> $RESULTS_FILE
    echo '      },' >> $RESULTS_FILE

    if [ "$MODULES_OK" = "true" ]; then
        echo "  ✓ All kernel modules loaded" | tee -a $LOG_FILE
    else
        echo "  ✗ Some kernel modules missing" | tee -a $LOG_FILE
    fi

    # Check bridge netfilter
    BRIDGE_NF=$(ssh root@$IP "sysctl -n net.bridge.bridge-nf-call-iptables" 2>/dev/null)
    if [ "$BRIDGE_NF" = "1" ]; then
        echo "  ✓ Bridge netfilter enabled" | tee -a $LOG_FILE
        echo '      "bridge_netfilter": true,' >> $RESULTS_FILE
    else
        echo "  ✗ Bridge netfilter disabled" | tee -a $LOG_FILE
        echo '      "bridge_netfilter": false,' >> $RESULTS_FILE
        ALL_PASS=false
    fi

    # Check time sync
    TIME_SYNC=$(ssh root@$IP "timedatectl status | grep 'System clock synchronized: yes' | wc -l" 2>/dev/null)
    if [ "$TIME_SYNC" = "1" ]; then
        echo "  ✓ Time synchronized" | tee -a $LOG_FILE
        echo '      "time_sync": true,' >> $RESULTS_FILE
    else
        echo "  ✗ Time not synchronized" | tee -a $LOG_FILE
        echo '      "time_sync": false,' >> $RESULTS_FILE
        ALL_PASS=false
    fi

    # Check systemd cgroup
    CGROUP_OK=$(ssh root@$IP "systemctl show --property=DefaultCPUAccounting | grep -q yes && echo true || echo false" 2>/dev/null)
    if [ "$CGROUP_OK" = "true" ]; then
        echo "  ✓ Systemd cgroup accounting enabled" | tee -a $LOG_FILE
        echo '      "systemd_cgroup": true' >> $RESULTS_FILE
    else
        echo "  ✗ Systemd cgroup accounting disabled" | tee -a $LOG_FILE
        echo '      "systemd_cgroup": false' >> $RESULTS_FILE
        ALL_PASS=false
    fi

    echo "    }" >> $RESULTS_FILE
done

echo "" >> $RESULTS_FILE
echo "  }," >> $RESULTS_FILE
echo "  \"all_nodes_pass\": $ALL_PASS" >> $RESULTS_FILE
echo "}" >> $RESULTS_FILE

echo "" | tee -a $LOG_FILE
echo "==============================" | tee -a $LOG_FILE
if [ "$ALL_PASS" = "true" ]; then
    echo "✓ All prerequisites verified successfully!" | tee -a $LOG_FILE
else
    echo "✗ Some prerequisites failed verification" | tee -a $LOG_FILE
fi
echo "Finished: $(date)" | tee -a $LOG_FILE
