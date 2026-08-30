# Layer 2 — Kubernetes admission + runtime

**Build second. Requires cluster infrastructure. Catches destructive actions
at the cluster boundary even when the commit bypassed review.**

Two halves:

- **Admission time.** Kyverno (or OPA/Gatekeeper) intercepts writes at the
  API server. Blocks `kubectl delete ns kube-system` before etcd is touched.
- **Runtime.** Falco watches syscalls and audit events. Catches host-level
  actions the API server never saw (`kubeadm reset` over SSH on a node,
  `etcd --force-new-cluster`, `netplan apply`, `rm -rf /var/lib/etcd`).

You need both. The incident playbook has actions in both domains.

---

## Files in this directory

```
kyverno/
  01-protect-system-namespaces.yaml        block DELETE/UPDATE of kube-system et al.
  02-disallow-sensitive-hostpaths.yaml     block /etc/kubernetes, /var/lib/etcd, /etc/netplan mounts
  03-pss-baseline.yaml                     privileged, host ns, privilege escalation
  04-block-exec-kube-system.yaml           no kubectl exec into protected namespaces
  05-restrict-clusteradmin-binding.yaml    no new cluster-admin bindings
gatekeeper/
  protected-namespaces.yaml                 same namespace-protection policy in Rego
rbac/
  ai-agent.yaml                             least-priv ServiceAccount + Role + RoleBinding + Namespace
networkpolicies/
  ai-workspace.yaml                         default-deny + egress to kube-dns + IMDS block
pss/
  ai-agent-worker.yaml                      example hardened Pod spec for agent workloads
vap/
  deny-privileged.yaml                      ValidatingAdmissionPolicy (built-in, K8s 1.30+)
falco/
  falco-rules-ai-agent.yaml                 custom rules for the incident pattern
  values.yaml                               Helm values with modern_ebpf + falcosidekick
```

---

## Install

**One-time install of Kyverno + Falco:**

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

kubectl create ns kyverno 2>/dev/null || true
helm upgrade --install kyverno kyverno/kyverno -n kyverno \
  --set replicaCount=3 \
  --set admissionController.replicas=3 \
  --set admissionController.container.resources.limits.memory=1Gi

kubectl create ns falco 2>/dev/null || true
helm upgrade --install falco falcosecurity/falco -n falco \
  --values falco/values.yaml
```

**Apply the policies in Audit mode first (one week), then Enforce:**

```bash
# Audit mode: PolicyReports show what would have blocked, nothing rejected
kubectl apply -f kyverno/

# Watch the reports
kubectl get policyreports -A -w

# After a week with no false positives, flip to Enforce
sed -i 's/validationFailureAction: Audit/validationFailureAction: Enforce/g' kyverno/*.yaml
kubectl apply -f kyverno/
```

**Create the ai-workspace namespace with least-privilege RBAC:**

```bash
kubectl apply -f rbac/ai-agent.yaml
kubectl apply -f networkpolicies/ai-workspace.yaml
```

---

## Verify

**The first check that would have stopped the talk's incident:**

```bash
# Should be denied
kubectl delete ns kube-system
# Kyverno: validation error: Deletion of protected namespace 'kube-system' is not allowed.
```

**Privileged pod block:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: badpod, namespace: default }
spec:
  containers:
    - name: c
      image: busybox
      securityContext: { privileged: true }
EOF
# Kyverno denies.
```

**Falco destructive-command trip:**

```bash
# On a node Falco covers, run:
kubeadm reset  # DO NOT actually confirm 'y' on a real cluster
# Falco should emit EMERGENCY: kubeadm reset executed.
```

---

## Kyverno vs Gatekeeper — pick one

| Dimension                   | Kyverno                 | OPA/Gatekeeper         |
|-----------------------------|-------------------------|------------------------|
| Language                    | YAML (K8s-native)       | Rego DSL               |
| Learning curve              | Low                     | Steep                  |
| Mutation                    | First-class             | Limited                |
| Generation (new resources)  | Yes                     | No                     |
| Image verification          | Cosign first-class      | External tool          |
| Non-K8s use                 | K8s-only                | General-purpose        |
| Managed offerings           | -                       | Azure Policy, GKE PC   |

**Pick Kyverno** for K8s-only, YAML-first, need mutation/generation.
**Pick Gatekeeper** when Rego is already in your stack. They coexist as
separate validating webhooks.

---

## What admission control cannot catch (and why Falco exists)

- **Host commands.** `kubeadm reset`, `etcdctl` on a local socket,
  `rm -rf /var/lib/etcd` from SSH. API server never sees them.
- **Kubelet bypass.** Direct hits on `https://node:10250/pods`.
- **Already-running privileged pods.** `kubectl exec` into an existing one
  skips admission.
- **`failurePolicy: Ignore`** on the webhook. Run three replicas, set
  `failurePolicy: Fail`, narrow the exclusions.

See: [../docs/three-layers.md](../docs/three-layers.md#layer-2-kubernetes-admission-control-and-runtime-detection)

---

## Operational cost budget

- Kyverno: 3 replicas × ~1 GiB RAM
- Falco: DaemonSet (1 pod/node) with modern_ebpf driver, ~256 MiB RAM each
- OPA/Gatekeeper (if using): 3 replicas × ~512 MiB
- Falcosidekick: 1 replica × ~128 MiB
- Tuning time: measure in engineering weeks, not days. Start in Audit, read
  PolicyReports, then flip to Enforce.
