#!/bin/bash
# ABOUTME: Install Kubernetes v1.33.4 exactly as specified
# ABOUTME: Installs kubeadm, kubelet, kubectl and configures kubelet

set -e

KUBERNETES_VERSION="1.33.4"

echo "=== Installing Kubernetes v${KUBERNETES_VERSION} packages ==="

# Discovery phase - check current state
echo "1. Checking current Kubernetes installation..."
if command -v kubeadm &> /dev/null; then
    echo "WARNING: kubeadm already installed: $(kubeadm version -o short)"
    echo "Proceeding with installation of v${KUBERNETES_VERSION}..."
fi

# Install prerequisites
echo "2. Installing prerequisites..."
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

# Add Kubernetes signing key
echo "3. Adding Kubernetes signing key..."
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes v1.33 repository
echo "4. Adding Kubernetes v1.33 repository..."
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' > /etc/apt/sources.list.d/kubernetes.list

# Update package index
echo "5. Updating package index..."
apt-get update

# Check available versions
echo "6. Checking available Kubernetes versions..."
apt-cache madison kubeadm | grep ${KUBERNETES_VERSION} || {
    echo "ERROR: Version ${KUBERNETES_VERSION} not found in repository!"
    echo "Available versions:"
    apt-cache madison kubeadm | head -10
    exit 1
}

# Install specific version
echo "7. Installing kubeadm, kubelet, kubectl v${KUBERNETES_VERSION}..."
apt-get install -y kubelet=${KUBERNETES_VERSION}-* kubeadm=${KUBERNETES_VERSION}-* kubectl=${KUBERNETES_VERSION}-*

# Hold packages to prevent auto-updates
echo "8. Holding packages to prevent auto-updates..."
apt-mark hold kubelet kubeadm kubectl

# Configure kubelet with systemd cgroup driver
echo "9. Configuring kubelet for systemd cgroup driver..."
mkdir -p /var/lib/kubelet
cat > /var/lib/kubelet/config.yaml <<EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
containerRuntimeEndpoint: unix:///run/containerd/containerd.sock
EOF

# Create kubelet extra args for systemd
mkdir -p /etc/systemd/system/kubelet.service.d
cat > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf <<EOF
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
Environment="KUBELET_EXTRA_ARGS=--cgroup-driver=systemd"
ExecStart=
ExecStart=/usr/bin/kubelet \$KUBELET_KUBECONFIG_ARGS \$KUBELET_CONFIG_ARGS \$KUBELET_EXTRA_ARGS
EOF

# Enable kubelet service
echo "10. Enabling kubelet service..."
systemctl daemon-reload
systemctl enable kubelet

# Configure kubectl bash completion
echo "11. Setting up kubectl bash completion..."
kubectl completion bash > /etc/bash_completion.d/kubectl
echo 'source <(kubectl completion bash)' >> /root/.bashrc
echo 'alias k=kubectl' >> /root/.bashrc
echo 'complete -F __start_kubectl k' >> /root/.bashrc

# Verify installation
echo "12. Verifying installation..."
echo "Checking versions..."
KUBEADM_VERSION=$(kubeadm version -o short)
KUBELET_VERSION=$(kubelet --version | awk '{print $2}')
KUBECTL_VERSION=$(kubectl version --client 2>&1 | grep "Client Version" | awk '{print $3}')

echo "kubeadm: ${KUBEADM_VERSION}"
echo "kubelet: ${KUBELET_VERSION}"
echo "kubectl: ${KUBECTL_VERSION}"

# Verify all are v1.33.4
if [[ "${KUBEADM_VERSION}" == "v${KUBERNETES_VERSION}" ]]; then
    echo "✓ kubeadm v${KUBERNETES_VERSION} installed successfully"
else
    echo "✗ kubeadm version mismatch! Expected v${KUBERNETES_VERSION}, got ${KUBEADM_VERSION}"
    exit 1
fi

if [[ "${KUBELET_VERSION}" == "v${KUBERNETES_VERSION}" ]]; then
    echo "✓ kubelet v${KUBERNETES_VERSION} installed successfully"
else
    echo "✗ kubelet version mismatch! Expected v${KUBERNETES_VERSION}, got ${KUBELET_VERSION}"
    exit 1
fi

if [[ "${KUBECTL_VERSION}" == "v${KUBERNETES_VERSION}" ]]; then
    echo "✓ kubectl v${KUBERNETES_VERSION} installed successfully"
else
    echo "✗ kubectl version mismatch! Expected v${KUBERNETES_VERSION}, got ${KUBECTL_VERSION}"
    exit 1
fi

echo ""
echo "=== Kubernetes v${KUBERNETES_VERSION} Installation Complete ==="
echo "Components installed:"
echo "- kubeadm v${KUBERNETES_VERSION}"
echo "- kubelet v${KUBERNETES_VERSION} (configured with systemd cgroup driver)"
echo "- kubectl v${KUBERNETES_VERSION}"
echo ""
echo "Packages held to prevent auto-updates"
echo "Kubelet service enabled (will start after kubeadm init/join)"
