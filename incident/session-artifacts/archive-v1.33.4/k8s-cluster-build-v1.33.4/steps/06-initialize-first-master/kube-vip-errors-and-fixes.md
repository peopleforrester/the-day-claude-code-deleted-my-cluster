# kube-vip v1.0.0 Errors and Root Cause Analysis

## Error Timeline

### Error 1: No Features Enabled
**Timestamp:** 2025/08/25 02:20:54
**Log Message:**
```
ERROR no features are enabled
```

**Root Cause:**
- The manifest was missing the `cp_enable` environment variable
- kube-vip v1.0.0 requires explicit feature enablement
- Without `cp_enable: "true"`, kube-vip has no functionality to execute

**Fix Applied:**
```yaml
- name: cp_enable
  value: "true"
```

### Error 2: Invalid CIDR Format
**Timestamp:** 2025/08/25 02:22:11
**Log Message:**
```
ERROR start manager err="invalid CIDR: \"192.168.0.200/\",
invalid CIDR address: 192.168.0.200/
could not format address '192.168.0.200' with subnetMask ''"
```

**Root Cause:**
- Conflicting address configuration using both `vip_address` and `vip_cidr`
- kube-vip attempted to construct "192.168.0.200/" (missing CIDR number)
- The v1.0.0 parser expects either:
  - `address` with embedded CIDR: `192.168.0.200/32`
  - OR separate `address` and `vip_cidr` variables

**Fix Applied:**
```yaml
- name: address
  value: 192.168.0.200    # No CIDR suffix
- name: vip_cidr
  value: "32"             # Separate CIDR variable
```

## Configuration Differences

### Pre-Initialization Manifest (Step 05)
- Simple VIP holder configuration
- No control plane features
- No leader election
- No admin.conf mounting

### Post-Initialization Manifest (Step 06)
- Full control plane load balancer
- Leader election enabled
- Admin config access required
- Service load balancing optional

## Critical Environment Variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `cp_enable` | YES | Enable control plane mode |
| `address` | YES | VIP address (without CIDR) |
| `vip_cidr` | YES | Subnet mask in CIDR notation |
| `vip_interface` | YES | Network interface for VIP |
| `vip_arp` | YES | Enable ARP advertisements |
| `vip_leaderelection` | YES (HA) | Enable leader election |
| `port` | YES | API server port |

## Debugging Commands

### Container Inspection
```bash
# Get container ID
crictl ps | grep kube-vip

# View logs (kubectl may fail due to TLS)
crictl logs <container-id>

# Check container status
crictl inspect <container-id>
```

### Network Verification
```bash
# Check VIP assignment
ip addr show | grep 192.168.0.200

# Verify ARP entry
arp -n | grep 192.168.0.200

# Test API connectivity
curl -k https://192.168.0.200:6443/livez
```

### Lease Verification
```bash
# Check leader election lease
kubectl get lease -n kube-system plndr-cp-lock -o yaml
```

## Common Failure Patterns

1. **Container Restart Loop**
   - Check environment variables in manifest
   - Verify image is pulled: `ctr image ls | grep kube-vip`
   - Check capabilities (NET_ADMIN, NET_RAW)

2. **VIP Not Responding**
   - Verify interface name matches system
   - Check for IP conflicts: `arping 192.168.0.200`
   - Ensure host network mode is enabled

3. **Leader Election Failures**
   - Verify admin.conf is mounted
   - Check RBAC permissions
   - Ensure kube-system namespace exists

4. **Parse Errors**
   - Environment values must be strings (quoted)
   - CIDR notation consistency
   - No trailing slashes in addresses
