# Issues Encountered - Step 02

## No Major Issues

All system prerequisites were applied successfully without any significant issues.

## Minor Observations

1. **systemd-resolved**
   - Was running on all nodes
   - Disabled to prevent conflicts with CoreDNS
   - Replaced with static DNS configuration

2. **Swap Files**
   - All nodes had 4-8GB swap files
   - Successfully disabled and removed
   - Freed up disk space

3. **IP Tables**
   - No existing iptables rules found
   - Clean slate for Kubernetes rules
   - Rules saved but persistence may need netfilter-persistent package

## Verification Results

All nodes passed verification:
- ✅ Swap disabled
- ✅ IP forwarding enabled
- ✅ All kernel modules loaded
- ✅ Bridge netfilter enabled
- ✅ Time synchronized
- ✅ Systemd cgroup accounting enabled

## Notes for Future Steps

1. **Containerd Configuration**
   - Must use systemd cgroup driver to match kubelet
   - Version must be exactly v2.1.4

2. **Network Plugin**
   - Firewall rules prepared for Cilium CNI
   - Additional ports may be needed for other services

3. **DNS**
   - May need to adjust DNS configuration after CoreDNS deployment
   - Current Google DNS servers are temporary
