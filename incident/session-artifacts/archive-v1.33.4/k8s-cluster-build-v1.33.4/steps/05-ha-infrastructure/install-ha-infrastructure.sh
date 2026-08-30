#!/bin/bash
# Install and configure HAProxy and Keepalived for HA control plane
# VIP: 192.168.0.200

CONTROL_NODES=(50 51 52)
VIP="192.168.0.200"
LOG_FILE="steps/05-ha-infrastructure/install-05.log"

echo "===================================" | tee -a $LOG_FILE
echo "Installing HA Infrastructure" | tee -a $LOG_FILE
echo "VIP: $VIP" | tee -a $LOG_FILE
echo "Started: $(date)" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Function to install HAProxy and Keepalived on a node
install_ha_on_node() {
    local ip=$1
    local node_name=$2
    local priority=$3  # Keepalived priority (higher = preferred master)

    echo "Installing HA components on $node_name ($ip)..." | tee -a $LOG_FILE

    # Step 1: Install HAProxy and Keepalived
    echo "  Installing HAProxy and Keepalived..." | tee -a $LOG_FILE
    ssh root@$ip "apt-get update && apt-get install -y haproxy keepalived" >> $LOG_FILE 2>&1

    if [ $? -ne 0 ]; then
        echo "    ERROR: Installation failed!" | tee -a $LOG_FILE
        return 1
    fi

    # Step 2: Configure HAProxy
    echo "  Configuring HAProxy..." | tee -a $LOG_FILE
    ssh root@$ip "cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

# Kubernetes API Server Frontend
frontend kubernetes-frontend
    bind *:8443
    mode tcp
    option tcplog
    default_backend kubernetes-backend

# Kubernetes API Server Backend
backend kubernetes-backend
    mode tcp
    option tcp-check
    balance roundrobin
    server k8s01 192.168.0.50:6443 check fall 3 rise 2
    server k8s02 192.168.0.51:6443 check fall 3 rise 2
    server k8s03 192.168.0.52:6443 check fall 3 rise 2

# Stats page
listen stats
    bind *:8080
    stats enable
    stats uri /stats
    stats refresh 30s
    stats show-node
    stats auth admin:admin123
EOF" >> $LOG_FILE 2>&1

    # Step 3: Get network interface name
    echo "  Detecting network interface..." | tee -a $LOG_FILE
    INTERFACE=$(ssh root@$ip "ip route | grep default | awk '{print \$5}' | head -1" 2>/dev/null)
    echo "    Interface: $INTERFACE" | tee -a $LOG_FILE

    # Step 4: Configure Keepalived
    echo "  Configuring Keepalived (priority: $priority)..." | tee -a $LOG_FILE

    # Determine state based on priority
    if [ "$priority" = "101" ]; then
        STATE="MASTER"
    else
        STATE="BACKUP"
    fi

    ssh root@$ip "cat > /etc/keepalived/keepalived.conf << EOF
global_defs {
    router_id LVS_K8S
    enable_script_security
}

vrrp_script check_haproxy {
    script '/usr/bin/killall -0 haproxy'
    interval 2
    weight 2
}

vrrp_instance VI_1 {
    state $STATE
    interface $INTERFACE
    virtual_router_id 51
    priority $priority
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass k8s_ha_pass
    }
    virtual_ipaddress {
        $VIP/24 dev $INTERFACE
    }
    track_script {
        check_haproxy
    }
}
EOF" >> $LOG_FILE 2>&1

    # Step 5: Configure firewall for HAProxy stats and load balancer port
    echo "  Configuring firewall rules..." | tee -a $LOG_FILE
    ssh root@$ip "iptables -A INPUT -p tcp --dport 8443 -j ACCEPT" >> $LOG_FILE 2>&1
    ssh root@$ip "iptables -A INPUT -p tcp --dport 8080 -j ACCEPT" >> $LOG_FILE 2>&1
    ssh root@$ip "iptables -A INPUT -p vrrp -j ACCEPT" >> $LOG_FILE 2>&1
    ssh root@$ip "iptables-save > /etc/iptables/rules.v4" >> $LOG_FILE 2>&1

    # Step 6: Enable IP forwarding for Keepalived
    echo "  Enabling IP forwarding for VIP..." | tee -a $LOG_FILE
    ssh root@$ip "echo 'net.ipv4.ip_nonlocal_bind = 1' >> /etc/sysctl.d/99-kubernetes.conf" >> $LOG_FILE 2>&1
    ssh root@$ip "sysctl -p /etc/sysctl.d/99-kubernetes.conf" >> $LOG_FILE 2>&1

    # Step 7: Start and enable services
    echo "  Starting services..." | tee -a $LOG_FILE
    ssh root@$ip "systemctl restart haproxy" >> $LOG_FILE 2>&1
    ssh root@$ip "systemctl enable haproxy" >> $LOG_FILE 2>&1
    ssh root@$ip "systemctl restart keepalived" >> $LOG_FILE 2>&1
    ssh root@$ip "systemctl enable keepalived" >> $LOG_FILE 2>&1

    # Verify services
    echo "  Verifying services..." | tee -a $LOG_FILE
    HAPROXY_STATUS=$(ssh root@$ip "systemctl is-active haproxy" 2>/dev/null)
    KEEPALIVED_STATUS=$(ssh root@$ip "systemctl is-active keepalived" 2>/dev/null)

    echo "    HAProxy: $HAPROXY_STATUS" | tee -a $LOG_FILE
    echo "    Keepalived: $KEEPALIVED_STATUS" | tee -a $LOG_FILE

    if [ "$HAPROXY_STATUS" = "active" ] && [ "$KEEPALIVED_STATUS" = "active" ]; then
        echo "  ✓ HA components installed successfully on $node_name" | tee -a $LOG_FILE
        return 0
    else
        echo "  ✗ Service startup failed on $node_name" | tee -a $LOG_FILE
        return 1
    fi
}

# Install on all control plane nodes with different priorities
PRIORITIES=(101 100 99)  # k8s01 will be preferred master
FAILED_NODES=""

for i in "${!CONTROL_NODES[@]}"; do
    node="${CONTROL_NODES[$i]}"
    priority="${PRIORITIES[$i]}"
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    if ! install_ha_on_node $IP $NODE_NAME $priority; then
        FAILED_NODES="$FAILED_NODES $NODE_NAME"
    fi
    echo "" | tee -a $LOG_FILE
done

# Wait for services to stabilize
echo "Waiting for services to stabilize..." | tee -a $LOG_FILE
sleep 5

# Check VIP assignment
echo "Checking VIP assignment..." | tee -a $LOG_FILE
VIP_HOLDER=""
for node in "${CONTROL_NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    HAS_VIP=$(ssh root@$IP "ip addr show | grep -q '$VIP' && echo 'yes' || echo 'no'" 2>/dev/null)
    if [ "$HAS_VIP" = "yes" ]; then
        VIP_HOLDER=$NODE_NAME
        echo "  ✓ VIP $VIP is active on $NODE_NAME" | tee -a $LOG_FILE
        break
    fi
done

if [ -z "$VIP_HOLDER" ]; then
    echo "  ✗ VIP is not active on any node!" | tee -a $LOG_FILE
    FAILED_NODES="$FAILED_NODES VIP"
fi

# Test VIP connectivity
echo "" | tee -a $LOG_FILE
echo "Testing VIP connectivity..." | tee -a $LOG_FILE
ping -c 3 -W 1 $VIP &>/dev/null
if [ $? -eq 0 ]; then
    echo "  ✓ VIP $VIP is responding to ping" | tee -a $LOG_FILE
else
    echo "  ✗ VIP $VIP is not responding" | tee -a $LOG_FILE
    FAILED_NODES="$FAILED_NODES VIP-PING"
fi

# Summary
echo "" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE
echo "Installation Summary" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE

if [ -z "$FAILED_NODES" ]; then
    echo "✓ HA Infrastructure successfully installed" | tee -a $LOG_FILE
    echo "  VIP: $VIP (active on $VIP_HOLDER)" | tee -a $LOG_FILE
    echo "  HAProxy: Load balancing on port 8443" | tee -a $LOG_FILE
    echo "  HAProxy Stats: http://<node-ip>:8080/stats (admin/admin123)" | tee -a $LOG_FILE
else
    echo "✗ Failed components:$FAILED_NODES" | tee -a $LOG_FILE
    echo "Please check the log file for details" | tee -a $LOG_FILE
    exit 1
fi

echo "" | tee -a $LOG_FILE
echo "Completed: $(date)" | tee -a $LOG_FILE
