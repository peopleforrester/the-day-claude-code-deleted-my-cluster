#!/bin/bash
# Discovery script for cluster initialization status

FIRST_MASTER="192.168.0.50"
VIP="192.168.0.200"
LOG_FILE="discovery-06.log"

echo "===================================" | tee $LOG_FILE
echo "Cluster Initialization Discovery" | tee -a $LOG_FILE
echo "Timestamp: $(date)" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "Target: k8s01 ($FIRST_MASTER)" | tee -a $LOG_FILE
echo "VIP: $VIP" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# 1. Check if cluster is already initialized
echo "1. CHECKING EXISTING INITIALIZATION:" | tee -a $LOG_FILE
echo "------------------------------------" | tee -a $LOG_FILE

# Check for kubeadm config
KUBEADM_CONFIG=$(ssh root@$FIRST_MASTER "test -f /etc/kubernetes/admin.conf && echo 'exists' || echo 'not found'" 2>/dev/null)
echo "  /etc/kubernetes/admin.conf: $KUBEADM_CONFIG" | tee -a $LOG_FILE

# Check for kubelet config
KUBELET_CONFIG=$(ssh root@$FIRST_MASTER "test -f /etc/kubernetes/kubelet.conf && echo 'exists' || echo 'not found'" 2>/dev/null)
echo "  /etc/kubernetes/kubelet.conf: $KUBELET_CONFIG" | tee -a $LOG_FILE

# Check for manifests
MANIFESTS=$(ssh root@$FIRST_MASTER "ls /etc/kubernetes/manifests/ 2>/dev/null | wc -l" 2>/dev/null)
echo "  Static pod manifests: $MANIFESTS files" | tee -a $LOG_FILE

# Check if API server is running
API_CHECK=$(ssh root@$FIRST_MASTER "ss -tlnp | grep 6443 2>/dev/null | wc -l" 2>/dev/null)
echo "  API server port 6443: $([ "$API_CHECK" -gt 0 ] && echo 'listening' || echo 'not listening')" | tee -a $LOG_FILE

# Check kubelet status
KUBELET_STATUS=$(ssh root@$FIRST_MASTER "systemctl is-active kubelet" 2>/dev/null)
echo "  Kubelet service: $KUBELET_STATUS" | tee -a $LOG_FILE

# 2. Check kube-vip status
echo "" | tee -a $LOG_FILE
echo "2. KUBE-VIP STATUS:" | tee -a $LOG_FILE
echo "-------------------" | tee -a $LOG_FILE

# Check if VIP is active
VIP_ACTIVE=$(ssh root@$FIRST_MASTER "ip addr show | grep -q '$VIP' && echo 'active' || echo 'not active'" 2>/dev/null)
echo "  VIP on first master: $VIP_ACTIVE" | tee -a $LOG_FILE

# Check kube-vip manifest
KUBE_VIP_MANIFEST=$(ssh root@$FIRST_MASTER "test -f /etc/kubernetes/manifests/kube-vip.yaml && echo 'exists' || echo 'not found'" 2>/dev/null)
echo "  kube-vip manifest: $KUBE_VIP_MANIFEST" | tee -a $LOG_FILE

# 3. Check prerequisites
echo "" | tee -a $LOG_FILE
echo "3. PREREQUISITES CHECK:" | tee -a $LOG_FILE
echo "-----------------------" | tee -a $LOG_FILE

# Check containerd
CONTAINERD=$(ssh root@$FIRST_MASTER "systemctl is-active containerd" 2>/dev/null)
echo "  containerd: $CONTAINERD" | tee -a $LOG_FILE

# Check crictl configuration
CRICTL_CONFIG=$(ssh root@$FIRST_MASTER "test -f /etc/crictl.yaml && cat /etc/crictl.yaml 2>/dev/null || echo 'not configured'" 2>/dev/null)
echo "  crictl config: $(echo "$CRICTL_CONFIG" | head -1)" | tee -a $LOG_FILE

# Check swap
SWAP=$(ssh root@$FIRST_MASTER "swapon --show | wc -l" 2>/dev/null)
echo "  Swap: $([ "$SWAP" = "0" ] && echo 'disabled' || echo 'ENABLED - must disable!')" | tee -a $LOG_FILE

# 4. Check network readiness
echo "" | tee -a $LOG_FILE
echo "4. NETWORK READINESS:" | tee -a $LOG_FILE
echo "---------------------" | tee -a $LOG_FILE

# Check hostname
HOSTNAME=$(ssh root@$FIRST_MASTER "hostname" 2>/dev/null)
FQDN=$(ssh root@$FIRST_MASTER "hostname -f" 2>/dev/null)
echo "  Hostname: $HOSTNAME" | tee -a $LOG_FILE
echo "  FQDN: $FQDN" | tee -a $LOG_FILE

# Check /etc/hosts
HOSTS_ENTRIES=$(ssh root@$FIRST_MASTER "grep -E '(k8s|192.168.0)' /etc/hosts | wc -l" 2>/dev/null)
echo "  /etc/hosts k8s entries: $HOSTS_ENTRIES" | tee -a $LOG_FILE

# Check DNS resolution
DNS_TEST=$(ssh root@$FIRST_MASTER "nslookup kubernetes.default 2>&1 | grep -q 'can.*t find' && echo 'not configured' || echo 'configured'" 2>/dev/null)
echo "  Kubernetes DNS: $DNS_TEST" | tee -a $LOG_FILE

# 5. Check versions
echo "" | tee -a $LOG_FILE
echo "5. VERSION CHECK:" | tee -a $LOG_FILE
echo "-----------------" | tee -a $LOG_FILE

KUBEADM_VERSION=$(ssh root@$FIRST_MASTER "kubeadm version -o short" 2>/dev/null)
KUBELET_VERSION=$(ssh root@$FIRST_MASTER "kubelet --version 2>/dev/null | awk '{print \$2}'" 2>/dev/null)
KUBECTL_VERSION=$(ssh root@$FIRST_MASTER "kubectl version --client -o yaml 2>/dev/null | grep gitVersion | awk '{print \$2}'" 2>/dev/null)

echo "  kubeadm: $KUBEADM_VERSION" | tee -a $LOG_FILE
echo "  kubelet: $KUBELET_VERSION" | tee -a $LOG_FILE
echo "  kubectl: $KUBECTL_VERSION" | tee -a $LOG_FILE

# Summary
echo "" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE
echo "Discovery Summary" | tee -a $LOG_FILE
echo "===================================" | tee -a $LOG_FILE

if [ "$KUBEADM_CONFIG" = "exists" ]; then
    echo "⚠ WARNING: Cluster appears to be already initialized!" | tee -a $LOG_FILE
    echo "  Found existing /etc/kubernetes/admin.conf" | tee -a $LOG_FILE
    echo "  Proceed with caution or reset first with: kubeadm reset" | tee -a $LOG_FILE
else
    echo "✓ Cluster not initialized - ready to proceed" | tee -a $LOG_FILE
    echo "  kubeadm version: $KUBEADM_VERSION" | tee -a $LOG_FILE
    echo "  VIP configured: $VIP_ACTIVE" | tee -a $LOG_FILE
    echo "  kube-vip manifest: $KUBE_VIP_MANIFEST" | tee -a $LOG_FILE
fi

echo "" | tee -a $LOG_FILE
echo "Discovery complete" | tee -a $LOG_FILE
