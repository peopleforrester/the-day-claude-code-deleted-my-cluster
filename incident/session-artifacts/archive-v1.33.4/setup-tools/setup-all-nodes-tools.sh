#!/bin/bash
# Setup kubectl, crictl, etcdctl and kubeconfig on all nodes

set -e

echo "========================================="
echo "Setting up tools on all cluster nodes"
echo "========================================="

# Define all nodes
CONTROL_NODES=("192.168.0.50" "192.168.0.51" "192.168.0.52")
WORKER_NODES=("192.168.0.53" "192.168.0.54" "192.168.0.55" "192.168.0.56" "192.168.0.57" "192.168.0.58")
ALL_NODES=("${CONTROL_NODES[@]}" "${WORKER_NODES[@]}")

# First, get the admin.conf from k8s01
echo "Fetching admin.conf from k8s01..."
scp root@192.168.0.50:/etc/kubernetes/admin.conf /tmp/admin.conf

# Function to setup tools on a node
setup_node() {
    local NODE_IP=$1
    local NODE_NAME=$2

    echo ""
    echo "========================================="
    echo "Setting up $NODE_NAME ($NODE_IP)"
    echo "========================================="

    # Check if kubectl is already installed
    echo "Checking kubectl..."
    if ! ssh root@$NODE_IP "which kubectl" >/dev/null 2>&1; then
        echo "Installing kubectl..."
        ssh root@$NODE_IP "apt-get update && apt-get install -y kubectl=1.33.4-1.1"
    else
        echo "kubectl already installed"
    fi

    # Check if crictl is already installed
    echo "Checking crictl..."
    if ! ssh root@$NODE_IP "which crictl" >/dev/null 2>&1; then
        echo "Installing crictl..."
        ssh root@$NODE_IP "cd /tmp && wget -q https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.33.0/crictl-v1.33.0-linux-amd64.tar.gz && tar -xzf crictl-v1.33.0-linux-amd64.tar.gz && mv crictl /usr/local/bin/ && chmod +x /usr/local/bin/crictl"

        # Configure crictl
        ssh root@$NODE_IP "cat > /etc/crictl.yaml << EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF"
    else
        echo "crictl already installed"
    fi

    # Install etcdctl
    echo "Checking etcdctl..."
    if ! ssh root@$NODE_IP "which etcdctl" >/dev/null 2>&1; then
        echo "Installing etcdctl..."
        ssh root@$NODE_IP "cd /tmp && wget -q https://github.com/etcd-io/etcd/releases/download/v3.5.21/etcd-v3.5.21-linux-amd64.tar.gz && tar -xzf etcd-v3.5.21-linux-amd64.tar.gz && mv etcd-v3.5.21-linux-amd64/etcdctl /usr/local/bin/ && chmod +x /usr/local/bin/etcdctl"
    else
        echo "etcdctl already installed"
    fi

    # Setup kubectl configuration
    echo "Setting up kubectl configuration..."
    ssh root@$NODE_IP "mkdir -p /root/.kube"
    scp /tmp/admin.conf root@$NODE_IP:/root/.kube/config
    ssh root@$NODE_IP "chmod 600 /root/.kube/config"

    # Create kubectl alias and completion
    echo "Setting up kubectl aliases and completion..."
    ssh root@$NODE_IP "cat >> /root/.bashrc << 'EOF'

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
source <(kubectl completion bash)
complete -o default -F __start_kubectl k
EOF"

    # Test kubectl
    echo "Testing kubectl..."
    if ssh root@$NODE_IP "kubectl get nodes" >/dev/null 2>&1; then
        echo "✓ kubectl configured and working"
    else
        echo "⚠ kubectl configured but may have connection issues"
    fi

    # Test crictl
    echo "Testing crictl..."
    if ssh root@$NODE_IP "crictl ps" >/dev/null 2>&1; then
        echo "✓ crictl configured and working"
    else
        echo "⚠ crictl may need additional configuration"
    fi

    echo "✓ $NODE_NAME setup complete"
}

# Setup control plane nodes
echo ""
echo "Setting up Control Plane nodes..."
for i in ${!CONTROL_NODES[@]}; do
    NODE_IP="${CONTROL_NODES[$i]}"
    NODE_NAME="k8s0$((i+1))"
    setup_node "$NODE_IP" "$NODE_NAME"
done

# Setup worker nodes
echo ""
echo "Setting up Worker nodes..."
for i in ${!WORKER_NODES[@]}; do
    NODE_IP="${WORKER_NODES[$i]}"
    NODE_NAME="k8s0$((i+4))"
    setup_node "$NODE_IP" "$NODE_NAME"
done

echo ""
echo "========================================="
echo "Verification Summary"
echo "========================================="

# Quick verification on all nodes
echo ""
echo "kubectl version on all nodes:"
for i in ${!ALL_NODES[@]}; do
    NODE_IP="${ALL_NODES[$i]}"
    if [ $i -lt 3 ]; then
        NODE_NAME="k8s0$((i+1))"
    else
        NODE_NAME="k8s0$((i+1))"
    fi
    echo -n "$NODE_NAME: "
    ssh root@$NODE_IP "kubectl version --client --short 2>/dev/null | grep Client" || echo "Not installed"
done

echo ""
echo "crictl version on all nodes:"
for i in ${!ALL_NODES[@]}; do
    NODE_IP="${ALL_NODES[$i]}"
    if [ $i -lt 3 ]; then
        NODE_NAME="k8s0$((i+1))"
    else
        NODE_NAME="k8s0$((i+1))"
    fi
    echo -n "$NODE_NAME: "
    ssh root@$NODE_IP "crictl --version 2>/dev/null" || echo "Not installed"
done

echo ""
echo "etcdctl version on all nodes:"
for i in ${!ALL_NODES[@]}; do
    NODE_IP="${ALL_NODES[$i]}"
    if [ $i -lt 3 ]; then
        NODE_NAME="k8s0$((i+1))"
    else
        NODE_NAME="k8s0$((i+1))"
    fi
    echo -n "$NODE_NAME: "
    ssh root@$NODE_IP "etcdctl version 2>/dev/null | head -1" || echo "Not installed"
done

echo ""
echo "Testing kubectl get nodes from each node:"
for i in ${!ALL_NODES[@]}; do
    NODE_IP="${ALL_NODES[$i]}"
    if [ $i -lt 3 ]; then
        NODE_NAME="k8s0$((i+1))"
    else
        NODE_NAME="k8s0$((i+1))"
    fi
    echo ""
    echo "From $NODE_NAME:"
    ssh root@$NODE_IP "kubectl get nodes --no-headers 2>/dev/null | wc -l" | xargs -I {} echo "  Can see {} nodes"
done

echo ""
echo "========================================="
echo "All nodes configured with:"
echo "- kubectl v1.33.4"
echo "- crictl v1.33.0"
echo "- etcdctl v3.5.21"
echo "- Cluster admin kubeconfig"
echo "========================================="
