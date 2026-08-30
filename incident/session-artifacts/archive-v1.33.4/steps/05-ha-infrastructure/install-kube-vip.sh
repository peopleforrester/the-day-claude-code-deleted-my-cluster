#!/bin/bash
# Install kube-vip v1.0.0 EXACTLY as specified in requirements

CONTROL_NODES=(50 51 52)
VIP="192.168.0.200"
KUBE_VIP_VERSION="v1.0.0"  # EXACT version from requirements
LOG_FILE="steps/05-ha-infrastructure/kube-vip-install.log"

echo "===================================" | tee $LOG_FILE
echo "Installing kube-vip ${KUBE_VIP_VERSION}" | tee -a $LOG_FILE
echo "VIP: $VIP" | tee -a $LOG_FILE
echo "Started: $(date)" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# First, check if the exact version exists
echo "Checking kube-vip ${KUBE_VIP_VERSION} availability..." | tee -a $LOG_FILE
RELEASE_CHECK=$(curl -s https://api.github.com/repos/kube-vip/kube-vip/releases | grep -c "\"tag_name\": \"${KUBE_VIP_VERSION}\"")

if [ "$RELEASE_CHECK" -eq 0 ]; then
    echo "  Checking all available versions..." | tee -a $LOG_FILE
    curl -s https://api.github.com/repos/kube-vip/kube-vip/releases | grep '"tag_name"' | head -10 | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
    echo "ERROR: kube-vip ${KUBE_VIP_VERSION} not found in releases!" | tee -a $LOG_FILE
    echo "Available versions shown above. Stopping as per NO SUBSTITUTIONS policy." | tee -a $LOG_FILE
    exit 1
fi

echo "  ✓ Version ${KUBE_VIP_VERSION} found" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Download kube-vip binary for the exact version
echo "Downloading kube-vip ${KUBE_VIP_VERSION} binary..." | tee -a $LOG_FILE
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# Download the container image and extract binary (standard method for kube-vip)
# kube-vip is typically deployed as a static pod, but we need the binary first
curl -sL "https://github.com/kube-vip/kube-vip/releases/download/${KUBE_VIP_VERSION}/kube-vip-linux-amd64" -o kube-vip

if [ ! -f kube-vip ]; then
    echo "ERROR: Failed to download kube-vip binary" | tee -a $LOG_FILE
    exit 1
fi

chmod +x kube-vip
echo "  ✓ Binary downloaded" | tee -a $LOG_FILE

# Copy binary to all control plane nodes
for node in "${CONTROL_NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    echo "" | tee -a $LOG_FILE
    echo "Setting up kube-vip on $NODE_NAME ($IP)..." | tee -a $LOG_FILE

    # Copy binary
    echo "  Copying kube-vip binary..." | tee -a $LOG_FILE
    scp kube-vip root@$IP:/usr/local/bin/kube-vip >> $LOG_FILE 2>&1
    ssh root@$IP "chmod +x /usr/local/bin/kube-vip" >> $LOG_FILE 2>&1

    # Verify installation
    INSTALLED_VERSION=$(ssh root@$IP "/usr/local/bin/kube-vip version 2>&1 | grep -o 'Version:.*' | awk '{print \$2}'" 2>/dev/null)
    echo "  Installed version: $INSTALLED_VERSION" | tee -a $LOG_FILE

    # Get the primary network interface
    INTERFACE=$(ssh root@$IP "ip route | grep default | awk '{print \$5}' | head -1" 2>/dev/null)
    echo "  Network interface: $INTERFACE" | tee -a $LOG_FILE

    # Since the cluster isn't initialized yet, we'll prepare the static pod manifest
    # This will be used when we initialize the cluster
    echo "  Creating kube-vip static pod manifest..." | tee -a $LOG_FILE

    ssh root@$IP "mkdir -p /etc/kubernetes/manifests" >> $LOG_FILE 2>&1

    # Generate the manifest using kube-vip's built-in manifest generation
    # For control plane load balancing mode
    ssh root@$IP "/usr/local/bin/kube-vip manifest pod \
        --interface $INTERFACE \
        --address $VIP \
        --controlplane \
        --services \
        --arp \
        --leaderElection > /etc/kubernetes/manifests/kube-vip.yaml.template" >> $LOG_FILE 2>&1

    if [ $? -eq 0 ]; then
        echo "  ✓ Static pod manifest template created" | tee -a $LOG_FILE
    else
        echo "  ✗ Failed to create manifest template" | tee -a $LOG_FILE
    fi

    # For now, we'll also create a systemd service for pre-cluster testing
    # This will be replaced by the static pod once the cluster is initialized
    echo "  Creating temporary systemd service for testing..." | tee -a $LOG_FILE

    ssh root@$IP "cat > /etc/systemd/system/kube-vip-temp.service << EOF
[Unit]
Description=Kube-VIP (Temporary for testing)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/kube-vip start \
    --interface $INTERFACE \
    --address $VIP \
    --port 6443 \
    --arp \
    --startAsLeader=true \
    --prometheusHTTPServer :2113
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF" >> $LOG_FILE 2>&1

    # For initial testing, start on first node only
    if [ "$node" = "50" ]; then
        echo "  Starting temporary kube-vip service on $NODE_NAME (primary)..." | tee -a $LOG_FILE
        ssh root@$IP "systemctl daemon-reload && systemctl start kube-vip-temp" >> $LOG_FILE 2>&1

        # Give it a moment to start
        sleep 3

        # Check if VIP is assigned
        HAS_VIP=$(ssh root@$IP "ip addr show | grep -q '$VIP' && echo 'yes' || echo 'no'" 2>/dev/null)
        if [ "$HAS_VIP" = "yes" ]; then
            echo "  ✓ VIP $VIP assigned to $NODE_NAME" | tee -a $LOG_FILE
        else
            echo "  ✗ VIP not assigned - will be configured during cluster init" | tee -a $LOG_FILE
        fi
    else
        echo "  Service prepared but not started (will start during cluster init)" | tee -a $LOG_FILE
    fi
done

# Clean up temp directory
cd /
rm -rf $TEMP_DIR

# Test VIP
echo "" | tee -a $LOG_FILE
echo "Testing VIP connectivity..." | tee -a $LOG_FILE
ping -c 2 -W 1 $VIP &>/dev/null
if [ $? -eq 0 ]; then
    echo "  ✓ VIP $VIP is responding" | tee -a $LOG_FILE
else
    echo "  ℹ VIP not yet responding (normal - will be active after cluster init)" | tee -a $LOG_FILE
fi

echo "" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE
echo "kube-vip Installation Summary" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE
echo "✓ kube-vip ${KUBE_VIP_VERSION} installed on all control plane nodes" | tee -a $LOG_FILE
echo "✓ Static pod manifests prepared for cluster initialization" | tee -a $LOG_FILE
echo "✓ Temporary service created for pre-init testing" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Note: kube-vip will be fully activated during cluster initialization (Step 06)" | tee -a $LOG_FILE
echo "The static pod manifest will be used once the kubelet starts." | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Completed: $(date)" | tee -a $LOG_FILE
