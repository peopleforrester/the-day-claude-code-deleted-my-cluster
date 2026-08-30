#!/bin/bash
# ABOUTME: Interactive deployment script for Kubernetes cluster
# ABOUTME: Guides through manual steps when automation isn't possible

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                Kubernetes Cluster Deployment                   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
}

print_step() {
    echo -e "\n${GREEN}▶ Step $1: $2${NC}"
    echo -e "${GREEN}────────────────────────────────────────────────────────────────${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_command() {
    echo -e "${BLUE}$ $1${NC}"
}

# VM Details
print_header
echo ""
echo "Cluster Configuration:"
echo "  Master:  192.168.0.183"
echo "  Worker1: 192.168.0.191"
echo "  Worker2: 192.168.0.194"
echo "  Worker3: 192.168.0.196"
echo "  Worker4: 192.168.0.197"
echo ""
echo "Credentials: User=claude, Password=<REDACTED-PASSWORD>"
echo ""

# Create deployment bundle
print_step "1" "Creating deployment bundle"
tar -czf k8s_deploy.tar.gz install_k8s_prerequisites.sh init_master.sh
print_success "Deployment bundle created: k8s_deploy.tar.gz"

# Manual deployment instructions
print_step "2" "Deploy to all nodes"
print_info "Copy and run these commands on each node:"
echo ""

cat << 'DEPLOY_COMMANDS'
# On each node (master and all workers), run:

# 1. Copy the deployment bundle (from your local machine):
scp k8s_deploy.tar.gz claude@<NODE_IP>:/tmp/

# 2. SSH into the node:
ssh claude@<NODE_IP>

# 3. Extract and install prerequisites:
cd /tmp
tar -xzf k8s_deploy.tar.gz
chmod +x *.sh
sudo ./install_k8s_prerequisites.sh

# 4. Exit the node:
exit
DEPLOY_COMMANDS

echo ""
print_info "Press Enter after completing installation on ALL nodes..."
read

# Master initialization
print_step "3" "Initialize Master Node"
print_info "Run these commands on the MASTER node (192.168.0.183):"
echo ""
print_command "ssh claude@192.168.0.183"
print_command "cd /tmp"
print_command "sudo ./init_master.sh"
print_command "cat /home/claude/kubeadm_join_command.sh"
echo ""
print_info "Copy the join command output and press Enter..."
read

# Join workers
print_step "4" "Join Worker Nodes"
print_info "Paste the join command you copied:"
read -r JOIN_CMD
echo ""
print_info "Run this command on each WORKER node:"
echo ""
print_command "sudo $JOIN_CMD"
echo ""
print_info "Press Enter after all workers have joined..."
read

# Verify
print_step "5" "Verify Cluster"
print_info "Run on master to check cluster status:"
print_command "kubectl get nodes"
echo ""

# Get kubeconfig
print_step "6" "Setup Local kubectl"
print_info "Copy kubeconfig from master:"
print_command "scp claude@192.168.0.183:/home/claude/.kube/config ./kubeconfig"
print_command "export KUBECONFIG=$(pwd)/kubeconfig"
print_command "kubectl get nodes"
echo ""

print_success "Deployment guide complete!"
echo ""
echo "Next steps:"
echo "1. Run: source ./setup_kubectl.sh"
echo "2. Verify with: ./verify_cluster.sh"
