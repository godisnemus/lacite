# BASH script to install `kubeadm` on `Ubuntu 20.04.6 LTS (Focal Fossa)`
# Script must be executed as root
# Script must be executed from a clean boot

#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
  echo 'This script must be run by root' >&2
  exit 1
fi

# Upgrade
sudo apt-get update
sudo apt-get upgrade -y
sleep 3

# Disable swap
sudo swapoff -a
sudo rm -rf /swap.img
sudo sed -i '/[/]swap/ s/^/#/' /etc/fstab

# Network pre-requisites
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
sleep 3

# Install containerd
wget https://github.com/containerd/containerd/releases/download/v1.6.8/containerd-1.6.8-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.6.8-linux-amd64.tar.gz
wget https://github.com/opencontainers/runc/releases/download/v1.1.3/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz
sudo mkdir /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /etc/systemd/system/containerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sleep 3

# Install kubeadm, kubectl, kubelet
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo mkdir -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.25/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.25/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sleep 3

# Kubeadm init and basic configs
sudo kubeadm config images pull
sudo kubeadm init --pod-network-cidr 10.88.0.0/16
sleep 3

#Kubeconfig for root 
mkdir -pv $HOME/.kube
sudo cp -iv /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown -v $(id -u):$(id -g) $HOME/.kube/config
sleep 3

# Install Calico CNI
curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/calico.yaml -O
kubectl apply -f calico.yaml
sleep 3 

# Kubeconfig for user
# echo $SUDO_USER
mkdir -pv /home/$SUDO_USER/.kube
sudo cp -ivf /etc/kubernetes/admin.conf /home/$SUDO_USER/.kube/config
sudo chown -v $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.kube/config
sleep 3

# Kubernetes readiness
kubectl get all --namespace kube-system
sleep 3
# kubectl taint nodes --all node-role.kubernetes.io/control-plane-node/<...MASTER-NODE-NAME..> untainted

# Reboot
sudo reboot
