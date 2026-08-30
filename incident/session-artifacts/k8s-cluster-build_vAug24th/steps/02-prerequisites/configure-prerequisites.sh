#!/bin/bash
# ABOUTME: System prerequisites configuration for Kubernetes
# ABOUTME: Configures kernel modules, sysctl, and system settings

set -e

echo "=== Configuring System Prerequisites for Kubernetes ==="

# Disable swap permanently
echo "1. Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Load required kernel modules
echo "2. Loading kernel modules..."
cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF

# Load modules immediately
modprobe overlay
modprobe br_netfilter
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe nf_conntrack

# Configure sysctl for Kubernetes networking
echo "3. Configuring sysctl..."
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
net.ipv4.conf.all.forwarding        = 1
net.ipv6.conf.all.forwarding        = 1
EOF

# Apply sysctl settings
sysctl --system

# Configure firewall rules for Kubernetes
echo "4. Configuring firewall..."

# Check if ufw is active
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    echo "UFW is active, configuring rules..."

    # Control plane nodes
    if [[ $(hostname) =~ ^master[0-9]+$ ]]; then
        ufw allow 6443/tcp comment 'Kubernetes API server'
        ufw allow 2379:2380/tcp comment 'etcd server client API'
        ufw allow 10250/tcp comment 'Kubelet API'
        ufw allow 10259/tcp comment 'kube-scheduler'
        ufw allow 10257/tcp comment 'kube-controller-manager'
    fi

    # All nodes
    ufw allow 10250/tcp comment 'Kubelet API'
    ufw allow 30000:32767/tcp comment 'NodePort Services'
    ufw allow 179/tcp comment 'Calico BGP'
    ufw allow 4789/udp comment 'Calico VXLAN'
    ufw allow 5473/tcp comment 'Calico Typha'

    ufw reload
else
    echo "UFW not active or not installed, skipping firewall configuration"
fi

# Install and configure chrony for time synchronization
echo "5. Configuring time synchronization..."
apt-get update
apt-get install -y chrony
systemctl enable chrony
systemctl restart chrony

# Verify systemd as cgroup manager
echo "6. Verifying systemd cgroup configuration..."
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    echo "Cgroup v2 detected (expected for Ubuntu 24.04)"
    stat -fc %T /sys/fs/cgroup
else
    echo "WARNING: Cgroup v2 not detected!"
fi

echo "=== System Prerequisites Configuration Complete ==="
echo ""
echo "Verification:"
echo "- Swap: $(swapon --show | wc -l) entries (should be 0)"
echo "- IP forwarding: $(sysctl net.ipv4.ip_forward | awk '{print $3}')"
echo "- br_netfilter loaded: $(lsmod | grep -c br_netfilter || echo 0)"
echo "- Time sync: $(chronyc tracking | grep "Leap status" | awk '{print $4}')"
