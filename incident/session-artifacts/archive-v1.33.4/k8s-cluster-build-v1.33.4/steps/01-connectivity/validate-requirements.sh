#!/bin/bash
# Validate system requirements and create comprehensive test results

LOG_FILE="steps/01-connectivity/discovery-01.log"
REQUIREMENTS_FILE="steps/01-connectivity/system-requirements-check.json"
CGROUP_FILE="steps/01-connectivity/cgroup-status.json"
NODES=(50 51 52 53 54 55 56 57 58)

echo "" >> $LOG_FILE
echo "=== System Requirements Validation ===" >> $LOG_FILE
echo "Timestamp: $(date)" >> $LOG_FILE
echo "" >> $LOG_FILE

# Create requirements check JSON
echo "{" > $REQUIREMENTS_FILE
echo '  "validation_timestamp": "'$(date -Iseconds)'",' >> $REQUIREMENTS_FILE
echo '  "requirements": {' >> $REQUIREMENTS_FILE
echo '    "minimum": {' >> $REQUIREMENTS_FILE
echo '      "control_plane_memory_mb": 4096,' >> $REQUIREMENTS_FILE
echo '      "worker_memory_mb": 2048,' >> $REQUIREMENTS_FILE
echo '      "disk_gb": 20,' >> $REQUIREMENTS_FILE
echo '      "cpu_cores": 2,' >> $REQUIREMENTS_FILE
echo '      "kernel_version": "3.10",' >> $REQUIREMENTS_FILE
echo '      "network_latency_ms": 1' >> $REQUIREMENTS_FILE
echo '    }' >> $REQUIREMENTS_FILE
echo '  },' >> $REQUIREMENTS_FILE
echo '  "validation_results": {' >> $REQUIREMENTS_FILE

# Create cgroup status JSON
echo "{" > $CGROUP_FILE
echo '  "check_timestamp": "'$(date -Iseconds)'",' >> $CGROUP_FILE
echo '  "nodes": {' >> $CGROUP_FILE

NODE_COUNT=0
ALL_PASS=true

for node in "${NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"
    NODE_COUNT=$((NODE_COUNT + 1))

    echo "Validating $NODE_NAME ($IP)..." | tee -a $LOG_FILE

    # Get node info for validation
    if [ $node -le 52 ]; then
        ROLE="control-plane"
        MIN_MEM=4096
    else
        ROLE="worker"
        MIN_MEM=2048
    fi

    # Add comma if not first node
    if [ $NODE_COUNT -gt 1 ]; then
        echo "," >> $REQUIREMENTS_FILE
        echo "," >> $CGROUP_FILE
    fi

    # Get system values
    MEMORY_MB=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "free -m | grep '^Mem:' | awk '{print \$2}'" 2>/dev/null)
    CPU_CORES=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "nproc" 2>/dev/null)
    DISK_AVAIL=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "df -BG / | tail -1 | awk '{print \$4}' | tr -d 'G'" 2>/dev/null)
    KERNEL=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "uname -r" 2>/dev/null)
    SWAP_STATUS=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "swapon -s | wc -l" 2>/dev/null)

    # DNS resolution test
    DNS_TEST=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "nslookup google.com >/dev/null 2>&1 && echo 'OK' || echo 'FAIL'" 2>/dev/null)

    # Cgroup detailed check
    CGROUP_TYPE=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "stat -fc %T /sys/fs/cgroup/" 2>/dev/null)
    CGROUP_CONTROLLERS=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "cat /sys/fs/cgroup/cgroup.controllers 2>/dev/null || echo 'none'" 2>/dev/null)
    SYSTEMD_CGROUP=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@$IP "systemctl show --property=DefaultCPUAccounting,DefaultMemoryAccounting,DefaultTasksAccounting | grep -q '=yes' && echo 'enabled' || echo 'disabled'" 2>/dev/null)

    # Validate requirements
    MEM_PASS="false"
    CPU_PASS="false"
    DISK_PASS="false"

    if [ "$MEMORY_MB" -ge "$MIN_MEM" ]; then MEM_PASS="true"; fi
    if [ "$CPU_CORES" -ge "2" ]; then CPU_PASS="true"; fi
    if [ "$DISK_AVAIL" -ge "20" ]; then DISK_PASS="true"; fi

    if [ "$MEM_PASS" = "false" ] || [ "$CPU_PASS" = "false" ] || [ "$DISK_PASS" = "false" ]; then
        ALL_PASS=false
    fi

    # Write requirements validation
    echo "    \"$NODE_NAME\": {" >> $REQUIREMENTS_FILE
    echo "      \"role\": \"$ROLE\"," >> $REQUIREMENTS_FILE
    echo "      \"checks\": {" >> $REQUIREMENTS_FILE
    echo "        \"memory\": {" >> $REQUIREMENTS_FILE
    echo "          \"required_mb\": $MIN_MEM," >> $REQUIREMENTS_FILE
    echo "          \"actual_mb\": $MEMORY_MB," >> $REQUIREMENTS_FILE
    echo "          \"pass\": $MEM_PASS" >> $REQUIREMENTS_FILE
    echo "        }," >> $REQUIREMENTS_FILE
    echo "        \"cpu\": {" >> $REQUIREMENTS_FILE
    echo "          \"required_cores\": 2," >> $REQUIREMENTS_FILE
    echo "          \"actual_cores\": $CPU_CORES," >> $REQUIREMENTS_FILE
    echo "          \"pass\": $CPU_PASS" >> $REQUIREMENTS_FILE
    echo "        }," >> $REQUIREMENTS_FILE
    echo "        \"disk\": {" >> $REQUIREMENTS_FILE
    echo "          \"required_gb\": 20," >> $REQUIREMENTS_FILE
    echo "          \"available_gb\": $DISK_AVAIL," >> $REQUIREMENTS_FILE
    echo "          \"pass\": $DISK_PASS" >> $REQUIREMENTS_FILE
    echo "        }," >> $REQUIREMENTS_FILE
    echo "        \"kernel\": \"$KERNEL\"," >> $REQUIREMENTS_FILE
    echo "        \"swap_lines\": $SWAP_STATUS," >> $REQUIREMENTS_FILE
    echo "        \"dns_resolution\": \"$DNS_TEST\"" >> $REQUIREMENTS_FILE
    echo "      }" >> $REQUIREMENTS_FILE
    echo "    }" >> $REQUIREMENTS_FILE

    # Write cgroup status
    echo "    \"$NODE_NAME\": {" >> $CGROUP_FILE
    echo "      \"filesystem_type\": \"$CGROUP_TYPE\"," >> $CGROUP_FILE
    echo "      \"version\": \"$([ "$CGROUP_TYPE" = "cgroup2fs" ] && echo "v2" || echo "v1")\"," >> $CGROUP_FILE
    echo "      \"controllers\": \"$CGROUP_CONTROLLERS\"," >> $CGROUP_FILE
    echo "      \"systemd_cgroup_driver\": \"$SYSTEMD_CGROUP\"" >> $CGROUP_FILE
    echo "    }" >> $CGROUP_FILE

    echo "  ✓ Validated $NODE_NAME" | tee -a $LOG_FILE
done

echo "" >> $REQUIREMENTS_FILE
echo "  }," >> $REQUIREMENTS_FILE
echo "  \"overall_pass\": $ALL_PASS" >> $REQUIREMENTS_FILE
echo "}" >> $REQUIREMENTS_FILE

echo "" >> $CGROUP_FILE
echo "  }" >> $CGROUP_FILE
echo "}" >> $CGROUP_FILE

echo "" >> $LOG_FILE
echo "Requirements validation complete" >> $LOG_FILE
echo "Overall pass: $ALL_PASS" >> $LOG_FILE
