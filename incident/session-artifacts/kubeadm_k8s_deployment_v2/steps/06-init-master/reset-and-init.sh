#!/bin/bash
# Reset and reinitialize with simpler config

MASTER1="192.168.0.183"

echo "=== Resetting and Reinitializing Master1 ==="
echo ""

# Reset kubeadm
echo "Resetting kubeadm..."
ssh root@$MASTER1 "kubeadm reset -f" 2>&1 > /dev/null

# Remove kube-vip temporarily
echo "Removing kube-vip for initial bootstrap..."
ssh root@$MASTER1 "rm -f /etc/kubernetes/manifests/kube-vip.yaml" 2>&1

# Create a simpler kubeadm config without VIP first
echo "Creating bootstrap config..."
ssh root@$MASTER1 "cat > /root/kubeadm-init-bootstrap.yaml << 'EOF'
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 192.168.0.183
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: v1.31.11
controlPlaneEndpoint: "192.168.0.183:6443"
networking:
  serviceSubnet: "10.96.0.0/12"
  podSubnet: "10.244.0.0/16"
apiServer:
  certSANs:
  - "192.168.0.180"
  - "192.168.0.183"
  - "192.168.0.194"
  - "192.168.0.196"
  - "kubernetes"
  - "kubernetes.default"
  - "kubernetes.default.svc"
  - "kubernetes.default.svc.cluster.local"
etcd:
  local:
    dataDir: "/data/etcd"
EOF" 2>&1

# Run kubeadm init
echo "Running kubeadm init..."
ssh root@$MASTER1 "kubeadm init --config=/root/kubeadm-init-bootstrap.yaml --upload-certs" 2>&1 | tee steps/06-init-master/kubeadm-init-bootstrap.log

echo ""
echo "=== Bootstrap Complete ==="
