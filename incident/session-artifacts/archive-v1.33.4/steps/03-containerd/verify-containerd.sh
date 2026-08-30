#!/bin/bash
# Verify containerd v2.1.4 installation and configuration

NODES=(50 51 52 53 54 55 56 57 58)
RESULTS_FILE="steps/03-containerd/verification-results.json"
LOG_FILE="steps/03-containerd/outputs-03.log"

echo "Verifying Containerd Installation" | tee $LOG_FILE
echo "Started: $(date)" | tee -a $LOG_FILE
echo "==================================" | tee -a $LOG_FILE

# Start JSON results file
echo "{" > $RESULTS_FILE
echo '  "verification_timestamp": "'$(date -Iseconds)'",' >> $RESULTS_FILE
echo '  "required_version": "2.1.4",' >> $RESULTS_FILE
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

    # Check containerd version
    VERSION=$(ssh root@$IP "containerd --version" 2>/dev/null | grep -o "v2.1.4" || echo "")
    if [ "$VERSION" = "v2.1.4" ]; then
        echo "  ✓ Containerd version: v2.1.4" | tee -a $LOG_FILE
        echo '      "version_correct": true,' >> $RESULTS_FILE
    else
        echo "  ✗ Containerd version mismatch" | tee -a $LOG_FILE
        echo '      "version_correct": false,' >> $RESULTS_FILE
        ALL_PASS=false
    fi

    # Check containerd service
    SERVICE_STATUS=$(ssh root@$IP "systemctl is-active containerd" 2>/dev/null)
    if [ "$SERVICE_STATUS" = "active" ]; then
        echo "  ✓ Containerd service: active" | tee -a $LOG_FILE
        echo '      "service_active": true,' >> $RESULTS_FILE
    else
        echo "  ✗ Containerd service: $SERVICE_STATUS" | tee -a $LOG_FILE
        echo '      "service_active": false,' >> $RESULTS_FILE
        ALL_PASS=false
    fi

    # Check systemd cgroup driver
    SYSTEMD_CGROUP=$(ssh root@$IP "grep 'SystemdCgroup = true' /etc/containerd/config.toml | wc -l" 2>/dev/null)
    if [ "$SYSTEMD_CGROUP" -ge "1" ]; then
        echo "  ✓ Systemd cgroup driver: configured" | tee -a $LOG_FILE
        echo '      "systemd_cgroup": true,' >> $RESULTS_FILE
    else
        echo "  ✗ Systemd cgroup driver: not configured" | tee -a $LOG_FILE
        echo '      "systemd_cgroup": false,' >> $RESULTS_FILE
        ALL_PASS=false
    fi

    # Check CRI socket
    SOCKET_EXISTS=$(ssh root@$IP "test -S /run/containerd/containerd.sock && echo 'true' || echo 'false'" 2>/dev/null)
    if [ "$SOCKET_EXISTS" = "true" ]; then
        echo "  ✓ CRI socket: exists" | tee -a $LOG_FILE
        echo '      "cri_socket": true,' >> $RESULTS_FILE
    else
        echo "  ✗ CRI socket: missing" | tee -a $LOG_FILE
        echo '      "cri_socket": false,' >> $RESULTS_FILE
        ALL_PASS=false
    fi

    # Check metrics endpoint
    METRICS_ENABLED=$(ssh root@$IP "grep 'address = \"127.0.0.1:1338\"' /etc/containerd/config.toml | wc -l" 2>/dev/null)
    if [ "$METRICS_ENABLED" -ge "1" ]; then
        echo "  ✓ Metrics endpoint: enabled" | tee -a $LOG_FILE
        echo '      "metrics_enabled": true,' >> $RESULTS_FILE
    else
        echo "  ⚠ Metrics endpoint: not enabled" | tee -a $LOG_FILE
        echo '      "metrics_enabled": false,' >> $RESULTS_FILE
    fi

    # Test crictl
    CRICTL_TEST=$(ssh root@$IP "crictl version 2>/dev/null | grep -q 'Runtime' && echo 'true' || echo 'false'" 2>/dev/null)
    if [ "$CRICTL_TEST" = "true" ]; then
        echo "  ✓ Crictl: working" | tee -a $LOG_FILE
        echo '      "crictl_working": true,' >> $RESULTS_FILE
    else
        echo "  ✗ Crictl: not working" | tee -a $LOG_FILE
        echo '      "crictl_working": false,' >> $RESULTS_FILE
        ALL_PASS=false
    fi

    # Check runc
    RUNC_EXISTS=$(ssh root@$IP "test -x /usr/local/sbin/runc && echo 'true' || echo 'false'" 2>/dev/null)
    if [ "$RUNC_EXISTS" = "true" ]; then
        echo "  ✓ Runc: installed" | tee -a $LOG_FILE
        echo '      "runc_installed": true,' >> $RESULTS_FILE
    else
        echo "  ✗ Runc: not found" | tee -a $LOG_FILE
        echo '      "runc_installed": false,' >> $RESULTS_FILE
        ALL_PASS=false
    fi

    # Check CNI plugins
    CNI_EXISTS=$(ssh root@$IP "test -d /opt/cni/bin && ls /opt/cni/bin | wc -l" 2>/dev/null)
    if [ "$CNI_EXISTS" -gt "0" ]; then
        echo "  ✓ CNI plugins: $CNI_EXISTS installed" | tee -a $LOG_FILE
        echo '      "cni_plugins": true' >> $RESULTS_FILE
    else
        echo "  ✗ CNI plugins: not found" | tee -a $LOG_FILE
        echo '      "cni_plugins": false' >> $RESULTS_FILE
        ALL_PASS=false
    fi

    echo "    }" >> $RESULTS_FILE
done

echo "" >> $RESULTS_FILE
echo "  }," >> $RESULTS_FILE
echo "  \"all_nodes_pass\": $ALL_PASS" >> $RESULTS_FILE
echo "}" >> $RESULTS_FILE

echo "" | tee -a $LOG_FILE
echo "==================================" | tee -a $LOG_FILE
if [ "$ALL_PASS" = "true" ]; then
    echo "✓ All nodes verified successfully!" | tee -a $LOG_FILE
else
    echo "✗ Some nodes failed verification" | tee -a $LOG_FILE
fi
echo "Finished: $(date)" | tee -a $LOG_FILE
