#!/bin/bash
# ABOUTME: Script to fix DNS issues and install Kubernetes with retries
# ABOUTME: Handles temporary network failures during installation

set -e

echo "Fixing DNS and installing Kubernetes prerequisites..."

# Fix DNS first
echo "Configuring DNS..."
cat <<EOF | sudo tee /etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF

# Test connectivity
echo "Testing connectivity..."
for i in {1..5}; do
    if ping -c 1 google.com &> /dev/null; then
        echo "✓ Internet connectivity confirmed"
        break
    else
        echo "Attempt $i: Waiting for network..."
        sleep 5
    fi
done

# Update with retries
echo "Updating package lists with retries..."
for i in {1..3}; do
    if sudo apt-get update; then
        echo "✓ Package lists updated"
        break
    else
        echo "Retry $i: Fixing apt sources..."
        # Try different mirrors
        sudo sed -i 's|http://archive.ubuntu.com|http://us.archive.ubuntu.com|g' /etc/apt/sources.list
        sleep 10
    fi
done

# Install prerequisites
echo "Installing prerequisites..."
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release || {
    echo "Retrying with --fix-missing..."
    sudo apt-get update --fix-missing
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
}

# Now run the main installation
echo "Running main Kubernetes installation..."
sudo /tmp/install_k8s_prerequisites.sh
