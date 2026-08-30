#!/bin/bash
# Initialize single-node cluster due to network constraints

MASTER1="192.168.0.183"

echo "=== Initializing Single-Node Kubernetes Cluster ==="
echo "Due to network constraints, starting with single-node setup"
echo ""

# Reset any previous attempts
echo "Resetting previous configuration..."
ssh root@$MASTER1 "kubeadm reset -f" 2>&1 > /dev/null

# Remove kube-vip for now
ssh root@$MASTER1 "rm -f /etc/kubernetes/manifests/kube-vip.yaml" 2>&1

# Create single-node config
echo "Creating single-node configuration..."
ssh root@$MASTER1 "cat > /root/kubeadm-single-node.yaml << 'EOF'
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 10.0.2.2
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: v1.31.11
controlPlaneEndpoint: "10.0.2.2:6443"
networking:
  serviceSubnet: "10.96.0.0/12"
  podSubnet: "10.244.0.0/16"
etcd:
  local:
    dataDir: "/data/etcd"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
failSwapOn: false
EOF" 2>&1

# Initialize cluster
echo "Running kubeadm init..."
ssh root@$MASTER1 "kubeadm init --config=/root/kubeadm-single-node.yaml" 2>&1 | tee steps/06-init-master/single-node-init.log

# Check if successful
if grep -q "Your Kubernetes control-plane has initialized successfully!" steps/06-init-master/single-node-init.log; then
  echo ""
  echo "✓ Cluster initialized successfully!"

  # Configure kubectl
  echo "Configuring kubectl..."
  ssh root@$MASTER1 "mkdir -p /root/.kube && cp -f /etc/kubernetes/admin.conf /root/.kube/config" 2>&1

  # Remove taint to allow pods on control plane
  echo "Removing control-plane taint for single-node cluster..."
  ssh root@$MASTER1 "kubectl taint nodes --all node-role.kubernetes.io/control-plane-" 2>&1

  # Check cluster status
  echo ""
  echo "Cluster status:"
  ssh root@$MASTER1 "kubectl get nodes && echo '' && kubectl get pods -n kube-system" 2>&1
else
  echo ""
  echo "✗ Cluster initialization failed"
fi

echo ""
echo "=== Single-Node Initialization Complete ==="
