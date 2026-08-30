#!/bin/bash
# ABOUTME: Install Cilium CNI latest stable version
# ABOUTME: Makes cluster networking functional

set -euo pipefail

LOG_DIR="logs/07-cilium"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
INSTALL_LOG="$LOG_DIR/install-$TIMESTAMP.log"

echo "Installing Cilium CNI latest stable" | tee "$INSTALL_LOG"
echo "====================================" | tee -a "$INSTALL_LOG"

# Install Cilium CLI
echo "Installing Cilium CLI..." | tee -a "$INSTALL_LOG"
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum} 2>&1 | tee -a "$INSTALL_LOG"
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum 2>&1 | tee -a "$INSTALL_LOG"
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin 2>&1 | tee -a "$INSTALL_LOG"
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
echo "✓ Cilium CLI installed: $(cilium version --client)" | tee -a "$INSTALL_LOG"

# Install Cilium
echo "Installing Cilium..." | tee -a "$INSTALL_LOG"
cilium install --version v1.16.5 2>&1 | tee -a "$INSTALL_LOG"

# Wait for Cilium to be ready
echo "Waiting for Cilium to be ready..." | tee -a "$INSTALL_LOG"
cilium status --wait 2>&1 | tee -a "$INSTALL_LOG"

# Verify installation
echo "" | tee -a "$INSTALL_LOG"
echo "Verifying Cilium installation..." | tee -a "$INSTALL_LOG"
kubectl get pods -n kube-system -l k8s-app=cilium 2>&1 | tee -a "$INSTALL_LOG"

# Check node status
echo "" | tee -a "$INSTALL_LOG"
echo "Checking node status..." | tee -a "$INSTALL_LOG"
kubectl get nodes 2>&1 | tee -a "$INSTALL_LOG"

echo "" | tee -a "$INSTALL_LOG"
echo "====================================" | tee -a "$INSTALL_LOG"
echo "Cilium CNI installed successfully!" | tee -a "$INSTALL_LOG"