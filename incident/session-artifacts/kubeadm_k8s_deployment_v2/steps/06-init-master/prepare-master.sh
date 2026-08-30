#!/bin/bash
# Prepare master1 for initialization

MASTER1="192.168.0.183"

echo "=== Preparing Master1 for Initialization ==="
echo "Start time: $(date)"
echo ""

# Create directories on /data to save space on root partition
echo "Creating directories on /data partition..."
ssh root@$MASTER1 "mkdir -p /data/kubernetes /data/etcd /data/containerd" 2>&1

# Move containerd data to /data to free up space
echo "Moving containerd data to /data..."
ssh root@$MASTER1 "systemctl stop containerd" 2>&1
ssh root@$MASTER1 "if [ -d /var/lib/containerd ]; then mv /var/lib/containerd /data/containerd/lib 2>/dev/null || true; fi" 2>&1
ssh root@$MASTER1 "mkdir -p /var/lib/containerd" 2>&1
ssh root@$MASTER1 "ln -sf /data/containerd/lib /var/lib/containerd" 2>&1
ssh root@$MASTER1 "systemctl start containerd" 2>&1

# Copy kubeadm config
echo "Copying kubeadm configuration..."
scp configs/kubeadm-config.yaml root@$MASTER1:/root/kubeadm-config.yaml 2>&1

# Pre-pull images to /data
echo "Pre-pulling Kubernetes images..."
ssh root@$MASTER1 "kubeadm config images pull --config=/root/kubeadm-config.yaml" 2>&1 | grep -E "(Pulled|Already exists|%)" || echo "Images pulled"

# Check disk space
echo ""
echo "Disk space after preparation:"
ssh root@$MASTER1 "df -h / /data" 2>&1

echo ""
echo "=== Preparation Complete ==="
echo "End time: $(date)"
