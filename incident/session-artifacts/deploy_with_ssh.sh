#!/bin/bash
# ABOUTME: Alternative deployment script using SSH with manual password entry
# ABOUTME: Used when sshpass is not available on the deployment machine

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

print_warning "This script requires manual password entry for each SSH connection."
print_warning "Password for all VMs: demo123"
echo ""

# Test connectivity first
print_status "Testing SSH connectivity to all nodes..."
print_status "You will be prompted for password (demo123) for each node"
echo ""

for node in "${!VMS[@]}"; do
    ip="${VMS[$node]}"
    print_status "Testing connection to $node ($ip)..."
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $SSH_USER@$ip "echo 'Connected to $node successfully'"
    if [ $? -eq 0 ]; then
        print_status "✓ Successfully connected to $node"
    else
        print_error "Failed to connect to $node ($ip)"
        exit 1
    fi
done

print_status "All nodes accessible. Starting deployment..."
echo ""

# Create a deployment package
print_status "Creating deployment package..."
tar -czf k8s_deploy.tar.gz install_k8s_prerequisites.sh init_master.sh

# Deploy to each node
for node in "${!VMS[@]}"; do
    ip="${VMS[$node]}"
    print_status "Deploying to $node ($ip)..."

    # Copy deployment package
    scp -o StrictHostKeyChecking=no k8s_deploy.tar.gz $SSH_USER@$ip:/tmp/

    # Extract and run prerequisites
    ssh -o StrictHostKeyChecking=no $SSH_USER@$ip "cd /tmp && tar -xzf k8s_deploy.tar.gz && chmod +x *.sh && sudo ./install_k8s_prerequisites.sh"

    if [ $? -eq 0 ]; then
        print_status "✓ Prerequisites installed on $node"
    else
        print_error "Failed to install prerequisites on $node"
        exit 1
    fi
done

# Initialize master
print_status "Initializing Kubernetes master node..."
ssh -o StrictHostKeyChecking=no $SSH_USER@${VMS["master"]} "cd /tmp && sudo ./init_master.sh"

# Get join command
print_status "Retrieving join command..."
JOIN_CMD=$(ssh -o StrictHostKeyChecking=no $SSH_USER@${VMS["master"]} "cat /home/claude/kubeadm_join_command.sh")

if [ -z "$JOIN_CMD" ]; then
    print_error "Failed to retrieve join command"
    exit 1
fi

echo "Join command: $JOIN_CMD"

# Join workers
for node in worker1 worker2 worker3 worker4; do
    ip="${VMS[$node]}"
    print_status "Joining $node to the cluster..."
    ssh -o StrictHostKeyChecking=no $SSH_USER@$ip "sudo $JOIN_CMD"

    if [ $? -eq 0 ]; then
        print_status "✓ $node successfully joined the cluster"
    else
        print_error "Failed to join $node to the cluster"
    fi
done

# Get cluster status
print_status "Checking cluster status..."
ssh -o StrictHostKeyChecking=no $SSH_USER@${VMS["master"]} "kubectl get nodes"

# Copy kubeconfig
print_status "Copying kubeconfig..."
scp -o StrictHostKeyChecking=no $SSH_USER@${VMS["master"]}:/home/claude/.kube/config ./kubeconfig

print_status "✨ Deployment complete!"
print_status "To use kubectl: export KUBECONFIG=$(pwd)/kubeconfig"

# Cleanup
rm -f k8s_deploy.tar.gz
