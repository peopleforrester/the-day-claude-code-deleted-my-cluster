#!/bin/bash
# ABOUTME: Reset all nodes to clean state for fresh cluster deployment
# ABOUTME: Removes Kubernetes, old containerd, and prepares for containerd 2.1.4

set -euo pipefail

LOG_DIR="logs/02-reset"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESET_LOG="$LOG_DIR/reset-$TIMESTAMP.log"
COMMANDS_LOG="$LOG_DIR/commands-$TIMESTAMP.log"

ALL_NODES=("192.168.0.50" "192.168.0.51" "192.168.0.52" "192.168.0.53" "192.168.0.54" "192.168.0.55" "192.168.0.56" "192.168.0.57" "192.168.0.58")
NODE_NAMES=("k8s01" "k8s02" "k8s03" "k8s04" "k8s05" "k8s06" "k8s07" "k8s08" "k8s09")

echo "Starting node reset at $TIMESTAMP" | tee "$RESET_LOG"
echo "================================================" | tee -a "$RESET_LOG"

# Function to reset a node
reset_node() {
    local ip=$1
    local name=$2
    
    echo "" | tee -a "$RESET_LOG"
    echo "Resetting $name ($ip)..." | tee -a "$RESET_LOG"
    echo "------------------------" | tee -a "$RESET_LOG"
    
    # Log commands
    echo "[$TIMESTAMP] Commands for $name ($ip):" >> "$COMMANDS_LOG"
    
    # Stop kubelet if running
    echo "Stopping kubelet..." | tee -a "$RESET_LOG"
    ssh root@$ip "systemctl stop kubelet 2>/dev/null || true" 2>&1 | tee -a "$RESET_LOG"
    echo "  systemctl stop kubelet" >> "$COMMANDS_LOG"
    
    # Kubeadm reset if installed
    if ssh root@$ip "which kubeadm" >/dev/null 2>&1; then
        echo "Running kubeadm reset..." | tee -a "$RESET_LOG"
        ssh root@$ip "kubeadm reset -f 2>&1" | grep -E "preflight|reset|cleanup" | tee -a "$RESET_LOG"
        echo "  kubeadm reset -f" >> "$COMMANDS_LOG"
    fi
    
    # Stop and disable services
    echo "Stopping container runtime..." | tee -a "$RESET_LOG"
    ssh root@$ip "systemctl stop containerd 2>/dev/null || true" 2>&1 | tee -a "$RESET_LOG"
    ssh root@$ip "systemctl disable containerd 2>/dev/null || true" 2>&1 | tee -a "$RESET_LOG"
    echo "  systemctl stop containerd" >> "$COMMANDS_LOG"
    echo "  systemctl disable containerd" >> "$COMMANDS_LOG"
    
    # Clean up network interfaces
    echo "Cleaning network interfaces..." | tee -a "$RESET_LOG"
    ssh root@$ip "ip link delete cni0 2>/dev/null || true" 2>&1 | tee -a "$RESET_LOG"
    ssh root@$ip "ip link delete flannel.1 2>/dev/null || true" 2>&1 | tee -a "$RESET_LOG"
    ssh root@$ip "ip link delete cilium_net 2>/dev/null || true" 2>&1 | tee -a "$RESET_LOG"
    ssh root@$ip "ip link delete cilium_vxlan 2>/dev/null || true" 2>&1 | tee -a "$RESET_LOG"
    echo "  ip link delete cni0/flannel.1/cilium_*" >> "$COMMANDS_LOG"
    
    # Remove Kubernetes packages
    echo "Removing Kubernetes packages..." | tee -a "$RESET_LOG"
    ssh root@$ip "apt-mark unhold kubelet kubeadm kubectl 2>/dev/null || true" 2>&1 | tee -a "$RESET_LOG"
    ssh root@$ip "apt-get remove -y --purge kubeadm kubectl kubelet kubernetes-cni 2>/dev/null || true" >/dev/null 2>&1
    ssh root@$ip "apt-get autoremove -y 2>/dev/null || true" >/dev/null 2>&1
    echo "  apt-get remove kubeadm kubectl kubelet kubernetes-cni" >> "$COMMANDS_LOG"
    
    # Remove containerd 1.7.x
    echo "Removing containerd 1.7.x..." | tee -a "$RESET_LOG"
    ssh root@$ip "apt-get remove -y --purge containerd.io 2>/dev/null || true" >/dev/null 2>&1
    echo "  apt-get remove containerd.io" >> "$COMMANDS_LOG"
    
    # Clean directories
    echo "Cleaning directories..." | tee -a "$RESET_LOG"
    ssh root@$ip "rm -rf /etc/kubernetes /var/lib/etcd /var/lib/kubelet /var/lib/containerd" 2>&1 | tee -a "$RESET_LOG"
    ssh root@$ip "rm -rf /etc/cni /opt/cni /var/lib/cni /var/run/calico" 2>&1 | tee -a "$RESET_LOG"
    ssh root@$ip "rm -rf /etc/containerd" 2>&1 | tee -a "$RESET_LOG"
    echo "  rm -rf /etc/kubernetes /var/lib/etcd /var/lib/kubelet /var/lib/containerd" >> "$COMMANDS_LOG"
    echo "  rm -rf /etc/cni /opt/cni /var/lib/cni /var/run/calico" >> "$COMMANDS_LOG"
    
    # Clean iptables
    echo "Cleaning iptables..." | tee -a "$RESET_LOG"
    ssh root@$ip "iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X" 2>&1 | tee -a "$RESET_LOG"
    echo "  iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X" >> "$COMMANDS_LOG"
    
    # Update package list
    echo "Updating package list..." | tee -a "$RESET_LOG"
    ssh root@$ip "apt-get update" >/dev/null 2>&1
    echo "  apt-get update" >> "$COMMANDS_LOG"
    
    echo "✓ $name reset complete" | tee -a "$RESET_LOG"
}

# Reset all nodes
for i in "${!ALL_NODES[@]}"; do
    reset_node "${ALL_NODES[$i]}" "${NODE_NAMES[$i]}"
done

echo "" | tee -a "$RESET_LOG"
echo "================================================" | tee -a "$RESET_LOG"
echo "All nodes reset successfully!" | tee -a "$RESET_LOG"
echo "Logs saved to: $RESET_LOG" | tee -a "$RESET_LOG"
echo "Commands saved to: $COMMANDS_LOG" | tee -a "$RESET_LOG"