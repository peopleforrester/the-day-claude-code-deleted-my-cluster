#!/bin/bash
# Check for existing container runtimes on all nodes

NODES=(50 51 52 53 54 55 56 57 58)
LOG_FILE="steps/03-containerd/discovery-03.log"

echo "" >> $LOG_FILE
echo "=== Container Runtime Discovery ===" >> $LOG_FILE
echo "Timestamp: $(date)" >> $LOG_FILE
echo "" >> $LOG_FILE

for node in "${NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    echo "Checking $NODE_NAME ($IP)..." | tee -a $LOG_FILE

    # Check for Docker
    DOCKER_VERSION=$(ssh root@$IP "docker --version 2>/dev/null || echo 'not installed'" 2>/dev/null)
    echo "  Docker: $DOCKER_VERSION" >> $LOG_FILE

    # Check for containerd
    CONTAINERD_VERSION=$(ssh root@$IP "containerd --version 2>/dev/null || echo 'not installed'" 2>/dev/null)
    echo "  Containerd: $CONTAINERD_VERSION" >> $LOG_FILE

    # Check for CRI-O
    CRIO_VERSION=$(ssh root@$IP "crio --version 2>/dev/null || echo 'not installed'" 2>/dev/null)
    echo "  CRI-O: $CRIO_VERSION" >> $LOG_FILE

    # Check for existing containerd service
    CONTAINERD_SERVICE=$(ssh root@$IP "systemctl is-active containerd 2>/dev/null || echo 'not found'" 2>/dev/null)
    echo "  Containerd service: $CONTAINERD_SERVICE" >> $LOG_FILE

    echo "" >> $LOG_FILE
done

# Check for containerd v2.1.4 availability
echo "Checking containerd v2.1.4 availability..." | tee -a $LOG_FILE
echo "" >> $LOG_FILE

# Check GitHub releases
echo "GitHub releases for containerd v2.1.4:" >> $LOG_FILE
curl -s https://api.github.com/repos/containerd/containerd/releases | grep -A 3 '"tag_name": "v2.1.4"' >> $LOG_FILE 2>&1 || echo "Not found in releases" >> $LOG_FILE

echo "" >> $LOG_FILE
echo "Discovery complete" >> $LOG_FILE
