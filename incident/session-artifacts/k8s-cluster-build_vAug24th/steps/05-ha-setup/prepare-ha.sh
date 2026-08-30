#!/bin/bash
# ABOUTME: Prepare HA infrastructure on control plane nodes
# ABOUTME: Sets up kube-vip, encryption, and audit configurations

set -e

echo "=== Preparing HA Infrastructure ==="

# Check if this is a control plane node
HOSTNAME=$(hostname)
if [[ ! "$HOSTNAME" =~ ^master[0-9]+$ ]]; then
    echo "ERROR: This script should only run on control plane nodes"
    exit 1
fi

# Setup directories
echo "1. Creating required directories..."
mkdir -p /etc/kubernetes/pki
mkdir -p /etc/kubernetes/manifests
mkdir -p /var/log/kubernetes

# Generate encryption key if not exists
echo "2. Setting up etcd encryption..."
if [ ! -f /etc/kubernetes/pki/encryption-config.yaml ]; then
    # Generate a 32 byte random key and base64 encode it
    ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
    cat > /etc/kubernetes/pki/encryption-config.yaml <<EOF
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
      - configmaps
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
    chmod 600 /etc/kubernetes/pki/encryption-config.yaml
    echo "   Encryption configuration created"
else
    echo "   Encryption configuration already exists"
fi

# Setup audit policy
echo "3. Setting up audit policy..."
if [ ! -f /etc/kubernetes/audit-policy.yaml ]; then
    cp /tmp/audit-policy.yaml /etc/kubernetes/audit-policy.yaml
    echo "   Audit policy configured"
else
    echo "   Audit policy already exists"
fi

# Setup kube-vip
echo "4. Setting up kube-vip..."
if [ -f /tmp/setup-kube-vip.sh ]; then
    bash /tmp/setup-kube-vip.sh
else
    echo "   ERROR: kube-vip setup script not found"
    exit 1
fi

# Create Pod Security Standards configuration
echo "5. Setting up Pod Security Standards..."
cat > /etc/kubernetes/psa-config.yaml <<EOF
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: PodSecurity
  configuration:
    apiVersion: pod-security.admission.config.k8s.io/v1
    kind: PodSecurityConfiguration
    defaults:
      enforce: "baseline"
      enforce-version: "latest"
      audit: "restricted"
      audit-version: "latest"
      warn: "restricted"
      warn-version: "latest"
    exemptions:
      usernames: []
      runtimeClasses: []
      namespaces: ["kube-system", "kube-public", "kube-node-lease"]
EOF

echo ""
echo "=== HA Infrastructure Preparation Complete ==="
echo "Configuration files created:"
echo "  - /etc/kubernetes/pki/encryption-config.yaml"
echo "  - /etc/kubernetes/audit-policy.yaml"
echo "  - /etc/kubernetes/manifests/kube-vip.yaml"
echo "  - /etc/kubernetes/psa-config.yaml"
echo ""
echo "Ready for kubeadm init on first master"
