#!/bin/bash
# Check current state of system prerequisites on all nodes

NODES=(50 51 52 53 54 55 56 57 58)
LOG_FILE="steps/02-prerequisites/discovery-02.log"

echo "" >> $LOG_FILE
echo "=== System Prerequisites Discovery ===" >> $LOG_FILE
echo "Timestamp: $(date)" >> $LOG_FILE
echo "" >> $LOG_FILE

for node in "${NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    echo "Checking $NODE_NAME ($IP)..." | tee -a $LOG_FILE
    echo "------------------------" >> $LOG_FILE

    # Check swap status
    echo "  Swap status:" >> $LOG_FILE
    ssh root@$IP "swapon --show" >> $LOG_FILE 2>&1 || echo "    No swap active" >> $LOG_FILE
    ssh root@$IP "free -m | grep Swap" >> $LOG_FILE 2>&1

    # Check if swap entries in fstab
    echo "  Swap in fstab:" >> $LOG_FILE
    ssh root@$IP "grep -E '^[^#].*swap' /etc/fstab" >> $LOG_FILE 2>&1 || echo "    No swap entries" >> $LOG_FILE

    # Check kernel modules
    echo "  Kernel modules:" >> $LOG_FILE
    for module in br_netfilter overlay ip_vs ip_vs_rr ip_vs_wrr ip_vs_sh; do
        ssh root@$IP "lsmod | grep -q $module && echo '    $module: loaded' || echo '    $module: not loaded'" >> $LOG_FILE 2>&1
    done

    # Check sysctl settings
    echo "  Sysctl settings:" >> $LOG_FILE
    ssh root@$IP "sysctl net.ipv4.ip_forward" >> $LOG_FILE 2>&1
    ssh root@$IP "sysctl net.bridge.bridge-nf-call-iptables 2>/dev/null || echo '    net.bridge.bridge-nf-call-iptables: not set'" >> $LOG_FILE 2>&1
    ssh root@$IP "sysctl net.bridge.bridge-nf-call-ip6tables 2>/dev/null || echo '    net.bridge.bridge-nf-call-ip6tables: not set'" >> $LOG_FILE 2>&1

    # Check firewall status
    echo "  Firewall status:" >> $LOG_FILE
    ssh root@$IP "systemctl is-active ufw 2>/dev/null || echo '    ufw: inactive'" >> $LOG_FILE 2>&1
    ssh root@$IP "systemctl is-active firewalld 2>/dev/null || echo '    firewalld: inactive'" >> $LOG_FILE 2>&1

    # Check time sync
    echo "  Time sync:" >> $LOG_FILE
    ssh root@$IP "systemctl is-active systemd-timesyncd 2>/dev/null || echo '    systemd-timesyncd: inactive'" >> $LOG_FILE 2>&1
    ssh root@$IP "systemctl is-active chrony 2>/dev/null || echo '    chrony: inactive'" >> $LOG_FILE 2>&1
    ssh root@$IP "timedatectl status | grep 'System clock synchronized'" >> $LOG_FILE 2>&1

    # Check systemd cgroup
    echo "  Systemd cgroup:" >> $LOG_FILE
    ssh root@$IP "systemctl show --property=DefaultCPUAccounting,DefaultMemoryAccounting,DefaultTasksAccounting" >> $LOG_FILE 2>&1

    echo "" >> $LOG_FILE
done

echo "Discovery complete" >> $LOG_FILE
