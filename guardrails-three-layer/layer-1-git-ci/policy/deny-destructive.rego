package main

# Deny deletion of protected system namespaces.
deny[msg] {
    input.kind == "Namespace"
    protected := {"kube-system", "kube-public", "kube-node-lease", "default", "kyverno", "argocd", "flux-system"}
    protected[input.metadata.name]
    input.metadata.deletionTimestamp
    msg := sprintf("Refusing to delete protected namespace %q", [input.metadata.name])
}

# Deny Deployment containers that do not explicitly set runAsNonRoot.
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.runAsNonRoot
    msg := sprintf("Container %q must set securityContext.runAsNonRoot=true", [container.name])
}

# Deny privileged containers anywhere.
deny[msg] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Container %q runs privileged; forbidden.", [container.name])
}

# Deny host namespace sharing.
deny[msg] {
    input.kind == "Pod"
    input.spec.hostNetwork == true
    msg := "hostNetwork: true is forbidden."
}
deny[msg] {
    input.kind == "Pod"
    input.spec.hostPID == true
    msg := "hostPID: true is forbidden."
}
deny[msg] {
    input.kind == "Pod"
    input.spec.hostIPC == true
    msg := "hostIPC: true is forbidden."
}
