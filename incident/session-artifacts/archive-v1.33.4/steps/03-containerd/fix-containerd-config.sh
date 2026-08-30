#!/bin/bash
# Fix containerd configuration issues

NODES=(50 51 52 53 54 55 56 57 58)
LOG_FILE="steps/03-containerd/fix-config.log"

echo "Fixing containerd configuration" | tee $LOG_FILE
echo "Started: $(date)" | tee -a $LOG_FILE
echo "================================" | tee -a $LOG_FILE

for node in "${NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    echo "" | tee -a $LOG_FILE
    echo "Fixing $NODE_NAME ($IP)..." | tee -a $LOG_FILE

    # First, let's check the actual CNI plugins location
    echo "  Checking CNI plugins..." | tee -a $LOG_FILE
    ssh root@$IP "ls -la /opt/cni/bin/ | head -5" >> $LOG_FILE 2>&1

    # Get current config and fix systemd cgroup
    echo "  Fixing systemd cgroup configuration..." | tee -a $LOG_FILE
    ssh root@$IP '
        # Backup current config
        cp /etc/containerd/config.toml /etc/containerd/config.toml.bak

        # Generate fresh config with proper settings
        containerd config default > /etc/containerd/config.toml.new

        # Fix systemd cgroup in the new config
        sed -i "s/SystemdCgroup = false/SystemdCgroup = true/g" /etc/containerd/config.toml.new

        # Fix the sandbox image
        sed -i "s|sandbox_image = \"registry.k8s.io/pause:.*\"|sandbox_image = \"registry.k8s.io/pause:3.10\"|" /etc/containerd/config.toml.new

        # Enable metrics
        sed -i "/\[metrics\]/,/\[/{s/address = \"\"/address = \"127.0.0.1:1338\"/}" /etc/containerd/config.toml.new

        # Move the new config into place
        mv /etc/containerd/config.toml.new /etc/containerd/config.toml

        # Restart containerd
        systemctl restart containerd

        # Verify the changes
        echo "SystemdCgroup lines in config:"
        grep -n "SystemdCgroup" /etc/containerd/config.toml
    ' >> $LOG_FILE 2>&1

    echo "  ✓ Configuration updated on $NODE_NAME" | tee -a $LOG_FILE
done

echo "" | tee -a $LOG_FILE
echo "================================" | tee -a $LOG_FILE
echo "Configuration fixes complete!" | tee -a $LOG_FILE
echo "Finished: $(date)" | tee -a $LOG_FILE
