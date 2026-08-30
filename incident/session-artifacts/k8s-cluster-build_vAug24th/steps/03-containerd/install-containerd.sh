#!/bin/bash
# ABOUTME: Install containerd v2.1.4 exactly as specified
# ABOUTME: Configures containerd for Kubernetes with systemd cgroup driver

set -e

CONTAINERD_VERSION="2.1.4"
RUNC_VERSION="1.2.4"

echo "=== Installing containerd v${CONTAINERD_VERSION} ==="

# Discovery phase - check current state
echo "1. Current state check..."
if command -v containerd &> /dev/null; then
    echo "WARNING: containerd already installed: $(containerd --version)"
    echo "Proceeding with reinstallation..."
fi

# Download and install containerd v2.1.4
echo "2. Downloading containerd v${CONTAINERD_VERSION}..."
cd /tmp
wget -q https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz

echo "3. Extracting containerd..."
tar -C /usr/local -xzf containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz

# Create containerd service file
echo "4. Creating containerd systemd service..."
mkdir -p /usr/local/lib/systemd/system/
cat > /usr/local/lib/systemd/system/containerd.service <<EOF
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5

LimitNPROC=infinity
LimitCORE=infinity

TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

# Download and install runc
echo "5. Installing runc v${RUNC_VERSION}..."
wget -q https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc

# Download and install CNI plugins
echo "6. Installing CNI plugins..."
CNI_VERSION="1.6.2"
mkdir -p /opt/cni/bin
wget -q https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-amd64-v${CNI_VERSION}.tgz
tar -C /opt/cni/bin -xzf cni-plugins-linux-amd64-v${CNI_VERSION}.tgz

# Generate default containerd configuration
echo "7. Generating containerd configuration..."
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# Configure containerd for Kubernetes with systemd cgroup driver
echo "8. Configuring containerd for Kubernetes..."
# Update config for systemd cgroup driver (cgroup v2)
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Configure container runtime endpoint
sed -i 's|sandbox_image = "registry.k8s.io/pause:.*"|sandbox_image = "registry.k8s.io/pause:3.10"|g' /etc/containerd/config.toml

# Enable CRI plugin (ensure it's not disabled)
sed -i '/\[plugins."io.containerd.grpc.v1.cri"\]/,/^$/s/disabled = true/disabled = false/' /etc/containerd/config.toml

# Start and enable containerd
echo "9. Starting containerd service..."
systemctl daemon-reload
systemctl enable containerd
systemctl restart containerd

# Verify installation
echo "10. Verifying installation..."
sleep 2
if systemctl is-active --quiet containerd; then
    echo "✓ containerd service is running"
else
    echo "✗ containerd service failed to start"
    systemctl status containerd
    exit 1
fi

# Check version
INSTALLED_VERSION=$(containerd --version | awk '{print $3}')
if [[ "$INSTALLED_VERSION" == "v${CONTAINERD_VERSION}" ]]; then
    echo "✓ containerd v${CONTAINERD_VERSION} installed successfully"
else
    echo "✗ Version mismatch! Expected v${CONTAINERD_VERSION}, got ${INSTALLED_VERSION}"
    exit 1
fi

# Test CRI functionality
echo "11. Testing CRI functionality..."
if crictl --version &> /dev/null; then
    echo "crictl already installed"
else
    echo "Installing crictl..."
    CRICTL_VERSION="v1.34.0"
    wget -q https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
    tar -C /usr/local/bin -xzf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
fi

# Configure crictl
cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

# Test crictl
crictl info > /dev/null 2>&1 && echo "✓ CRI endpoint is working" || echo "✗ CRI endpoint test failed"

# Clean up
echo "12. Cleaning up temporary files..."
rm -f /tmp/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz
rm -f /tmp/runc.amd64
rm -f /tmp/cni-plugins-linux-amd64-v${CNI_VERSION}.tgz
rm -f /tmp/crictl-*.tar.gz

echo ""
echo "=== containerd v${CONTAINERD_VERSION} Installation Complete ==="
echo "Runtime endpoint: unix:///run/containerd/containerd.sock"
echo "Cgroup driver: systemd"
echo "CNI plugins: /opt/cni/bin/"
echo "Config file: /etc/containerd/config.toml"
