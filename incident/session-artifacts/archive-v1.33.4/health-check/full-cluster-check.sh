#!/bin/bash
# Complete cluster health check

echo "========================================="
echo "COMPLETE CLUSTER HEALTH CHECK"
echo "Date: $(date)"
echo "========================================="
echo

# Function to check each node
check_node_full() {
    local NODE=$1
    local IP=$2

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$NODE ($IP)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Connectivity
    echo -n "  Connectivity: "
    ping -c 1 -W 1 $IP > /dev/null 2>&1 && echo "✓ Online" || echo "✗ Offline"

    # System info
    ssh root@$IP "
        echo '  === System Info ==='
        echo '  Hostname:' \$(hostname)
        echo '  Kernel:' \$(uname -r)
        echo '  Uptime:' \$(uptime -p)
        echo
        echo '  === Resources ==='
        echo '  CPU Cores:' \$(nproc)
        echo '  Load Average:' \$(uptime | awk -F'load average:' '{print \$2}')
        echo '  Memory:' \$(free -h | grep Mem | awk '{print \"Total: \"\$2\", Used: \"\$3\", Free: \"\$4\", Available: \"\$7}')
        echo '  Swap:' \$(free -h | grep Swap | awk '{print \"Total: \"\$2\", Used: \"\$3}')
        echo
        echo '  === Disk Usage ==='
        df -h / /var /tmp 2>/dev/null | grep -v Filesystem
        echo
        echo '  === Top 5 CPU Processes ==='
        ps aux --sort=-%cpu | head -6 | tail -5 | awk '{print \"  \"\$11\" CPU:\"\$3\"%\"}'
        echo
        echo '  === Top 5 Memory Processes ==='
        ps aux --sort=-%mem | head -6 | tail -5 | awk '{print \"  \"\$11\" MEM:\"\$4\"%\"}'
        echo
        echo '  === Services Status ==='
        echo -n '  kubelet: '; systemctl is-active kubelet
        echo -n '  containerd: '; systemctl is-active containerd
        echo -n '  systemd-resolved: '; systemctl is-active systemd-resolved
        echo -n '  systemd-networkd: '; systemctl is-active systemd-networkd
        echo -n '  sshd: '; systemctl is-active sshd
        echo
        echo '  === Network Interfaces ==='
        ip -br addr show | grep UP
        echo
        echo '  === Listening Ports ==='
        ss -tuln | grep LISTEN | head -10
        echo
        echo '  === Recent Errors (last 10 min) ==='
        journalctl -p err --since '10 minutes ago' 2>/dev/null | tail -5 | sed 's/^/  /'
        [ \$(journalctl -p err --since '10 minutes ago' 2>/dev/null | wc -l) -eq 0 ] && echo '  None'
        echo
        echo '  === Kubelet Logs (last 5 min) ==='
        journalctl -u kubelet --since '5 minutes ago' 2>/dev/null | grep -E 'Error|error|Failed|failed' | tail -3 | sed 's/^/  /'
        [ \$(journalctl -u kubelet --since '5 minutes ago' 2>/dev/null | grep -iE 'error|failed' | wc -l) -eq 0 ] && echo '  No errors'
        echo
        echo '  === Disk I/O Stats ==='
        iostat -x 1 2 2>/dev/null | tail -n +4 | grep -E 'sda|sdb|nvme' | head -3 | awk '{print \"  Device: \"\$1\" r/s:\"\$4\" w/s:\"\$5\" %util:\"\$14}'
        echo
        echo '  === Zombie/Defunct Processes ==='
        echo -n '  Count: '; ps aux | grep -c '<defunct>' 2>/dev/null || echo '0'
    " 2>/dev/null || echo "  ERROR: Cannot connect to node"
    echo
}

echo "1. NODE-BY-NODE DETAILED CHECK"
echo "================================="
echo
check_node_full "k8s01" "192.168.0.50"
check_node_full "k8s02" "192.168.0.51"
check_node_full "k8s03" "192.168.0.52"
check_node_full "k8s04" "192.168.0.53"
check_node_full "k8s05" "192.168.0.54"
check_node_full "k8s06" "192.168.0.55"
check_node_full "k8s07" "192.168.0.56"
check_node_full "k8s08" "192.168.0.57"
check_node_full "k8s09" "192.168.0.58"

echo "2. KUBERNETES CLUSTER STATUS"
echo "============================="
echo
echo "Node Status:"
kubectl get nodes -o wide
echo
echo "Control Plane Components:"
kubectl get pods -n kube-system -l tier=control-plane
echo
echo "System Pods Health:"
kubectl get pods -n kube-system --no-headers | awk '{print $1,$2,$3}' | column -t
echo
echo "Failed/Error Pods:"
kubectl get pods --all-namespaces | grep -vE "Running|Completed" | head -10
echo

echo "3. CERTIFICATE STATUS"
echo "====================="
ssh root@192.168.0.50 "kubeadm certs check-expiration 2>/dev/null | head -20"
echo

echo "4. ETCD HEALTH"
echo "=============="
ssh root@192.168.0.50 "ETCDCTL_API=3 etcdctl \
    --endpoints=https://192.168.0.50:2379,https://192.168.0.51:2379,https://192.168.0.52:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    endpoint health 2>/dev/null"
echo

echo "5. NETWORK HEALTH"
echo "================="
echo "CNI Pod Status:"
kubectl get pods -n kube-system | grep -E "cilium|multus" | awk '{print $1,$2,$3}'
echo
echo "Network Policies:"
kubectl get networkpolicies --all-namespaces
echo
echo "Services:"
kubectl get svc --all-namespaces | head -10
echo

echo "6. STORAGE STATUS"
echo "================="
echo "PersistentVolumes:"
kubectl get pv 2>/dev/null || echo "None"
echo
echo "PersistentVolumeClaims:"
kubectl get pvc --all-namespaces 2>/dev/null || echo "None"
echo

echo "7. CLUSTER EVENTS (Warnings)"
echo "============================"
kubectl get events --all-namespaces --field-selector type=Warning --sort-by='.lastTimestamp' | tail -10
echo

echo "8. KUBECTL FUNCTIONALITY TEST"
echo "============================="
echo -n "exec test: "
kubectl run test-exec-final --image=alpine --restart=Never -- sleep 10 2>/dev/null
sleep 3
kubectl exec test-exec-final -- echo "✓ Working" 2>/dev/null || echo "✗ Failed"
kubectl delete pod test-exec-final --force --grace-period=0 2>/dev/null
echo -n "logs test: "
kubectl logs -n kube-system kube-apiserver-k8s01 --tail=1 > /dev/null 2>&1 && echo "✓ Working" || echo "✗ Failed"
echo

echo "9. RESOURCE USAGE SUMMARY"
echo "========================="
echo "Node Resource Usage:"
for i in 50 51 52 53 54 55 56 57 58; do
    NODE=$([ $i -le 52 ] && echo "k8s0$((i-49))" || echo "k8s0$((i-49))")
    echo -n "  $NODE: "
    ssh root@192.168.0.$i "
        CPU=\$(top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - \$1}')
        MEM=\$(free | grep Mem | awk '{print (\$3/\$2) * 100.0}')
        DISK=\$(df / | tail -1 | awk '{print \$5}')
        echo \"CPU: \${CPU}%, Memory: \${MEM}%, Disk: \${DISK}\"
    " 2>/dev/null || echo "ERROR"
done
echo

echo "10. CRITICAL SERVICE CHECK"
echo "=========================="
echo "API Server Response:"
curl -k https://192.168.0.200:6443/healthz 2>/dev/null && echo " - Healthy" || echo " - Unhealthy"
echo
echo "CoreDNS Resolution Test:"
kubectl run test-dns --image=alpine --restart=Never -- nslookup kubernetes.default 2>/dev/null
sleep 3
kubectl logs test-dns 2>/dev/null | head -5
kubectl delete pod test-dns --force --grace-period=0 2>/dev/null
echo

echo "========================================="
echo "HEALTH CHECK COMPLETE"
echo "========================================="
