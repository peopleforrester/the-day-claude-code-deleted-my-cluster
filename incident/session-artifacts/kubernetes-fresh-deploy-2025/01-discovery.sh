#!/bin/bash
# ABOUTME: Discovery script to check current state of all nodes
# ABOUTME: Documents everything for fresh cluster deployment

set -euo pipefail

LOG_DIR="logs/01-discovery"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DISCOVERY_LOG="$LOG_DIR/discovery-$TIMESTAMP.log"
STATE_FILE="$LOG_DIR/state-$TIMESTAMP.json"

# Nodes to check
CONTROL_NODES=("192.168.0.50" "192.168.0.51" "192.168.0.52")
WORKER_NODES=("192.168.0.53" "192.168.0.54" "192.168.0.55" "192.168.0.56" "192.168.0.57" "192.168.0.58")
ALL_NODES=("${CONTROL_NODES[@]}" "${WORKER_NODES[@]}")

echo "Starting discovery at $TIMESTAMP" | tee "$DISCOVERY_LOG"
echo "================================================" | tee -a "$DISCOVERY_LOG"

# Function to check node
check_node() {
    local ip=$1
    local name=$2
    echo "" | tee -a "$DISCOVERY_LOG"
    echo "Checking $name ($ip)..." | tee -a "$DISCOVERY_LOG"
    echo "------------------------" | tee -a "$DISCOVERY_LOG"
    
    # Check connectivity
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        echo "✓ Reachable" | tee -a "$DISCOVERY_LOG"
        
        # Check SSH
        if ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no root@"$ip" "echo 'SSH OK'" >/dev/null 2>&1; then
            echo "✓ SSH accessible" | tee -a "$DISCOVERY_LOG"
            
            # Get system info
            echo "System Info:" | tee -a "$DISCOVERY_LOG"
            ssh -o ConnectTimeout=2 root@"$ip" "hostname" 2>/dev/null | tee -a "$DISCOVERY_LOG"
            ssh -o ConnectTimeout=2 root@"$ip" "lsb_release -d 2>/dev/null | cut -f2" 2>/dev/null | tee -a "$DISCOVERY_LOG"
            ssh -o ConnectTimeout=2 root@"$ip" "uname -r" 2>/dev/null | tee -a "$DISCOVERY_LOG"
            
            # Check for existing Kubernetes
            echo "Kubernetes Status:" | tee -a "$DISCOVERY_LOG"
            if ssh -o ConnectTimeout=2 root@"$ip" "which kubeadm" >/dev/null 2>&1; then
                echo "  kubeadm: $(ssh root@$ip 'kubeadm version -o short' 2>/dev/null)" | tee -a "$DISCOVERY_LOG"
            else
                echo "  kubeadm: not installed" | tee -a "$DISCOVERY_LOG"
            fi
            
            if ssh -o ConnectTimeout=2 root@"$ip" "which kubelet" >/dev/null 2>&1; then
                echo "  kubelet: $(ssh root@$ip 'kubelet --version' 2>/dev/null)" | tee -a "$DISCOVERY_LOG"
            else
                echo "  kubelet: not installed" | tee -a "$DISCOVERY_LOG"
            fi
            
            # Check containerd
            echo "Container Runtime:" | tee -a "$DISCOVERY_LOG"
            if ssh -o ConnectTimeout=2 root@"$ip" "which containerd" >/dev/null 2>&1; then
                echo "  containerd: $(ssh root@$ip 'containerd --version' 2>/dev/null)" | tee -a "$DISCOVERY_LOG"
            else
                echo "  containerd: not installed" | tee -a "$DISCOVERY_LOG"
            fi
            
            # Check for running containers
            if ssh -o ConnectTimeout=2 root@"$ip" "which crictl" >/dev/null 2>&1; then
                local containers=$(ssh root@"$ip" "crictl ps 2>/dev/null | wc -l" 2>/dev/null)
                echo "  Running containers: $((containers-1))" | tee -a "$DISCOVERY_LOG"
            fi
            
        else
            echo "✗ SSH not accessible" | tee -a "$DISCOVERY_LOG"
        fi
    else
        echo "✗ Not reachable" | tee -a "$DISCOVERY_LOG"
    fi
}

# Check control plane nodes
echo "" | tee -a "$DISCOVERY_LOG"
echo "CONTROL PLANE NODES" | tee -a "$DISCOVERY_LOG"
echo "===================" | tee -a "$DISCOVERY_LOG"
for i in "${!CONTROL_NODES[@]}"; do
    check_node "${CONTROL_NODES[$i]}" "k8s0$((i+1))"
done

# Check worker nodes
echo "" | tee -a "$DISCOVERY_LOG"
echo "WORKER NODES" | tee -a "$DISCOVERY_LOG"
echo "============" | tee -a "$DISCOVERY_LOG"
for i in "${!WORKER_NODES[@]}"; do
    check_node "${WORKER_NODES[$i]}" "k8s0$((i+4))"
done

# Create state JSON
echo "" | tee -a "$DISCOVERY_LOG"
echo "Creating state file..." | tee -a "$DISCOVERY_LOG"

cat > "$STATE_FILE" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "control_plane": [
    {"ip": "192.168.0.50", "name": "k8s01", "role": "control-plane"},
    {"ip": "192.168.0.51", "name": "k8s02", "role": "control-plane"},
    {"ip": "192.168.0.52", "name": "k8s03", "role": "control-plane"}
  ],
  "workers": [
    {"ip": "192.168.0.53", "name": "k8s04", "role": "worker"},
    {"ip": "192.168.0.54", "name": "k8s05", "role": "worker"},
    {"ip": "192.168.0.55", "name": "k8s06", "role": "worker"},
    {"ip": "192.168.0.56", "name": "k8s07", "role": "worker"},
    {"ip": "192.168.0.57", "name": "k8s08", "role": "worker"},
    {"ip": "192.168.0.58", "name": "k8s09", "role": "worker"}
  ],
  "vip": "192.168.0.199"
}
EOF

echo "" | tee -a "$DISCOVERY_LOG"
echo "Discovery complete!" | tee -a "$DISCOVERY_LOG"
echo "Logs saved to: $DISCOVERY_LOG" | tee -a "$DISCOVERY_LOG"
echo "State saved to: $STATE_FILE" | tee -a "$DISCOVERY_LOG"