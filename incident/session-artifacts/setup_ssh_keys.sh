#!/bin/bash
# ABOUTME: This script sets up SSH keys for passwordless access to all cluster nodes
# ABOUTME: It copies the generated SSH key to each node in the Kubernetes cluster

set -e

echo "Setting up SSH keys for cluster nodes..."

# List of nodes
declare -A nodes=(
    ["master"]="192.168.0.183"
    ["worker1"]="192.168.0.191"
    ["worker2"]="192.168.0.194"
    ["worker3"]="192.168.0.196"
    ["worker4"]="192.168.0.197"
)

# SSH user and password
SSH_USER="claude"
SSH_PASS="demo123"

# Copy SSH key to each node
for node in "${!nodes[@]}"; do
    ip="${nodes[$node]}"
    echo "Copying SSH key to $node ($ip)..."

    # Use sshpass to automate password entry
    sshpass -p "$SSH_PASS" ssh-copy-id -i ~/.ssh/k8s_cluster_key.pub -o StrictHostKeyChecking=no "$SSH_USER@$ip" 2>/dev/null || {
        echo "Failed to copy key to $node. Trying alternative method..."
        # Alternative method using expect if sshpass fails
        cat ~/.ssh/k8s_cluster_key.pub | sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$ip" "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    }

    echo "✓ SSH key copied to $node"
done

echo "SSH key setup complete!"
