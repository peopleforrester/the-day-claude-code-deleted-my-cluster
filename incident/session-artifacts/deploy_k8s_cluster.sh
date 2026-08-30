#!/bin/bash
# ABOUTME: Main deployment script for Kubernetes cluster installation
# ABOUTME: Orchestrates the complete cluster setup process

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# VM configuration
declare -A VMS=(
    ["master"]="192.168.0.183"
    ["worker1"]="192.168.0.191"
    ["worker2"]="192.168.0.194"
    ["worker3"]="192.168.0.196"
    ["worker4"]="192.168.0.197"
)

SSH_USER="claude"
SSH_PASS="demo123"

# Progress tracking
TOTAL_STEPS=10
CURRENT_STEP=0

update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percentage=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    print_status "Progress: $CURRENT_STEP/$TOTAL_STEPS ($percentage%)"
}

# Step 1: Test SSH connectivity
print_status "Step 1: Testing SSH connectivity to all nodes..."
update_progress

for node in "${!VMS[@]}"; do
    ip="${VMS[$node]}"
    print_status "Testing connection to $node ($ip)..."

    if timeout 5 bash -c "echo 'exit' | sshpass -p '$SSH_PASS' ssh -o StrictHostKeyChecking=no $SSH_USER@$ip 2>/dev/null"; then
        print_status "✓ Successfully connected to $node"
    else
        print_error "Failed to connect to $node ($ip)"
        exit 1
    fi
done

# Step 2: Copy installation scripts to all nodes
print_status "Step 2: Copying installation scripts to all nodes..."
update_progress

for node in "${!VMS[@]}"; do
    ip="${VMS[$node]}"
    print_status "Copying scripts to $node..."
    sshpass -p "$SSH_PASS" scp -o StrictHostKeyChecking=no install_k8s_prerequisites.sh $SSH_USER@$ip:/tmp/
    if [ "$node" == "master" ]; then
        sshpass -p "$SSH_PASS" scp -o StrictHostKeyChecking=no init_master.sh $SSH_USER@$ip:/tmp/
    fi
done

# Step 3-7: Install prerequisites on all nodes
NODE_COUNT=0
for node in "${!VMS[@]}"; do
    NODE_COUNT=$((NODE_COUNT + 1))
    ip="${VMS[$node]}"
    print_status "Step $((2 + NODE_COUNT)): Installing Kubernetes prerequisites on $node..."
    update_progress

    print_status "Installing on $node (this may take 2-3 minutes)..."
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$ip "chmod +x /tmp/install_k8s_prerequisites.sh && sudo /tmp/install_k8s_prerequisites.sh" &

    # For progress indication
    PID=$!
    while kill -0 $PID 2>/dev/null; do
        echo -n "."
        sleep 5
    done
    echo ""

    wait $PID
    if [ $? -eq 0 ]; then
        print_status "✓ Prerequisites installed on $node"
    else
        print_error "Failed to install prerequisites on $node"
        exit 1
    fi
done

# Step 8: Initialize master node
print_status "Step 8: Initializing Kubernetes master node..."
update_progress

print_status "Initializing cluster on master (this may take 3-5 minutes)..."
sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@${VMS["master"]} "chmod +x /tmp/init_master.sh && /tmp/init_master.sh"

# Get the join command
print_status "Retrieving join command from master..."
JOIN_CMD=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@${VMS["master"]} "cat /home/claude/kubeadm_join_command.sh")

if [ -z "$JOIN_CMD" ]; then
    print_error "Failed to retrieve join command"
    exit 1
fi

# Step 9: Join worker nodes
print_status "Step 9: Joining worker nodes to the cluster..."
update_progress

for node in worker1 worker2 worker3 worker4; do
    ip="${VMS[$node]}"
    print_status "Joining $node to the cluster..."

    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$ip "sudo $JOIN_CMD"

    if [ $? -eq 0 ]; then
        print_status "✓ $node successfully joined the cluster"
    else
        print_error "Failed to join $node to the cluster"
        exit 1
    fi
done

# Step 10: Verify cluster status
print_status "Step 10: Verifying cluster status..."
update_progress

print_status "Waiting for all nodes to be ready (this may take 1-2 minutes)..."
sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@${VMS["master"]} "kubectl wait --for=condition=Ready nodes --all --timeout=300s"

# Get cluster status
print_status "Cluster status:"
sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@${VMS["master"]} "kubectl get nodes"

# Copy kubeconfig to local machine
print_status "Copying kubeconfig to local machine..."
sshpass -p "$SSH_PASS" scp -o StrictHostKeyChecking=no $SSH_USER@${VMS["master"]}:/home/claude/.kube/config ./kubeconfig
echo "export KUBECONFIG=$(pwd)/kubeconfig" > setup_kubectl.sh
chmod +x setup_kubectl.sh

print_status "✨ Kubernetes cluster deployment complete!"
print_status "To use kubectl locally, run: source ./setup_kubectl.sh"
print_status ""
print_status "Cluster summary:"
print_status "  Master: ${VMS["master"]}"
print_status "  Workers: ${VMS["worker1"]}, ${VMS["worker2"]}, ${VMS["worker3"]}, ${VMS["worker4"]}"
print_status "  Network Plugin: Calico"
print_status "  Pod Network CIDR: 10.244.0.0/16"
