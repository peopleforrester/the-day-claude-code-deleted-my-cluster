#!/bin/bash
# Test network connectivity between all nodes

NODES=(50 51 52 53 54 55 56 57 58)
MATRIX_FILE="steps/01-connectivity/network-matrix.yaml"
LOG_FILE="steps/01-connectivity/discovery-01.log"

echo "" >> $LOG_FILE
echo "=== Network Connectivity Matrix ===" >> $LOG_FILE
echo "Timestamp: $(date)" >> $LOG_FILE
echo "" >> $LOG_FILE

# Create network matrix YAML
echo "# Network Connectivity Matrix" > $MATRIX_FILE
echo "# Generated: $(date)" >> $MATRIX_FILE
echo "network_test:" >> $MATRIX_FILE
echo "  timestamp: \"$(date -Iseconds)\"" >> $MATRIX_FILE
echo "  results:" >> $MATRIX_FILE

for source in "${NODES[@]}"; do
    SOURCE_IP="192.168.0.$source"
    SOURCE_NAME="k8s$(printf '%02d' $((source - 49)))"

    echo "Testing from $SOURCE_NAME ($SOURCE_IP)..." | tee -a $LOG_FILE
    echo "    $SOURCE_NAME:" >> $MATRIX_FILE
    echo "      source_ip: $SOURCE_IP" >> $MATRIX_FILE
    echo "      targets:" >> $MATRIX_FILE

    for target in "${NODES[@]}"; do
        if [ "$source" != "$target" ]; then
            TARGET_IP="192.168.0.$target"
            TARGET_NAME="k8s$(printf '%02d' $((target - 49)))"

            # Test ping from source to target
            PING_RESULT=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$SOURCE_IP \
                "ping -c 2 -W 1 $TARGET_IP >/dev/null 2>&1 && echo 'OK' || echo 'FAIL'" 2>/dev/null)

            # Get latency if ping successful
            if [ "$PING_RESULT" = "OK" ]; then
                LATENCY=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$SOURCE_IP \
                    "ping -c 4 -W 1 $TARGET_IP | tail -1 | awk -F '/' '{print \$5}'" 2>/dev/null)
                echo "        - target: $TARGET_NAME" >> $MATRIX_FILE
                echo "          ip: $TARGET_IP" >> $MATRIX_FILE
                echo "          status: connected" >> $MATRIX_FILE
                echo "          latency_ms: $LATENCY" >> $MATRIX_FILE
                echo "  ✓ $SOURCE_NAME -> $TARGET_NAME: OK (${LATENCY}ms)" | tee -a $LOG_FILE
            else
                echo "        - target: $TARGET_NAME" >> $MATRIX_FILE
                echo "          ip: $TARGET_IP" >> $MATRIX_FILE
                echo "          status: failed" >> $MATRIX_FILE
                echo "  ✗ $SOURCE_NAME -> $TARGET_NAME: FAILED" | tee -a $LOG_FILE
            fi
        fi
    done
done

echo "" >> $LOG_FILE
echo "Network matrix test complete" >> $LOG_FILE
