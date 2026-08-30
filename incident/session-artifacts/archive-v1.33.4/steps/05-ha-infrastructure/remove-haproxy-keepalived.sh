#!/bin/bash
# Remove the wrongly installed HAProxy and Keepalived

CONTROL_NODES=(50 51 52)
LOG_FILE="steps/05-ha-infrastructure/removal.log"

echo "===================================" | tee $LOG_FILE
echo "Removing HAProxy and Keepalived" | tee -a $LOG_FILE
echo "Timestamp: $(date)" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

for node in "${CONTROL_NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    echo "Cleaning $NODE_NAME ($IP)..." | tee -a $LOG_FILE

    # Stop services
    echo "  Stopping services..." | tee -a $LOG_FILE
    ssh root@$IP "systemctl stop haproxy keepalived" 2>/dev/null
    ssh root@$IP "systemctl disable haproxy keepalived" 2>/dev/null

    # Remove packages
    echo "  Removing packages..." | tee -a $LOG_FILE
    ssh root@$IP "apt-get remove -y haproxy keepalived" >> $LOG_FILE 2>&1
    ssh root@$IP "apt-get autoremove -y" >> $LOG_FILE 2>&1

    # Remove configuration files
    echo "  Removing configuration files..." | tee -a $LOG_FILE
    ssh root@$IP "rm -rf /etc/haproxy /etc/keepalived" 2>/dev/null

    # Remove firewall rules added for HAProxy
    echo "  Cleaning firewall rules..." | tee -a $LOG_FILE
    ssh root@$IP "iptables -D INPUT -p tcp --dport 8443 -j ACCEPT" 2>/dev/null
    ssh root@$IP "iptables -D INPUT -p tcp --dport 8080 -j ACCEPT" 2>/dev/null
    ssh root@$IP "iptables -D INPUT -p vrrp -j ACCEPT" 2>/dev/null
    ssh root@$IP "iptables-save > /etc/iptables/rules.v4" 2>/dev/null

    # Remove sysctl setting for nonlocal bind
    echo "  Cleaning sysctl settings..." | tee -a $LOG_FILE
    ssh root@$IP "sed -i '/net.ipv4.ip_nonlocal_bind/d' /etc/sysctl.d/99-kubernetes.conf" 2>/dev/null
    ssh root@$IP "sysctl -p /etc/sysctl.d/99-kubernetes.conf" >> $LOG_FILE 2>&1

    echo "  ✓ Cleaned $NODE_NAME" | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
done

echo "Removal complete" | tee -a $LOG_FILE
