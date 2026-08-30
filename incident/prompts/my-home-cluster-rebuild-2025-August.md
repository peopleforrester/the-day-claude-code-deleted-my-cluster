claude "You have SSH access to my VMs and will build a Kubernetes cluster while maintaining a complete Git history. Create a branch for each step, execute the work, test it, then merge to main.
## CRITICAL INSTRUCTIONS:
1. **TIME**: Take as long as necessary - accuracy is more important than speed
2. **VERSIONS**: Install ONLY the exact versions specified - no substitutions
3. **NO WORKAROUNDS**: Do not mock, stub, or work around issues without explicit permission
4. **DISCOVERY FIRST**: When problems occur, investigate thoroughly before attempting fixes
5. **DOCUMENT EVERYTHING**: Record every command, decision, and outcome
6. **ASK WHEN STUCK**: If a specific version isn't available or something fails, ask for guidance immediately and do not proceed
7. **STAY ON COURSE**: Follow the specified approach exactly - no shortcuts or alternatives
8. **INTERACTIVE RESOLUTION**: For any error or uncertainty, pause, document the issue, and ask for user input before trying fixes; be methodical step-by-step
## Environment Setup:
- Initialize a git repo in current directory: 'k8s-cluster-build'
- You can SSH as root to all VMs from this WSL2 terminal
- VMs: 192.168.0.100, .101, .102 (masters) and .103, .104 (workers)
- All running Ubuntu 24.04 LTS (cgroup v2 default)
- VIP for HA: 192.168.0.200
## Software Versions (August 2025):
- Kubernetes: v1.33.4 (latest GA)
- containerd: v2.1.4 (v1.7.x reached EOL May 5, 2025)
- Multus CNI: v4.2.2
- Cilium CNI: v1.18.0 (non-exclusive mode required)
- Longhorn: v1.9.0
- KubeVirt: v1.5.0
- kube-vip: v1.0.0
- metrics-server: v0.8.0
- Dashboard: v7.13.0 (Helm-only, uses Kong gateway)
- Ingress-NGINX: v1.13.1 (CVE-2025-1974 fixed)
## Git Workflow Process:
### CRITICAL EXECUTION REQUIREMENTS:
- **No time constraints**: Take as long as necessary to ensure correctness
- **Exact versions only**: Install ONLY the specified versions (K8s 1.33.4, containerd 2.1.4, etc.)
- **No workarounds**: Do NOT use mocks, stubs, or workarounds without explicit permission
- **Discovery first**: When issues arise, perform thorough discovery before attempting fixes
- **Step-by-step resolution**: Resolve problems incrementally with full documentation
- **Search when needed**: Use web_search for current information if documentation is unclear
- **Document everything**: Record every command, output, and decision in git history
- **Stay on target**: Adhere to original requirements and specified methods
### Workflow Steps:
For EACH major step:
1. Create a feature branch: git checkout -b 'step-XX-description'
2. **Discovery Phase**:
   - Check current state of all nodes
   - Verify prerequisites for this step
   - Search for any version-specific requirements
   - Document findings in discovery-XX.log
3. **Implementation Phase**:
   - Execute actual commands on VMs
   - Use EXACT version numbers specified
   - If version unavailable, STOP and ask for guidance
   - Capture all outputs (success and errors)
4. **Verification Phase**:
   - Create/update relevant files (state, configs, test results, logs)
   - Run comprehensive tests to verify the step
   - Confirm installed versions match specifications exactly
5. **Documentation Phase**:
   - Record all commands executed in commands-XX.log
   - Save all configuration files as deployed
   - Document any issues encountered and resolutions
   - Capture system state after completion
6. **Commit & Merge**:
   - Commit with detailed message including:
     - What was done
     - Exact versions installed
     - Any issues encountered and how resolved
     - Test results summary
   - If tests pass: merge to main with squash commit
   - If tests fail: document failure, investigate root cause, retry
7. **Issue Resolution Process** (if problems occur):
   - STOP and document the exact error
   - Use discovery commands to understand the issue
   - Search for solution specific to our versions
   - Try solution and document result
   - If stuck, ask for permission before any workaround
   - Never skip or substitute components
8. Tag important milestones (e.g., v0.1-infra-ready, v1.0-cluster-init)
### Version Compliance & Problem Resolution:
**MANDATORY**: Every component MUST be the exact version specified:
- Kubernetes: v1.33.4 (not 1.33.3, not 1.33.5, exactly 1.33.4)
- containerd: v2.1.4 (not 2.1.3, not 2.1.5, exactly 2.1.4)
- Multus: v4.2.2 (not 4.2.1, not 4.2.3, exactly 4.2.2)
- Cilium: v1.18.0 (not 1.17.x, not 1.18.1, exactly 1.18.0; cni.exclusive=false)
- Longhorn: v1.9.0 (not 1.8.x, not 1.9.1, exactly 1.9.0)
- KubeVirt: v1.5.0 (not 1.4.x, not 1.5.1, exactly 1.5.0)
- ALL other components: exact versions as specified
**When Version Issues Occur**:
1. Document the exact issue (e.g., "Package containerd 2.1.4 not found in repository")
2. Search for official repository or download location for that exact version
3. If official sources don't have it, check archive repositories
4. Document all attempted sources in version-search-XX.log
5. NEVER substitute a different version without explicit permission
6. If stuck, pause and ask: "Version X.Y.Z is not available via method A. Should I try method B or would you prefer an alternative approach?"
**Documentation Requirements**:
Every step must generate:
- `commands-XX.log`: Every command executed with timestamps
- `outputs-XX.log`: All command outputs (stdout and stderr)
- `discovery-XX.log`: All investigation/debugging activities
- `decisions-XX.md`: Why specific approaches were chosen
- `issues-XX.md`: Problems encountered and how resolved
- `state-XX.json`: System state after step completion
## Major Steps to Execute:
### Step 01: Initial Connectivity & Inventory
- Branch: 'step-01-verify-connectivity'
- Actions:
  - SSH to all nodes, gather system info (CPU, RAM, disk, network)
  - Verify Ubuntu 24.04 LTS and kernel versions
  - Check network connectivity between all nodes
  - Validate DNS resolution
  - Verify cgroup v2 is active (Ubuntu 24.04 default)
- Files:
  - inventory.json with detailed node specifications
  - network-matrix.yaml showing inter-node connectivity
  - system-requirements-check.json
  - cgroup-status.json
- Tests: All nodes reachable, minimum resources met (4GB RAM control plane, 2GB workers), network latency <1ms, cgroup v2 confirmed
### Step 02: System Prerequisites
- Branch: 'step-02-system-prerequisites'
- Actions:
  - Disable swap permanently (swapoff -a, edit /etc/fstab)
  - Load kernel modules (br_netfilter, overlay, ip_vs*)
  - Configure sysctl for Kubernetes networking
  - Set up firewall rules for K8s ports
  - Configure time synchronization (chrony)
  - Verify systemd as cgroup manager (Ubuntu 24.04 default)
- Files:
  - system-config.yaml with all applied settings
  - firewall-rules.json with port mappings
  - kernel-modules.conf as deployed
  - sysctl-kubernetes.conf
- Tests: Swap off, modules loaded, IP forwarding enabled, firewall configured, time synced, systemd cgroup confirmed
### Step 03: Container Runtime
- Branch: 'step-03-containerd-install'
- Actions:
  - Install containerd v2.1.4 (note: v1.7.x is EOL as of May 5, 2025)
  - Configure systemd cgroup driver (matches kubelet)
  - Set up container runtime with proper cgroup v2 settings
  - Configure containerd for Kubernetes CRI
  - Enable container runtime metrics
- Files:
  - containerd-config.toml with systemd cgroup driver
  - cri-socket.conf with socket paths (/run/containerd/containerd.sock)
  - registry-mirrors.yaml if configured
  - containerd-version-info.json
- Tests: containerd v2.1.4 running, systemd cgroup driver active, crictl info working, metrics endpoint responding
### Step 04: Kubernetes Packages
- Branch: 'step-04-kubernetes-packages'
- Actions:
  - Add Kubernetes v1.33.4 apt repositories
  - Install kubeadm, kubelet, kubectl (v1.33.4)
  - Hold packages to prevent auto-updates
  - Configure kubelet with systemd cgroup driver
  - Enable kubelet certificate rotation
  - Set up kubectl bash completion
- Files:
  - kubernetes-versions.json (all components v1.33.4)
  - kubelet-config.yaml with systemd cgroup driver
  - apt-preferences showing held packages
  - kubelet-extra-args.env
- Tests: kubeadm version 1.33.4, kubelet configured for systemd, kubectl working, cert rotation enabled
### Step 05: HA Infrastructure Setup
- Branch: 'step-05-ha-infrastructure'
- Actions:
  - Install kube-vip v1.0.0 on all masters
  - Configure VIP at 192.168.0.200
  - Set up etcd encryption at rest for Secrets
  - Configure audit logging policies
  - Enable Pod Security Admission (PSA) - stable since K8s 1.25
  - Prepare kubeadm config with HA settings
- Files:
  - kube-vip-manifest.yaml (v1.0.0 static pod)
  - etcd-encryption-config.yaml
  - audit-policy.yaml
  - kubeadm-config.yaml with controlPlaneEndpoint: 192.168.0.200:6443
  - psa-config.yaml (pod-security.kubernetes.io labels)
- Tests: VIP pingable at 192.168.0.200, kube-vip v1.0.0 manifests ready, encryption config valid
### Step 06: Initialize First Master
- Branch: 'step-06-init-first-master'
- Actions:
  - Run kubeadm init with HA config on master1
  - Specify Kubernetes v1.33.4 explicitly
  - Configure pod and service CIDRs (10.244.0.0/16, 10.96.0.0/12)
  - Enable audit logging and PSA
  - Configure kubectl for admin access
  - Save join tokens and certificates
- Files:
  - kubeadm-init-output.log with join commands
  - cluster-info.json with endpoints (VIP: 192.168.0.200:6443)
  - admin.conf kubeconfig
  - join-tokens.encrypted (git-ignored but documented)
  - control-plane-certificates.json
- Tests: API server responding on https://192.168.0.200:6443, all control plane pods Running, kubectl cluster-info working
### Step 07: Join Control Planes
- Branch: 'step-07-join-control-planes'
- Actions:
  - Join master2 and master3 as control plane nodes
  - Verify etcd cluster formation (3 members for quorum)
  - Test HA failover by stopping master1 API server briefly
  - Configure etcd backup cronjob (daily minimum)
  - Verify load balancing across all 3 API servers
  - Enable graceful node shutdown feature
- Files:
  - control-plane-status.json (3 masters Ready)
  - etcd-member-list.json (3 healthy members)
  - ha-failover-test.log
  - etcd-backup-cronjob.yaml
  - graceful-shutdown-config.yaml
- Tests: All 3 masters Ready, etcd cluster healthy with quorum, failover <30 seconds, API accessible via VIP
### Step 08: Install Multus CNI
- Branch: 'step-08-multus-cni'
- Actions:
  - Install Multus v4.2.2 as meta CNI plugin
  - Configure Multus to enable multiple network interfaces for pods
  - Set up default delegate to point to Cilium (to be installed next)
  - Apply CRDs for NetworkAttachmentDefinitions
  - Verify Multus daemonset deployment
- Files:
  - multus-v4.2.2-daemonset.yaml
  - multus-config.yaml
  - network-attachment-crd.yaml
  - multus-status.json
- Tests: Multus v4.2.2 pods running on all nodes, CRDs installed, no errors in logs
### Step 09: Install Cilium CNI
- Branch: 'step-09-cilium-cni'
- Actions:
  - Install Cilium v1.18.0 via Helm with cni.exclusive=false for non-exclusive mode
  - Configure IP pools with pod CIDR 10.244.0.0/16
  - Enable eBPF dataplane if compatible (requires disabling kube-proxy)
  - Configure IPAM settings
  - Apply initial NetworkPolicies for security
  - Document eBPF vs standard dataplane choice
  - Ensure compatibility with Multus for chaining
- Files:
  - cilium-v1.18.0-helm-values.yaml (with cni.exclusive=false)
  - cilium-ippool.yaml (10.244.0.0/16)
  - network-policies/default-deny.yaml
  - ebpf-decision.md (if eBPF enabled, note kube-proxy disabled)
  - cilium-status.json
- Tests: Cilium v1.18.0 running in non-exclusive mode, pods get IPs from 10.244.0.0/16, pod-to-pod communication working, Multus integration confirmed
### Step 10: Install Longhorn
- Branch: 'step-10-longhorn-install'
- Actions:
  - Install Longhorn v1.9.0 via Helm
  - Configure default settings for storage (replicas=3, etc.)
  - Set up storage classes and persistent volume support
  - Verify Longhorn manager and engine deployments
  - Test basic volume creation and attachment
- Files:
  - longhorn-v1.9.0-helm-values.yaml
  - longhorn-storageclass.yaml
  - longhorn-status.json
  - test-volume.yaml
- Tests: Longhorn v1.9.0 pods running, storage class available, test PVC bound and usable
### Step 11: Join Workers
- Branch: 'step-11-join-workers'
- Actions:
  - Join worker1 and worker2 to cluster
  - Label nodes (node-role.kubernetes.io/worker=true)
  - Configure resource reservations (system-reserved, kube-reserved)
  - Set up pod eviction thresholds
  - Verify pod scheduling across workers
  - Configure PodDisruptionBudgets for system components
- Files:
  - complete-node-list.json (5 nodes total)
  - node-labels-taints.yaml
  - resource-reservations.yaml
  - pod-distribution.json
  - system-pdb.yaml
- Tests: All 5 nodes Ready, pods scheduling on workers, resource limits applied, workload distribution balanced
### Step 12: Install KubeVirt with Bridged Networking
- Branch: 'step-12-kubevirt-install'
- Actions:
  - Install KubeVirt v1.5.0 operator and CR via manifests/Helm
  - Create NetworkAttachmentDefinition for bridged networking using Multus (e.g., bridge CNI plugin)
  - Configure KubeVirt for bridged interfaces (macvtap or bridge mode)
  - Deploy test VM with bridged network attachment
  - Verify VM connectivity via bridged network
  - Ensure Cilium non-exclusive mode allows Multus attachments
- Files:
  - kubevirt-v1.5.0-operator.yaml
  - kubevirt-cr.yaml
  - bridged-nad.yaml (NetworkAttachmentDefinition for bridge)
  - test-vm.yaml (with bridged interface)
  - kubevirt-status.json
- Tests: KubeVirt v1.5.0 running, NAD created, test VM starts with bridged network, VM has external connectivity, no conflicts with Cilium
### Step 13: Core Monitoring
- Branch: 'step-13-monitoring-core'
- Actions:
  - Deploy metrics-server v0.8.0 (released July 2025)
  - Configure HA deployment with 2+ replicas
  - Install kube-state-metrics
  - Set up Prometheus node-exporter
  - Configure resource requests/limits
  - Enable kubectl top commands
- Files:
  - metrics-server-v0.8.0-values.yaml
  - kube-state-metrics-config.yaml
  - node-exporter-daemonset.yaml
  - monitoring-rbac.yaml
  - resource-metrics.json
- Tests: kubectl top nodes/pods working, metrics-server v0.8.0 running, all metrics endpoints healthy
### Step 14: Ingress & Dashboard
- Branch: 'step-14-ingress-dashboard'
- Actions:
  - Install Ingress-NGINX v1.13.1 (CVE-2025-1974 fixed)
  - Deploy Kubernetes Dashboard v7.13.0 via Helm (mandatory method)
  - Configure Kong gateway (Dashboard v7 requirement)
  - Set up RBAC with least-privilege (avoid cluster-admin)
  - Create read-only and admin ServiceAccounts
  - Configure NodePort (30443) or Ingress access
  - Install cert-manager for TLS certificates
- Files:
  - ingress-nginx-v1.13.1-values.yaml
  - dashboard-v7.13.0-helm-values.yaml
  - kong-gateway-config.yaml
  - dashboard-rbac-least-privilege.yaml
  - dashboard-ingress.yaml
  - cert-manager-config.yaml
- Tests: Ingress-NGINX v1.13.1 running, Dashboard accessible, Kong gateway healthy, RBAC working, TLS certificates valid
### Step 15: Test Applications
- Branch: 'step-15-test-deployment'
- Actions:
  - Deploy test nginx with 3 replicas
  - Configure PodDisruptionBudget (minAvailable: 2)
  - Create LoadBalancer and NodePort services
  - Set up HorizontalPodAutoscaler (HPA)
  - Configure Ingress routing with TLS
  - Test rolling updates with zero downtime
  - Simulate node failure and recovery
- Files:
  - test-apps/nginx-deployment.yaml
  - test-apps/nginx-pdb.yaml
  - test-apps/services.yaml
  - test-apps/hpa-config.yaml
  - test-apps/ingress-tls.yaml
  - test-results/rolling-update.log
  - test-results/node-failure-recovery.json
- Tests: App accessible via Ingress, PDB enforced, HPA scaling (requires metrics-server v0.8.0), zero-downtime updates verified
### Step 16: Final Validation & Documentation
- Branch: 'step-16-cluster-validation'
- Actions:
  - Run comprehensive cluster health checks
  - Verify all component versions match specifications
  - Test etcd backup and restore procedure
  - Performance baseline (API <100ms p99, etcd <10ms p99)
  - Generate CIS Kubernetes Benchmark report
  - Create user-friendly validation script
  - Document all access methods and credentials
  - Set up Velero for backup (optional)
  - Validate KubeVirt bridged networking and Longhorn storage
- Files:
  - cluster-validation-report.json
  - component-versions.yaml (verify all match spec)
  - cis-benchmark-report.html (target >95% score)
  - performance-baseline.json
  - validate-cluster.sh (comprehensive check script)
  - access-guide.md (Dashboard URL, tokens, kubectl config)
  - backup-restore-test.log
  - health-check-endpoints.json
- Tests:
  - All nodes Ready (5 total)
  - Kubernetes v1.33.4 confirmed
  - All specified versions correct
  - Zero pods in Error/CrashLoop
  - etcd latency <10ms p99
  - API latency <100ms p99
  - DNS resolution working (cluster.local)
  - Dashboard accessible (Kong gateway healthy)
  - Ingress routing functional
  - PSA policies enforced
  - Audit logs capturing events
  - Certificate rotation configured
  - CIS score >95%
  - Longhorn volumes working
  - KubeVirt VMs with bridged networks operational
## Repository Structure:
k8s-cluster-build/
├── .git/
├── README.md (living documentation)
├── VERSIONS.md (track all component versions)
├── steps/
│ ├── 01-connectivity/
│ ├── 02-prerequisites/
│ ├── 03-containerd/
│ ├── 04-kubernetes/
│ ├── 05-ha-setup/
│ ├── 06-init-master/
│ ├── 07-join-masters/
│ ├── 08-multus/
│ ├── 09-cilium/
│ ├── 10-longhorn/
│ ├── 11-join-workers/
│ ├── 12-kubevirt/
│ ├── 13-monitoring/
│ ├── 14-dashboard/
│ ├── 15-test-apps/
│ └── 16-validation/
├── configs/
│ ├── containerd-v2.1.4.toml
│ ├── multus-v4.2.2.yaml
│ ├── cilium-v1.18.0.yaml
│ ├── longhorn-v1.9.0.yaml
│ ├── kubevirt-v1.5.0.yaml
│ ├── dashboard-helm-values.yaml
│ └── ... (all deployed configs)
├── scripts/
│ ├── validate-cluster.sh
│ ├── backup-etcd.sh
│ └── health-check.sh
├── docs/
│ ├── architecture.md
│ ├── security.md
│ ├── disaster-recovery.md
│ └── troubleshooting.md
└── tests/
└── test-results/
text## Important Version-Specific Notes:
1. **containerd v2.1.4**: Version 1.7.x reached EOL on May 5, 2025. Must use v2.x
2. **Cilium v1.18.0**: Must set cni.exclusive=false for Multus compatibility; supports eBPF but requires disabling kube-proxy if enabled
3. **Multus v4.2.2**: Enables multiple interfaces; configure with Cilium as delegate
4. **Longhorn v1.9.0**: Persistent storage for stateful workloads
5. **KubeVirt v1.5.0**: For virtualization; use Multus for bridged networking via NetworkAttachmentDefinitions
6. **Dashboard v7.13.0**: No longer supports kubectl apply. Must use Helm. Uses Kong gateway
7. **Ubuntu 24.04**: Cgroup v2 is default, systemd is the cgroup driver
8. **PSA**: Pod Security Admission is stable and should be enabled
9. **Ingress-NGINX v1.13.1**: Includes critical security fix for CVE-2025-1974
## Git Tags to Apply:
- v0.1-infrastructure-ready (after step 02)
- v0.2-runtime-ready (after step 03)
- v0.5-ha-configured (after step 05)
- v1.0-cluster-initialized (after step 07)
- v1.2-networking-ready (after step 09)
- v1.3-storage-ready (after step 10)
- v1.5-workers-joined (after step 11)
- v1.6-virtualization-ready (after step 12)
- v2.0-monitoring-enabled (after step 13)
- v2.5-ingress-ready (after step 14)
- v3.0-production-ready (after step 16)
## Final Validation Script (validate-cluster.sh):
The script should verify:
- Component versions match spec (K8s 1.33.4, containerd 2.1.4, etc.)
- All 5 nodes Ready
- Control plane HA working (VIP 192.168.0.200)
- All system pods Running
- Metrics available (metrics-server v0.8.0)
- Dashboard accessible via Kong gateway
- Ingress controller serving traffic
- Network policies enforced
- PSA policies active
- Display access URLs and tokens
- Show resource usage summary
- Longhorn storage operational
- KubeVirt VMs with bridged networking functional
- Cilium in non-exclusive mode
Begin by creating the repository and initial README.md documenting the Kubernetes 1.33.4 deployment process."
Summary of Critical Updates:
Version Changes:

Kubernetes: Remains v1.33.4 (latest as of August 24, 2025)
containerd: Remains v2.1.4
kube-vip: Remains v1.0.0
metrics-server: Remains v0.8.0
Dashboard: Remains v7.13.0
Ingress-NGINX: Remains v1.13.1
Removed Calico (replaced by Multus + Cilium)
Added Multus: v4.2.2
Added Cilium: v1.18.0
Added Longhorn: v1.9.0
Added KubeVirt: v1.5.0

Key Implementation Changes:

Replaced Calico with Multus (Step 08) and Cilium in non-exclusive mode (Step 09) for KubeVirt compatibility
Added Longhorn installation (new Step 10) immediately after CNI setup
Added KubeVirt installation with bridged networking (new Step 12), using Multus NetworkAttachmentDefinitions
Shifted subsequent steps and updated tags/repository structure accordingly
Enhanced interactivity: Explicitly require pausing and asking for input on any uncertainty
Dashboard v7 requires Helm installation (kubectl apply no longer works)
Dashboard uses Kong gateway for routing
containerd must use systemd cgroup driver to match kubelet
Cilium non-exclusive mode (cni.exclusive=false) required for Multus chaining
PSA (Pod Security Admission) should be enabled as it's stable
Focus on least-privilege RBAC instead of cluster-admin tokens
