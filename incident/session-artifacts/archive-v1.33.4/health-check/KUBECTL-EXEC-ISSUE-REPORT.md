# kubectl exec/logs TLS Issue - Investigation Report

## Date: 2025-08-25
## Time: 20:40 UTC

## Executive Summary
**CRITICAL ISSUE**: `kubectl exec` and `kubectl logs` are completely broken due to missing kubelet serving certificates. This is NOT a minor issue - it severely impacts cluster operability.

## Problem Statement
- **Commands affected**: `kubectl exec`, `kubectl logs`, `kubectl port-forward`
- **Error**: `remote error: tls: internal error`
- **Root cause**: 293 pending Certificate Signing Requests (CSRs) for kubelet serving certificates that have never been approved

## Investigation Findings

### 1. Certificate Configuration
```yaml
# /var/lib/kubelet/config.yaml
serverTLSBootstrap: true
```
This setting enables kubelet to request serving certificates via CSR, but they must be approved.

### 2. Missing Serving Certificates
- **Client certificates**: ✅ Present at `/var/lib/kubelet/pki/kubelet-client-current.pem`
- **Server certificates**: ❌ Missing - no serving certificates exist on any node

### 3. Pending CSRs
```
Total pending CSRs: 293
Type: kubernetes.io/kubelet-serving
Status: ALL Pending (some for 18+ hours)
Nodes affected: All 9 nodes (k8s01-k8s09)
```

### 4. Kubelet Errors
From kubelet logs on all nodes:
```
"Certificate request was not signed" err="timed out waiting for the condition"
"http: TLS handshake error from X.X.X.X: no serving certificate available for the kubelet"
"Reached backoff limit, still unable to rotate certs"
```

### 5. Auto-approval Configuration
Current ClusterRoleBindings only auto-approve:
- `kubeadm:node-autoapprove-bootstrap` - for node client certificates
- `kubeadm:node-autoapprove-certificate-rotation` - for self node client certificate rotation

**Missing**: Auto-approval for `kubernetes.io/kubelet-serving` certificates

## Impact Analysis

### Operations Blocked
1. **Debugging**: Cannot exec into pods for troubleshooting
2. **Logs**: Cannot retrieve container logs via kubectl
3. **Port Forwarding**: Cannot forward ports to pods
4. **File Operations**: Cannot copy files to/from pods
5. **Health Checks**: Cannot run commands in pods for validation

### Workarounds Currently Required
- SSH to nodes and use `crictl exec` directly
- Check logs via `crictl logs` on nodes
- Use `journalctl` for system services

## Why This Happened
When `serverTLSBootstrap: true` is set in kubelet config:
1. Kubelet generates CSRs for serving certificates
2. These CSRs must be approved (manually or via controller)
3. No auto-approval is configured for serving certificates (security best practice)
4. CSRs accumulated over 18 hours without approval

## Security Considerations
Serving certificate CSRs are NOT auto-approved by default because:
- They allow external connections to kubelet API
- Could be exploited if malicious CSRs were auto-approved
- Best practice is manual approval or dedicated controller

## Solutions Available

### Option 1: Approve All Pending CSRs (Quick Fix)
```bash
kubectl get csr -o name | xargs kubectl certificate approve
```
**Pros**: Immediate fix
**Cons**: Approves without verification (security risk if any malicious CSRs)

### Option 2: Selective Approval (Recommended for Production)
```bash
kubectl get csr | grep kubernetes.io/kubelet-serving | awk '{print $1}' | xargs kubectl certificate approve
```
**Pros**: Only approves kubelet-serving CSRs
**Cons**: Still bulk approval without individual verification

### Option 3: Install Auto-Approver (Long-term Solution)
Deploy a controller like `kubelet-csr-approver` that safely auto-approves legitimate kubelet CSRs

### Option 4: Disable serverTLSBootstrap (Not Recommended)
Set `serverTLSBootstrap: false` and use self-signed certificates
**Pros**: No CSR management needed
**Cons**: Less secure, no certificate rotation

## Recommendation
This is a **CRITICAL** issue that needs immediate resolution:

1. **Immediate**: Approve pending CSRs to restore functionality
2. **Short-term**: Document CSR approval process
3. **Long-term**: Deploy auto-approval controller or establish manual approval workflow

## Commands to Verify Issue
```bash
# Check CSR count
kubectl get csr | wc -l

# Check for pending serving CSRs
kubectl get csr | grep Pending | grep kubernetes.io/kubelet-serving

# Test kubectl exec (will fail)
kubectl run test --image=alpine -- sleep 10
kubectl exec test -- echo hello

# Check kubelet logs
ssh root@NODE_IP "journalctl -u kubelet | grep -i certificate"
```

## Conclusion
This is NOT a non-blocking issue. Core kubernetes operations are broken. The cluster cannot be effectively operated or debugged without kubectl exec/logs functionality. Immediate action required.
