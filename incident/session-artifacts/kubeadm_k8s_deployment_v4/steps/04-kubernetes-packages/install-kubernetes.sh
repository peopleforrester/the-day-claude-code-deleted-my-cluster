#\!/bin/bash
# Install Kubernetes packages (kubeadm, kubelet, kubectl)

# Add Kubernetes apt repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

# Update package index
apt-get update

# Install Kubernetes packages
apt-get install -y kubelet kubeadm kubectl

# Hold packages to prevent automatic updates
apt-mark hold kubelet kubeadm kubectl

# Enable kubelet service
systemctl enable kubelet

echo "Kubernetes packages installed successfully"
kubeadm version
kubectl version --client
kubelet --version
