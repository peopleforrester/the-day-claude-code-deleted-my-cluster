# COMPLETE KUBE-VIP v1.0.0 FIX DOCUMENTATION

## Executive Summary
kube-vip v1.0.0 failed after cluster initialization due to incorrect manifest configuration. This document details every error, the root causes, and the exact fix that resolved the issues.

## Timeline of Failures

### Attempt 1: Original Manifest from Step 05
**Error Message:**
```
2025/08/25 02:20:54 ERROR no features are enabled
```

**Root Cause:**
- The manifest was missing critical environment variables to enable functionality
- Specifically missing: `cp_enable: "true"` to enable control plane load balancing
- Also missing: `svc_enable` configuration

**Manifest Issue:**
```yaml
env:
- name: vip_arp
  value: "true"
- name: vip_interface
  value: "enp2s0"
# MISSING: cp_enable, svc_enable
```

### Attempt 2: Added cp_enable but CIDR Error
**Error Message:**
```
2025/08/25 02:22:11 ERROR start manager err="invalid CIDR: \"192.168.0.200/\",
invalid CIDR address: 192.168.0.200/
could not format address '192.168.0.200' with subnetMask ''
```

**Root Cause:**
- The manifest had conflicting CIDR configuration
- Used both `vip_cidr: "32"` and `vip_address: "192.168.0.200"`
- kube-vip v1.0.0 expects either:
  - `address` with CIDR included: `address: "192.168.0.200/32"`, OR
  - `address` and `vip_cidr` as separate variables

**Manifest Issue:**
```yaml
- name: vip_cidr
  value: "32"
- name: vip_address
  value: "192.168.0.200"
# These conflicted - kube-vip tried to construct "192.168.0.200/" (missing number)
```

## THE WORKING SOLUTION

### Critical Requirements for kube-vip v1.0.0 Post-Init:

1. **Control Plane Mode MUST be enabled:**
   ```yaml
   - name: cp_enable
     value: "true"
   ```

2. **Address configuration (use ONE of these patterns):**
   ```yaml
   # Pattern A: Separate address and CIDR
   - name: address
     value: 192.168.0.200
   - name: vip_cidr
     value: "32"
   ```

3. **Leader Election for HA:**
   ```yaml
   - name: vip_leaderelection
     value: "true"
   - name: vip_leaseduration
     value: "5"
   ```

4. **Admin Config Access:**
   ```yaml
   volumeMounts:
   - mountPath: /etc/kubernetes/admin.conf
     name: kubeconfig
   volumes:
   - hostPath:
       path: /etc/kubernetes/admin.conf
     name: kubeconfig
   ```

### Complete Working Manifest
Location: `/etc/kubernetes/manifests/kube-vip.yaml`

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
    - name: vip_arp
      value: "true"
    - name: port
      value: "6443"
    - name: vip_interface
      value: enp2s0           # Interface specific to k8s01
    - name: vip_cidr
      value: "32"
    - name: cp_enable
      value: "true"           # CRITICAL: Enable control plane mode
    - name: cp_namespace
      value: kube-system
    - name: vip_ddns
      value: "false"
    - name: svc_enable
      value: "false"          # We're not load balancing services
    - name: vip_leaderelection
      value: "true"           # Enable leader election for HA
    - name: vip_leaseduration
      value: "5"
    - name: vip_renewdeadline
      value: "3"
    - name: vip_retryperiod
      value: "1"
    - name: address
      value: 192.168.0.200    # VIP address WITHOUT /32
    image: ghcr.io/kube-vip/kube-vip:v1.0.0
    imagePullPolicy: IfNotPresent
    name: kube-vip
    resources: {}
    securityContext:
      capabilities:
        add:
        - NET_ADMIN           # Required for network management
        - NET_RAW             # Required for ARP
    volumeMounts:
    - mountPath: /etc/kubernetes/admin.conf
      name: kubeconfig
  hostAliases:
  - hostnames:
    - kubernetes
    ip: 127.0.0.1
  hostNetwork: true           # MUST run in host network
  volumes:
  - hostPath:
      path: /etc/kubernetes/admin.conf
    name: kubeconfig
```

## Verification Commands

### 1. Check Pod Status
```bash
kubectl get pods -n kube-system | grep kube-vip
# Expected: kube-vip-k8s01   1/1   Running   0   <time>
```

### 2. Check Logs via crictl (kubectl logs may fail due to TLS)
```bash
crictl ps | grep kube-vip
crictl logs <container-id>
# Expected: "successfully acquired lease kube-system/plndr-cp-lock"
```

### 3. Verify VIP Assignment
```bash
ip addr show | grep 192.168.0.200
# Expected: inet 192.168.0.200/32 scope global <interface>
```

### 4. Test VIP Connectivity
```bash
# From another machine:
ping 192.168.0.200
nc -zv 192.168.0.200 6443
curl -k https://192.168.0.200:6443/livez
# Expected: "ok"
```

## Successful Operation Logs
```
2025/08/25 02:28:03 INFO starting namespace=kube-system Mode=ARP "Control Plane"=true Services=false
2025/08/25 02:28:03 INFO Starting Kube-vip Manager with the ARP engine
2025/08/25 02:28:03 INFO cluster membership namespace=kube-system lock=plndr-cp-lock id=k8s01
I0825 02:28:03.399641 leaderelection.go:271] successfully acquired lease kube-system/plndr-cp-lock
2025/08/25 02:28:03 INFO New leader leader=k8s01
2025/08/25 02:28:03 INFO inserting ARP/NDP instance name=192.168.0.200/32-enp2s0
```

## Common Pitfalls

1. **DO NOT** use `vip_address` with `/32` suffix when `vip_cidr` is separate
2. **DO NOT** forget `cp_enable: "true"` for control plane mode
3. **DO NOT** run without host network mode
4. **DO NOT** forget NET_ADMIN and NET_RAW capabilities
5. **DO NOT** assume kubectl logs will work - use crictl for debugging

## For Additional Control Plane Nodes

When adding k8s02 and k8s03:
1. Copy the same manifest
2. Change `vip_interface` to match their network interface (enp2s0 or enp1s0)
3. The leader election will handle VIP failover automatically
4. Only the leader will hold the VIP at any given time

## Troubleshooting Steps

If kube-vip fails:
1. Check container status: `crictl ps -a | grep kube-vip`
2. Get container logs: `crictl logs <container-id>`
3. Check manifest: `cat /etc/kubernetes/manifests/kube-vip.yaml`
4. Verify image exists: `ctr image ls | grep kube-vip`
5. Check network interface: `ip link show`
6. Verify no port conflicts: `ss -tlnp | grep 6443`

## Key Lessons Learned

1. **kube-vip v1.0.0 is sensitive to environment variable format**
   - Some variables expect quotes, others don't
   - CIDR can be embedded or separate but not malformed

2. **Pre-init vs Post-init configurations are different**
   - Pre-init: Simple VIP holder
   - Post-init: Full control plane load balancer with leader election

3. **Static pods restart automatically**
   - Changes to manifest trigger automatic restart
   - No need to manually restart kubelet

4. **Leader election requires cluster access**
   - Must mount admin.conf
   - Must have access to kube-system namespace

## References
- kube-vip v1.0.0 source: https://github.com/kube-vip/kube-vip/tree/v1.0.0
- Static pod location: /etc/kubernetes/manifests/
- Leader lease: kube-system/plndr-cp-lock
