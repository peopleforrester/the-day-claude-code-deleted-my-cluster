#!/bin/bash
# Script to check SSH connectivity to all nodes

LOG_FILE="steps/01-connectivity/discovery-01.log"
NODES=(50 51 52 53 54 55 56 57 58)

echo "" >> $LOG_FILE
echo "=== SSH Connectivity Test ===" >> $LOG_FILE
echo "Timestamp: $(date)" >> $LOG_FILE
echo "" >> $LOG_FILE

for node in "${NODES[@]}"; do
    IP="192.168.0.$node"
    echo "Testing $IP..." | tee -a $LOG_FILE

    if ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o PasswordAuthentication=no root@$IP "hostname" 2>/dev/null; then
        echo "  ✓ SSH OK - hostname: $(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP hostname 2>/dev/null)" | tee -a $LOG_FILE
    else
        echo "  ✗ SSH FAILED" | tee -a $LOG_FILE
    fi
done

echo "" >> $LOG_FILE
echo "SSH connectivity test complete" >> $LOG_FILE
