# kube-vip v1.0.0 Troubleshooting Guide

## Quick Diagnostic Commands

### Check kube-vip Status
```bash
# Is the pod running?
kubectl get pods -n kube-system | grep kube-vip

# Get container ID for direct inspection
crictl ps | grep kube-vip

# View recent logs
crictl logs $(crictl ps | grep kube-vip | awk '{print $1}') | tail -20

# Check if VIP is assigned
ip addr show | grep 192.168.0.200
```

## Common Issues and Solutions

### Issue 1: Pod Not Starting

**Symptoms:**
- No kube-vip pod in `kubectl get pods -n kube-system`
- Container not visible in `crictl ps`

**Diagnosis:**
```bash
# Check if manifest exists
ls -la /etc/kubernetes/manifests/kube-vip.yaml

# Verify manifest syntax
kubectl apply --dry-run=client -f /etc/kubernetes/manifests/kube-vip.yaml

# Check kubelet logs for static pod errors
journalctl -u kubelet -n 50 | grep kube-vip
```

**Solutions:**
1. Ensure manifest is in `/etc/kubernetes/manifests/`
2. Fix YAML syntax errors
3. Verify image can be pulled: `ctr image pull ghcr.io/kube-vip/kube-vip:v1.0.0`
4. Restart kubelet: `systemctl restart kubelet`

### Issue 2: Container Crashing (CrashLoopBackOff)

**Symptoms:**
- Pod shows status `CrashLoopBackOff` or `Error`
- Restart count increasing

**Diagnosis:**
```bash
# Get detailed pod status
kubectl describe pod kube-vip-$(hostname) -n kube-system

# Check container logs for error
crictl logs $(crictl ps -a | grep kube-vip | head -1 | awk '{print $1}')

# Common error patterns to look for:
# - "no features are enabled"
# - "invalid CIDR"
# - "failed to get kubeconfig"
```

**Solutions:**

For "no features are enabled":
```yaml
# Add to manifest env section:
- name: cp_enable
  value: "true"
```

For "invalid CIDR" errors:
```yaml
# Use correct format:
- name: address
  value: 192.168.0.200  # No /32 here
- name: vip_cidr
  value: "32"           # CIDR as separate variable
```

For kubeconfig errors:
```yaml
# Ensure volume mount exists:
volumeMounts:
- mountPath: /etc/kubernetes/admin.conf
  name: kubeconfig
volumes:
- hostPath:
    path: /etc/kubernetes/admin.conf
  name: kubeconfig
```

### Issue 3: VIP Not Assigned

**Symptoms:**
- Pod running but no VIP on interface
- `ip addr show | grep 192.168.0.200` returns nothing

**Diagnosis:**
```bash
# Check interface name
ip link show

# Verify kube-vip has leader lease
kubectl get lease -n kube-system plndr-cp-lock -o yaml

# Check logs for ARP errors
crictl logs $(crictl ps | grep kube-vip | awk '{print $1}') | grep -i arp
```

**Solutions:**
1. Verify interface name matches system:
   ```yaml
   - name: vip_interface
     value: enp2s0  # Must match actual interface
   ```

2. Check for IP conflicts:
   ```bash
   arping -I enp2s0 192.168.0.200
   ```

3. Ensure capabilities are set:
   ```yaml
   securityContext:
     capabilities:
       add:
       - NET_ADMIN
       - NET_RAW
   ```

### Issue 4: Leader Election Failing

**Symptoms:**
- Log shows "failed to acquire lease"
- Multiple masters but no VIP holder

**Diagnosis:**
```bash
# Check lease status
kubectl get lease -n kube-system plndr-cp-lock -o yaml

# Verify RBAC permissions
kubectl auth can-i update leases -n kube-system --as system:node:$(hostname)

# Check connectivity to API server
curl -k https://localhost:6443/healthz
```

**Solutions:**
1. Ensure admin.conf is accessible:
   ```bash
   ls -la /etc/kubernetes/admin.conf
   ```

2. Verify leader election is enabled:
   ```yaml
   - name: vip_leaderelection
     value: "true"
   ```

3. Check lease parameters are reasonable:
   ```yaml
   - name: vip_leaseduration
     value: "5"
   - name: vip_renewdeadline
     value: "3"
   - name: vip_retryperiod
     value: "1"
   ```

### Issue 5: API Server Not Accessible via VIP

**Symptoms:**
- VIP assigned but connection refused on port 6443
- `curl -k https://192.168.0.200:6443/healthz` fails

**Diagnosis:**
```bash
# Check if API server is binding correctly
ss -tlnp | grep 6443

# Verify iptables rules
iptables -L -n -t nat | grep 6443

# Test local API server
curl -k https://$(hostname -i):6443/healthz
```

**Solutions:**
1. Verify API server advertise address in kubeadm config
2. Check firewall rules: `ufw status`
3. Ensure no port conflicts
4. Verify kube-vip port configuration:
   ```yaml
   - name: port
     value: "6443"
   ```

## Advanced Debugging

### Enable Debug Logging
Add to manifest for verbose output:
```yaml
- name: log_level
  value: "debug"
```

### Manual VIP Testing
Test VIP assignment manually:
```bash
# Add VIP manually (temporary)
ip addr add 192.168.0.200/32 dev enp2s0

# Test connectivity
ping -c 3 192.168.0.200

# Remove test VIP
ip addr del 192.168.0.200/32 dev enp2s0
```

### Container Inspection
Deep dive into container state:
```bash
# Get full container details
crictl inspect $(crictl ps | grep kube-vip | awk '{print $1}')

# Check container filesystem
crictl exec $(crictl ps | grep kube-vip | awk '{print $1}') ls -la /etc/kubernetes/

# Test network from inside container
crictl exec $(crictl ps | grep kube-vip | awk '{print $1}') ip addr show
```

## Recovery Procedures

### Complete Reset of kube-vip
```bash
# 1. Remove static pod manifest
mv /etc/kubernetes/manifests/kube-vip.yaml /tmp/

# 2. Wait for pod to terminate
sleep 10

# 3. Clean up any stuck VIP
ip addr del 192.168.0.200/32 dev enp2s0 2>/dev/null

# 4. Restore corrected manifest
cp /path/to/fixed/kube-vip.yaml /etc/kubernetes/manifests/

# 5. Monitor startup
watch crictl ps
```

### Force Leader Release
If a node is holding the lease incorrectly:
```bash
# Delete the lease (new leader will be elected)
kubectl delete lease -n kube-system plndr-cp-lock

# Monitor new leader election
kubectl get lease -n kube-system plndr-cp-lock -w
```

## Monitoring Commands

### Continuous Monitoring
```bash
# Watch pod status
watch -n 2 'kubectl get pods -n kube-system | grep kube-vip'

# Monitor VIP assignment
watch -n 2 'ip addr show | grep 192.168.0.200'

# Track leader changes
kubectl get lease -n kube-system plndr-cp-lock -w

# Follow logs in real-time
crictl logs -f $(crictl ps | grep kube-vip | awk '{print $1}')
```

## Prevention Best Practices

1. **Always test manifest changes** with `--dry-run` first
2. **Keep backup of working manifest** before modifications
3. **Document interface names** for each node
4. **Test VIP availability** before adding more masters
5. **Monitor after changes** for at least 5 minutes
6. **Use exact versions** specified in requirements (v1.0.0)

## When to Escalate

Contact for help if:
- VIP conflicts with existing infrastructure
- Network driver incompatibilities
- Persistent lease corruption
- Image registry access issues
- Unexplained packet loss on VIP

## Quick Reference Card

| Command | Purpose |
|---------|---------|
| `crictl ps \| grep kube-vip` | Get container ID |
| `crictl logs <id>` | View container logs |
| `ip addr show \| grep 200` | Check VIP assignment |
| `kubectl get lease -n kube-system` | Check leader election |
| `curl -k https://192.168.0.200:6443/healthz` | Test API via VIP |
| `journalctl -u kubelet \| grep kube-vip` | Check kubelet logs |
