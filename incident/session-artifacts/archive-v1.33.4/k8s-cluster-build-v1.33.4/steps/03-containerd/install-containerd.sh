#!/bin/bash
# Install containerd v2.1.4 exactly as specified

NODES=(50 51 52 53 54 55 56 57 58)
CONTAINERD_VERSION="2.1.4"
LOG_FILE="steps/03-containerd/commands-03.log"

echo "Installing containerd v${CONTAINERD_VERSION}" | tee $LOG_FILE
echo "Started: $(date)" | tee -a $LOG_FILE
echo "==========================================" | tee -a $LOG_FILE

# Function to install containerd on a single node
install_containerd_node() {
    local ip="192.168.0.$1"
    local name="k8s$(printf '%02d' $(($1 - 49)))"

    echo "" | tee -a $LOG_FILE
    echo "Installing on $name ($ip)..." | tee -a $LOG_FILE

    # Install dependencies
    echo "  Installing dependencies..." | tee -a $LOG_FILE
    ssh root@$ip "apt-get update && apt-get install -y ca-certificates curl gnupg" >> $LOG_FILE 2>&1

    # Download containerd v2.1.4 binary
    echo "  Downloading containerd v${CONTAINERD_VERSION}..." | tee -a $LOG_FILE
    ssh root@$ip "
        curl -L https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz -o /tmp/containerd.tar.gz
    " >> $LOG_FILE 2>&1

    # Extract containerd
    echo "  Extracting containerd..." | tee -a $LOG_FILE
    ssh root@$ip "
        tar Cxzvf /usr/local /tmp/containerd.tar.gz
    " >> $LOG_FILE 2>&1

    # Download and install runc
    echo "  Installing runc..." | tee -a $LOG_FILE
    ssh root@$ip "
        curl -L https://github.com/opencontainers/runc/releases/download/v1.2.3/runc.amd64 -o /usr/local/sbin/runc
        chmod 755 /usr/local/sbin/runc
    " >> $LOG_FILE 2>&1

    # Download and install CNI plugins
    echo "  Installing CNI plugins..." | tee -a $LOG_FILE
    ssh root@$ip "
        mkdir -p /opt/cni/bin
        curl -L https://github.com/containernetworking/plugins/releases/download/v1.6.1/cni-plugins-linux-amd64-v1.6.1.tgz -o /tmp/cni-plugins.tgz
        tar Cxzvf /opt/cni/bin /tmp/cni-plugins.tgz
    " >> $LOG_FILE 2>&1

    # Create containerd service file
    echo "  Creating systemd service..." | tee -a $LOG_FILE
    ssh root@$ip "
        curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /etc/systemd/system/containerd.service
    " >> $LOG_FILE 2>&1

    # Create containerd configuration directory
    echo "  Creating configuration..." | tee -a $LOG_FILE
    ssh root@$ip "
        mkdir -p /etc/containerd
        containerd config default > /etc/containerd/config.toml
    " >> $LOG_FILE 2>&1

    # Configure systemd cgroup driver
    echo "  Configuring systemd cgroup driver..." | tee -a $LOG_FILE
    ssh root@$ip "
        sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

        # Also ensure the runtime uses systemd cgroup
        sed -i '/\\[plugins.\"io.containerd.grpc.v1.cri\".containerd.runtimes.runc.options\\]/a\\            SystemdCgroup = true' /etc/containerd/config.toml

        # Set the cgroup driver explicitly
        sed -i 's/cgroup_driver = \"cgroupfs\"/cgroup_driver = \"systemd\"/' /etc/containerd/config.toml 2>/dev/null || true
    " >> $LOG_FILE 2>&1

    # Enable metrics
    echo "  Enabling metrics endpoint..." | tee -a $LOG_FILE
    ssh root@$ip "
        # Enable metrics in config
        sed -i 's/^\\(\\s*\\)address = \"\"$/\\1address = \"127.0.0.1:1338\"/' /etc/containerd/config.toml
    " >> $LOG_FILE 2>&1

    # Configure sandbox image for Kubernetes
    echo "  Configuring sandbox image..." | tee -a $LOG_FILE
    ssh root@$ip "
        sed -i 's|sandbox_image = \"registry.k8s.io/pause:.*\"|sandbox_image = \"registry.k8s.io/pause:3.10\"|' /etc/containerd/config.toml
    " >> $LOG_FILE 2>&1

    # Start and enable containerd
    echo "  Starting containerd service..." | tee -a $LOG_FILE
    ssh root@$ip "
        systemctl daemon-reload
        systemctl enable --now containerd
        systemctl status containerd --no-pager
    " >> $LOG_FILE 2>&1

    # Install crictl for testing
    echo "  Installing crictl..." | tee -a $LOG_FILE
    ssh root@$ip "
        curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.31.1/crictl-v1.31.1-linux-amd64.tar.gz -o /tmp/crictl.tar.gz
        tar zxvf /tmp/crictl.tar.gz -C /usr/local/bin

        # Configure crictl
        cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
    " >> $LOG_FILE 2>&1

    # Verify installation
    echo "  Verifying installation..." | tee -a $LOG_FILE
    VERSION_CHECK=$(ssh root@$ip "containerd --version" 2>/dev/null)
    echo "    Installed: $VERSION_CHECK" | tee -a $LOG_FILE

    if [[ "$VERSION_CHECK" == *"$CONTAINERD_VERSION"* ]]; then
        echo "  ✓ Containerd v${CONTAINERD_VERSION} installed on $name" | tee -a $LOG_FILE
    else
        echo "  ✗ Version mismatch on $name: $VERSION_CHECK" | tee -a $LOG_FILE
    fi
}

# Install on all nodes
for node in "${NODES[@]}"; do
    install_containerd_node $node
done

echo "" | tee -a $LOG_FILE
echo "==========================================" | tee -a $LOG_FILE
echo "Containerd installation complete!" | tee -a $LOG_FILE
echo "Finished: $(date)" | tee -a $LOG_FILE
