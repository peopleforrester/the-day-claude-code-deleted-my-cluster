# Decisions - Step 01: Initial Connectivity & Inventory

## Date: August 24, 2025

### Key Findings

1. **All nodes accessible via SSH**
   - All 9 nodes (192.168.0.50-58) have passwordless root SSH access
   - Hostnames correctly set (k8s01-k8s09)

2. **Ubuntu 24.04.3 LTS confirmed on all nodes**
   - Kernel: 6.8.0-78-generic (non-LTS but acceptable)
   - All nodes running same OS version as required

3. **Cgroup v2 active on all nodes**
   - Confirmed via filesystem type check (cgroup2fs)
   - Ubuntu 24.04 default as expected
   - systemd as cgroup driver will be configured

4. **Hardware meets requirements**
   - Control plane nodes: 15.7GB RAM (exceeds 4GB minimum)
   - Worker nodes: 7.8-63GB RAM (exceeds 2GB minimum)
   - All nodes have >400GB available disk space
   - CPU cores: 4-12 cores per node (exceeds 2 core minimum)

5. **Issues discovered**
   - IP forwarding disabled on all nodes (will fix in Step 02)
   - Swap enabled on all nodes (will disable in Step 02)
   - Network testing tools (ping, nc) not installed by default

### Decisions Made

1. **Proceed with deployment** - All critical requirements met
2. **Network tools installation** - Will install iputils-ping and netcat in Step 02
3. **Accept non-LTS kernel** - 6.8.0 kernel works fine with Kubernetes
4. **Node roles confirmed**:
   - Control plane: k8s01-k8s03 (192.168.0.50-52)
   - Workers: k8s04-k8s09 (192.168.0.53-58)

### Action Items for Step 02
- Disable swap permanently
- Enable IP forwarding
- Install network diagnostic tools
- Configure kernel modules
- Set up firewall rules
