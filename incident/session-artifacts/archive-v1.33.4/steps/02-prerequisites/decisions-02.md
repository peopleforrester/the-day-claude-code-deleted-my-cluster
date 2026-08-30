# Decisions - Step 02: System Prerequisites

## Date: August 24, 2025

### Key Decisions Made

1. **Swap Disabled Permanently**
   - Removed swap entries from /etc/fstab
   - Deleted swap files to free disk space
   - Kubernetes requires swap to be disabled for proper memory management

2. **Kernel Modules Loaded**
   - Loaded all required modules for Kubernetes networking
   - Made persistent via /etc/modules-load.d/kubernetes.conf
   - Includes ip_vs modules for kube-proxy IPVS mode

3. **Sysctl Configuration**
   - Enabled IP forwarding (required for pod networking)
   - Enabled bridge netfilter (required for iptables rules)
   - Added performance tuning (BBR congestion control)
   - Increased inotify limits for better file watching

4. **Firewall Configuration**
   - Opened all required Kubernetes ports
   - Different rules for control plane vs worker nodes
   - Saved rules for persistence across reboots

5. **Time Synchronization**
   - Installed chrony for better time sync than systemd-timesyncd
   - Critical for certificate validation and etcd

6. **DNS Configuration**
   - Disabled systemd-resolved to prevent conflicts with CoreDNS
   - Set Google DNS as fallback resolvers

7. **Systemd Cgroup**
   - Confirmed systemd cgroup driver is active
   - Will configure containerd to match in Step 03

### Configuration Choices

- **Performance**: Enabled BBR TCP congestion control for better network performance
- **Security**: Kept firewall rules minimal but sufficient
- **Reliability**: Used chrony for more accurate time synchronization
- **Compatibility**: Ensured all settings compatible with Ubuntu 24.04 and cgroup v2

### Next Steps
- Install containerd v2.1.4 with systemd cgroup driver
- Configure containerd for Kubernetes CRI
