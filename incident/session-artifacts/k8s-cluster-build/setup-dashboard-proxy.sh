#!/bin/bash
# ABOUTME: Script to set up kubectl proxy for dashboard access
# ABOUTME: Establishes SSH tunnel and runs kubectl proxy
echo "Setting up Kubernetes Dashboard access..."

# Check if we can reach the cluster
if ! ssh -o ConnectTimeout=5 root@192.168.0.100 'echo "SSH connection successful"' >/dev/null 2>&1; then
    echo "Error: Cannot connect to cluster at 192.168.0.100"
    echo "Please ensure you have SSH access to the cluster"
    exit 1
fi

# Create SSH tunnel and run kubectl proxy on the remote server
echo "Starting kubectl proxy via SSH tunnel..."
echo "Dashboard will be available at: http://localhost:8111/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard-web:/proxy/"
echo ""
echo "Press Ctrl+C to stop the proxy"
echo ""

# This creates an SSH tunnel that:
# - Forwards local port 8111 to remote port 8111
# - Runs kubectl proxy on the remote server
ssh -L 8111:localhost:8111 root@192.168.0.100 'kubectl proxy --port=8111'
