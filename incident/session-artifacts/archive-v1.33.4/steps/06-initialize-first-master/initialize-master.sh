#!/bin/bash
# Initialize the first Kubernetes master node

FIRST_MASTER="192.168.0.50"
VIP="192.168.0.200"
LOG_FILE="steps/06-initialize-first-master/init-06.log"

echo "===================================" | tee -a $LOG_FILE
echo "Initializing First Master" | tee -a $LOG_FILE
echo "Node: k8s01 ($FIRST_MASTER)" | tee -a $LOG_FILE
echo "Control Plane Endpoint: $VIP:6443" | tee -a $LOG_FILE
echo "Started: $(date)" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# 1. Copy kubeadm config to the first master
echo "1. Copying kubeadm configuration..." | tee -a $LOG_FILE
scp steps/06-initialize-first-master/kubeadm-config.yaml root@$FIRST_MASTER:/tmp/kubeadm-config.yaml >> $LOG_FILE 2>&1

# 2. Ensure crictl is configured
echo "2. Configuring crictl..." | tee -a $LOG_FILE
ssh root@$FIRST_MASTER "cat > /etc/crictl.yaml << EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
pull-image-on-create: false
EOF" >> $LOG_FILE 2>&1

# 3. Pre-pull images (optional but helps with troubleshooting)
echo "3. Pre-pulling Kubernetes images..." | tee -a $LOG_FILE
echo "   This may take a few minutes..." | tee -a $LOG_FILE
ssh root@$FIRST_MASTER "kubeadm config images pull --config=/tmp/kubeadm-config.yaml" >> $LOG_FILE 2>&1

if [ $? -ne 0 ]; then
    echo "   ⚠ Image pull had issues, but continuing..." | tee -a $LOG_FILE
fi

# 4. Initialize the cluster
echo "4. Initializing Kubernetes cluster..." | tee -a $LOG_FILE
echo "   This will take several minutes..." | tee -a $LOG_FILE

# Run kubeadm init and capture output
ssh root@$FIRST_MASTER "kubeadm init --config=/tmp/kubeadm-config.yaml --upload-certs" 2>&1 | tee -a $LOG_FILE

# Check if initialization was successful
if ssh root@$FIRST_MASTER "test -f /etc/kubernetes/admin.conf" 2>/dev/null; then
    echo "" | tee -a $LOG_FILE
    echo "✓ Cluster initialization successful!" | tee -a $LOG_FILE
else
    echo "" | tee -a $LOG_FILE
    echo "✗ Cluster initialization failed!" | tee -a $LOG_FILE
    echo "Check the log file for details: $LOG_FILE" | tee -a $LOG_FILE
    exit 1
fi

# 5. Configure kubectl for root user
echo "" | tee -a $LOG_FILE
echo "5. Configuring kubectl access..." | tee -a $LOG_FILE
ssh root@$FIRST_MASTER "mkdir -p /root/.kube && cp -f /etc/kubernetes/admin.conf /root/.kube/config && chown root:root /root/.kube/config" >> $LOG_FILE 2>&1

# 6. Extract and save join commands
echo "6. Extracting join commands..." | tee -a $LOG_FILE

# Get the certificate key for control plane joins
CERT_KEY=$(ssh root@$FIRST_MASTER "kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -1" 2>/dev/null)
echo "   Certificate key: $CERT_KEY" | tee -a $LOG_FILE

# Generate control plane join command
echo "   Generating control plane join command..." | tee -a $LOG_FILE
CONTROL_PLANE_JOIN=$(ssh root@$FIRST_MASTER "kubeadm token create --print-join-command --certificate-key $CERT_KEY" 2>/dev/null)
echo "$CONTROL_PLANE_JOIN --control-plane --certificate-key $CERT_KEY" > steps/06-initialize-first-master/control-plane-join.sh
chmod +x steps/06-initialize-first-master/control-plane-join.sh

# Generate worker join command
echo "   Generating worker join command..." | tee -a $LOG_FILE
WORKER_JOIN=$(ssh root@$FIRST_MASTER "kubeadm token create --print-join-command" 2>/dev/null)
echo "$WORKER_JOIN" > steps/06-initialize-first-master/worker-join.sh
chmod +x steps/06-initialize-first-master/worker-join.sh

# 7. Verify cluster status
echo "" | tee -a $LOG_FILE
echo "7. Verifying cluster status..." | tee -a $LOG_FILE

# Check nodes
echo "   Nodes:" | tee -a $LOG_FILE
ssh root@$FIRST_MASTER "kubectl get nodes -o wide" 2>&1 | tee -a $LOG_FILE

# Check pods
echo "" | tee -a $LOG_FILE
echo "   System pods:" | tee -a $LOG_FILE
ssh root@$FIRST_MASTER "kubectl get pods -n kube-system -o wide" 2>&1 | tee -a $LOG_FILE

# Check component status
echo "" | tee -a $LOG_FILE
echo "   Component status:" | tee -a $LOG_FILE
ssh root@$FIRST_MASTER "kubectl get componentstatuses" 2>&1 | tee -a $LOG_FILE

# 8. Copy kubeconfig locally for management
echo "" | tee -a $LOG_FILE
echo "8. Copying kubeconfig locally..." | tee -a $LOG_FILE
mkdir -p ~/.kube
scp root@$FIRST_MASTER:/etc/kubernetes/admin.conf ~/.kube/k8s-cluster-config
echo "   Kubeconfig saved to: ~/.kube/k8s-cluster-config" | tee -a $LOG_FILE
echo "   To use: export KUBECONFIG=~/.kube/k8s-cluster-config" | tee -a $LOG_FILE

# Summary
echo "" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE
echo "Initialization Summary" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE

# Get cluster info
CLUSTER_INFO=$(ssh root@$FIRST_MASTER "kubectl cluster-info" 2>/dev/null)
echo "$CLUSTER_INFO" | tee -a $LOG_FILE

echo "" | tee -a $LOG_FILE
echo "Join commands saved to:" | tee -a $LOG_FILE
echo "  - Control plane: steps/06-initialize-first-master/control-plane-join.sh" | tee -a $LOG_FILE
echo "  - Workers: steps/06-initialize-first-master/worker-join.sh" | tee -a $LOG_FILE

echo "" | tee -a $LOG_FILE
echo "Completed: $(date)" | tee -a $LOG_FILE
