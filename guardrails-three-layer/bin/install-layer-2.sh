#!/usr/bin/env bash
# ABOUTME: Apply Layer 2 Kubernetes guardrails (Kyverno + RBAC + NetworkPolicy) to the current kubectl context.
# ABOUTME: Does NOT install Kyverno itself - you must install the controller first (see layer-2-kubernetes/README.md).
set -euo pipefail

if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl not found on PATH." >&2
    exit 1
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "kubectl cluster-info failed. Point kubectl at a cluster first." >&2
    exit 2
fi

CTX="$(kubectl config current-context)"
cat <<EOF
About to apply Layer 2 resources to:
    context: ${CTX}
    server:  $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

Manifests:
    - Kyverno ClusterPolicies (Audit mode)
    - ai-workspace namespace + least-priv RBAC
    - NetworkPolicy: default-deny + IMDS block
    - ValidatingAdmissionPolicy (K8s 1.30+)
EOF
read -r -p "Continue? [y/N] " ans
[[ "${ans}" =~ ^[yY]$ ]] || { echo "Aborted."; exit 0; }

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/layer-2-kubernetes"

echo
echo "Applying Kyverno ClusterPolicies (Audit mode)"
if kubectl get crd clusterpolicies.kyverno.io >/dev/null 2>&1; then
    kubectl apply -f "${SRC}/kyverno/"
else
    echo "  Kyverno CRDs not found. Install Kyverno first:"
    echo "    helm install kyverno kyverno/kyverno -n kyverno --create-namespace --set replicaCount=3"
fi

echo
echo "Applying ai-workspace namespace + RBAC"
kubectl apply -f "${SRC}/rbac/ai-agent.yaml"

echo
echo "Applying NetworkPolicies"
kubectl apply -f "${SRC}/networkpolicies/ai-workspace.yaml"

echo
echo "Applying ValidatingAdmissionPolicy (K8s 1.30+)"
if kubectl api-resources | grep -q validatingadmissionpolicies; then
    kubectl apply -f "${SRC}/vap/deny-privileged.yaml"
else
    echo "  ValidatingAdmissionPolicy not available on this API server. Skipping."
fi

cat <<'EOF'

Layer 2 core applied in Audit mode.

Next steps:

  1) Install Falco if you haven't:
       helm install falco falcosecurity/falco -n falco --create-namespace \
         --values layer-2-kubernetes/falco/values.yaml

  2) Watch PolicyReports for one week to check for false positives:
       kubectl get policyreports -A -w

  3) After the audit period, flip the ClusterPolicies to Enforce:
       sed -i 's/validationFailureAction: Audit/validationFailureAction: Enforce/g' \
         layer-2-kubernetes/kyverno/*.yaml
       kubectl apply -f layer-2-kubernetes/kyverno/

EOF
