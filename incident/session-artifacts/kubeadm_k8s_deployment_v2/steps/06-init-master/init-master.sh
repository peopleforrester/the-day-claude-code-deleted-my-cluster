#!/bin/bash
# Initialize the first Kubernetes master

MASTER1="192.168.0.183"

echo "=== Initializing First Kubernetes Master ==="
echo "Start time: $(date)"
echo ""

# Run kubeadm init
echo "Running kubeadm init..."
ssh root@$MASTER1 "kubeadm init --config=/root/kubeadm-config.yaml --upload-certs" 2>&1 | tee steps/06-init-master/kubeadm-init.log

# Extract important information from init output
echo ""
echo "Extracting join commands and tokens..."

# Get the control plane join command
CONTROL_PLANE_JOIN=$(grep -A 3 "You can now join any number of control-plane nodes" steps/06-init-master/kubeadm-init.log | grep -A 2 "kubeadm join" | tr '\n' ' ' | sed 's/\\//g' | sed 's/  */ /g')

# Get the worker join command
WORKER_JOIN=$(grep -A 2 "Then you can join any number of worker nodes" steps/06-init-master/kubeadm-init.log | grep -A 1 "kubeadm join" | tr '\n' ' ' | sed 's/\\//g' | sed 's/  */ /g')

# Save join commands
echo "$CONTROL_PLANE_JOIN" > state/control-plane-join-command.txt
echo "$WORKER_JOIN" > state/worker-join-command.txt

# Configure kubectl for root user
echo ""
echo "Configuring kubectl..."
ssh root@$MASTER1 "mkdir -p /root/.kube && cp -i /etc/kubernetes/admin.conf /root/.kube/config && chown root:root /root/.kube/config" 2>&1

# Copy kubeconfig locally
echo "Copying kubeconfig locally..."
mkdir -p ~/.kube
scp root@$MASTER1:/etc/kubernetes/admin.conf ~/.kube/config-k8s-cluster 2>&1

# Wait for API server to be ready
echo ""
echo "Waiting for API server to be ready..."
sleep 10

# Check cluster status
echo ""
echo "Checking cluster status..."
ssh root@$MASTER1 "kubectl get nodes && kubectl get pods -n kube-system" 2>&1

echo ""
echo "=== Master Initialization Complete ==="
echo "End time: $(date)"
