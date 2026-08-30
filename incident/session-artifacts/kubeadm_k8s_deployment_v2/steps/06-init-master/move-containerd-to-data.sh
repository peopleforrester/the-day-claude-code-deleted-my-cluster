#!/bin/bash
# Move containerd data to /data partition

MASTER1="192.168.0.183"

echo "=== Moving Containerd to /data Partition ==="
echo ""

# Stop containerd
echo "Stopping containerd..."
ssh root@$MASTER1 "systemctl stop containerd" 2>&1

# Remove the symlink if it exists
echo "Cleaning up old configuration..."
ssh root@$MASTER1 "rm -f /var/lib/containerd" 2>&1

# Move existing containerd data to /data
echo "Moving containerd data to /data..."
ssh root@$MASTER1 "mkdir -p /data/containerd" 2>&1
ssh root@$MASTER1 "if [ -d /var/lib/containerd ]; then cp -a /var/lib/containerd/* /data/containerd/ 2>/dev/null || true; fi" 2>&1
ssh root@$MASTER1 "rm -rf /var/lib/containerd" 2>&1

# Create symlink
echo "Creating symlink..."
ssh root@$MASTER1 "ln -s /data/containerd /var/lib/containerd" 2>&1

# Update containerd config to use /data
echo "Updating containerd configuration..."
ssh root@$MASTER1 "sed -i 's|root = \"/var/lib/containerd\"|root = \"/data/containerd\"|g' /etc/containerd/config.toml" 2>&1

# Start containerd
echo "Starting containerd..."
ssh root@$MASTER1 "systemctl start containerd" 2>&1

# Clean up images to free space
echo "Cleaning up failed image pulls..."
ssh root@$MASTER1 "ctr -n k8s.io images ls -q | xargs -r ctr -n k8s.io images rm 2>/dev/null || true" 2>&1

# Check disk space
echo ""
echo "Disk space after move:"
ssh root@$MASTER1 "df -h / /data" 2>&1

echo ""
echo "=== Move Complete ==="
