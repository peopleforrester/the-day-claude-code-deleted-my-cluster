# kube-vip v1.0.0 Working Configuration Details

## Verified Working Manifest

This configuration has been tested and verified on Ubuntu 24.04 with Kubernetes v1.33.4.

### Full Static Pod Manifest
**Location:** `/etc/kubernetes/manifests/kube-vip.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-vip
  namespace: kube-system
spec:
  containers:
  - args:
    - manager
    env:
    # Network Configuration
    - name: vip_arp
      value: "true"              # Enable ARP mode for VIP
    - name: vip_interface
      value: enp2s0              # Physical interface (node-specific)

    # Address Configuration
    - name: address
      value: 192.168.0.200       # VIP address (no CIDR suffix)
    - name: vip_cidr
      value: "32"                # CIDR mask as separate variable
    - name: port
      value: "6443"              # Kubernetes API server port

    # Feature Enablement
    - name: cp_enable
      value: "true"              # CRITICAL: Enable control plane mode
    - name: cp_namespace
      value: kube-system         # Namespace for control plane resources
    - name: svc_enable
      value: "false"             # Not load balancing services
    - name: vip_ddns
      value: "false"             # Dynamic DNS not needed

    # Leader Election Configuration
    - name: vip_leaderelection
      value: "true"              # Enable HA leader election
    - name: vip_leaseduration
      value: "5"                 # Lease duration in seconds
    - name: vip_renewdeadline
      value: "3"                 # Renewal deadline in seconds
    - name: vip_retryperiod
      value: "1"                 # Retry period in seconds

    image: ghcr.io/kube-vip/kube-vip:v1.0.0
    imagePullPolicy: IfNotPresent
    name: kube-vip
    resources: {}
    securityContext:
      capabilities:
        add:
        - NET_ADMIN              # Required for network management
        - NET_RAW                # Required for ARP operations
    volumeMounts:
    - mountPath: /etc/kubernetes/admin.conf
      name: kubeconfig
  hostAliases:
  - hostnames:
    - kubernetes
    ip: 127.0.0.1
  hostNetwork: true              # MUST use host network
  volumes:
  - hostPath:
      path: /etc/kubernetes/admin.conf
    name: kubeconfig
```

## Configuration Parameters Explained

### Network Settings
| Parameter | Value | Description |
|-----------|-------|-------------|
| `vip_arp` | true | Use ARP for VIP advertisement (Layer 2) |
| `vip_interface` | enp2s0 | Network interface to bind VIP |
| `address` | 192.168.0.200 | Virtual IP address for API server |
| `vip_cidr` | 32 | Host-only subnet mask (/32) |
| `port` | 6443 | Kubernetes API server port |

### Control Plane Settings
| Parameter | Value | Description |
|-----------|-------|-------------|
| `cp_enable` | true | Enable control plane load balancing |
| `cp_namespace` | kube-system | Namespace for CP resources |
| `svc_enable` | false | Disable service load balancing |

### High Availability Settings
| Parameter | Value | Description |
|-----------|-------|-------------|
| `vip_leaderelection` | true | Enable leader election for HA |
| `vip_leaseduration` | 5 | Time before lease expires |
| `vip_renewdeadline` | 3 | Time to renew lease |
| `vip_retryperiod` | 1 | Retry interval for lease |

## Verification Steps

### 1. Pod Running Status
```bash
kubectl get pods -n kube-system -l name=kube-vip
# Output:
# NAME            READY   STATUS    RESTARTS   AGE
# kube-vip-k8s01  1/1     Running   0          10m
```

### 2. VIP Assignment
```bash
ip addr show dev enp2s0 | grep 192.168.0.200
# Output:
# inet 192.168.0.200/32 scope global enp2s0
```

### 3. Leader Election Status
```bash
kubectl get lease -n kube-system plndr-cp-lock -o jsonpath='{.spec.holderIdentity}'
# Output: k8s01
```

### 4. API Server Access via VIP
```bash
kubectl --server=https://192.168.0.200:6443 get nodes
# Output: List of cluster nodes
```

### 5. Successful Log Output
```bash
crictl logs $(crictl ps | grep kube-vip | awk '{print $1}')
# Expected output:
# INFO starting namespace=kube-system Mode=ARP "Control Plane"=true Services=false
# INFO Starting Kube-vip Manager with the ARP engine
# INFO cluster membership namespace=kube-system lock=plndr-cp-lock id=k8s01
# successfully acquired lease kube-system/plndr-cp-lock
# INFO New leader leader=k8s01
# INFO inserting ARP/NDP instance name=192.168.0.200/32-enp2s0
```

## Multi-Master Configuration

### For Additional Control Plane Nodes (k8s02, k8s03)

1. **Copy the same manifest** to `/etc/kubernetes/manifests/kube-vip.yaml`

2. **Adjust interface name** if different:
   ```yaml
   - name: vip_interface
     value: enp2s0  # or enp1s0 based on node
   ```

3. **Leader election handles failover automatically**:
   - Only one node holds the VIP at a time
   - Automatic failover on leader failure
   - No manual intervention required

### Expected Behavior in HA Setup
- First master (k8s01) initially holds the VIP
- If k8s01 fails, k8s02 or k8s03 takes over within 5 seconds
- VIP moves seamlessly between control plane nodes
- API server remains accessible at 192.168.0.200:6443

## Critical Success Factors

1. **Exact image version**: `ghcr.io/kube-vip/kube-vip:v1.0.0`
2. **Host network mode**: Required for VIP management
3. **Capabilities**: NET_ADMIN and NET_RAW are mandatory
4. **Admin config mount**: Required for Kubernetes API access
5. **Correct interface**: Must match actual network interface
6. **No conflicting services**: Ensure no other service uses the VIP

## Troubleshooting Quick Reference

| Symptom | Check | Solution |
|---------|-------|----------|
| Pod not starting | `crictl ps -a` | Check manifest syntax |
| No VIP assigned | `ip addr show` | Verify interface name |
| API unreachable | `nc -zv 192.168.0.200 6443` | Check firewall rules |
| Leader election fails | `kubectl get lease -n kube-system` | Verify admin.conf mount |
| Container restarts | `crictl logs` | Check environment variables |
