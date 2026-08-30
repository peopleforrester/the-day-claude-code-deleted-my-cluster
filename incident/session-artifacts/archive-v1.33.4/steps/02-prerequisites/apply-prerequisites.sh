#!/bin/bash
# Apply system prerequisites for Kubernetes on all nodes

NODES=(50 51 52 53 54 55 56 57 58)
LOG_FILE="steps/02-prerequisites/commands-02.log"

echo "Applying System Prerequisites for Kubernetes" | tee $LOG_FILE
echo "Started: $(date)" | tee -a $LOG_FILE
echo "=============================================" | tee -a $LOG_FILE

# Function to apply prerequisites on a single node
apply_node_prerequisites() {
    local ip="192.168.0.$1"
    local name="k8s$(printf '%02d' $(($1 - 49)))"

    echo "" | tee -a $LOG_FILE
    echo "Configuring $name ($ip)..." | tee -a $LOG_FILE

    # 1. Disable swap
    echo "  Disabling swap..." | tee -a $LOG_FILE
    ssh root@$ip "swapoff -a" >> $LOG_FILE 2>&1
    ssh root@$ip "sed -i '/swap/s/^/#/' /etc/fstab" >> $LOG_FILE 2>&1
    ssh root@$ip "rm -f /swap.img" >> $LOG_FILE 2>&1

    # 2. Load kernel modules
    echo "  Loading kernel modules..." | tee -a $LOG_FILE
    ssh root@$ip "modprobe br_netfilter" >> $LOG_FILE 2>&1
    ssh root@$ip "modprobe overlay" >> $LOG_FILE 2>&1
    ssh root@$ip "modprobe ip_vs" >> $LOG_FILE 2>&1
    ssh root@$ip "modprobe ip_vs_rr" >> $LOG_FILE 2>&1
    ssh root@$ip "modprobe ip_vs_wrr" >> $LOG_FILE 2>&1
    ssh root@$ip "modprobe ip_vs_sh" >> $LOG_FILE 2>&1
    ssh root@$ip "modprobe nf_conntrack" >> $LOG_FILE 2>&1

    # 3. Make modules persistent
    echo "  Making kernel modules persistent..." | tee -a $LOG_FILE
    ssh root@$ip "cat > /etc/modules-load.d/kubernetes.conf << EOF
br_netfilter
overlay
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF" >> $LOG_FILE 2>&1

    # 4. Configure sysctl for Kubernetes
    echo "  Configuring sysctl..." | tee -a $LOG_FILE
    ssh root@$ip "cat > /etc/sysctl.d/99-kubernetes.conf << EOF
# Kubernetes required settings
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Optional: Performance tuning
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_notsent_lowat = 16384

# Optional: Increase limits
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 524288
EOF" >> $LOG_FILE 2>&1

    # Apply sysctl settings
    ssh root@$ip "sysctl --system" >> $LOG_FILE 2>&1

    # 5. Configure firewall rules for Kubernetes
    echo "  Configuring firewall..." | tee -a $LOG_FILE

    # Determine if this is a control plane or worker node
    if [ $1 -le 52 ]; then
        # Control plane node - open required ports
        echo "    Opening control plane ports..." | tee -a $LOG_FILE
        ssh root@$ip "
            # API server
            iptables -A INPUT -p tcp --dport 6443 -j ACCEPT
            # etcd
            iptables -A INPUT -p tcp --dport 2379:2380 -j ACCEPT
            # kubelet API
            iptables -A INPUT -p tcp --dport 10250 -j ACCEPT
            # kube-scheduler
            iptables -A INPUT -p tcp --dport 10259 -j ACCEPT
            # kube-controller-manager
            iptables -A INPUT -p tcp --dport 10257 -j ACCEPT
            # NodePort range
            iptables -A INPUT -p tcp --dport 30000:32767 -j ACCEPT
        " >> $LOG_FILE 2>&1
    else
        # Worker node - open required ports
        echo "    Opening worker node ports..." | tee -a $LOG_FILE
        ssh root@$ip "
            # kubelet API
            iptables -A INPUT -p tcp --dport 10250 -j ACCEPT
            # NodePort range
            iptables -A INPUT -p tcp --dport 30000:32767 -j ACCEPT
        " >> $LOG_FILE 2>&1
    fi

    # Save iptables rules
    ssh root@$ip "iptables-save > /etc/iptables/rules.v4 2>/dev/null || true" >> $LOG_FILE 2>&1

    # 6. Install and configure chrony for better time sync
    echo "  Installing chrony..." | tee -a $LOG_FILE
    ssh root@$ip "apt-get install -y chrony" >> $LOG_FILE 2>&1
    ssh root@$ip "systemctl enable --now chrony" >> $LOG_FILE 2>&1

    # 7. Disable systemd-resolved if running (can interfere with CoreDNS)
    echo "  Configuring DNS..." | tee -a $LOG_FILE
    ssh root@$ip "systemctl disable --now systemd-resolved 2>/dev/null || true" >> $LOG_FILE 2>&1
    ssh root@$ip "rm -f /etc/resolv.conf" >> $LOG_FILE 2>&1
    ssh root@$ip "echo 'nameserver 8.8.8.8' > /etc/resolv.conf" >> $LOG_FILE 2>&1
    ssh root@$ip "echo 'nameserver 8.8.4.4' >> /etc/resolv.conf" >> $LOG_FILE 2>&1

    echo "  ✓ Prerequisites applied to $name" | tee -a $LOG_FILE
}

# Apply prerequisites to all nodes
for node in "${NODES[@]}"; do
    apply_node_prerequisites $node
done

echo "" | tee -a $LOG_FILE
echo "=============================================" | tee -a $LOG_FILE
echo "Prerequisites application complete!" | tee -a $LOG_FILE
echo "Finished: $(date)" | tee -a $LOG_FILE
