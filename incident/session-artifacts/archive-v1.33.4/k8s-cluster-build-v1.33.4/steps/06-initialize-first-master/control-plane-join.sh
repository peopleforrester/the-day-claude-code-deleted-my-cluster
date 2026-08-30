#!/bin/bash
# Join command for control plane nodes
kubeadm join 192.168.0.200:6443 --token <REDACTED-KUBEADM-TOKEN> \
	--discovery-token-ca-cert-hash sha256:4b39b4e58fbaddba3424dc38184cb11ee5bd0ae0578ffd763bde00921e8bdd46 \
	--control-plane --certificate-key edb097cdda22eb6bcf9d4fb5d1f5eb9d27a6f40514f2af4d2d658b4394d2329e
