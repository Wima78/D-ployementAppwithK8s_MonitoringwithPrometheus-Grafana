#!/bin/bash

# Script d'installation complète de Kubernetes avec configuration du cluster
# Ce script installe les composants et configure un cluster single-node

# Fonction pour vérifier si une commande s'est bien exécutée
check_command() {
    if [ $? -ne 0 ]; then
        echo "Erreur: $1"
        exit 1
    fi
}

# Mettre à jour le système
echo "[1/9] Mise à jour du système..."
sudo apt-get update && sudo apt-get upgrade -y
check_command "Mise à jour du système échouée"

# Désactiver le swap
echo "[2/9] Désactivation du swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
check_command "Désactivation du swap échouée"

# Charger les modules nécessaires
echo "[3/9] Configuration des modules kernel..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
check_command "Configuration des modules kernel échouée"

# Paramètres réseau pour Kubernetes
echo "[4/9] Configuration des paramètres réseau..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
check_command "Configuration des paramètres réseau échouée"

# Installer Docker/containerd
echo "[5/9] Installation de containerd..."
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y containerd.io
check_command "Installation de containerd échouée"

# Configurer containerd
echo "[6/9] Configuration de containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
check_command "Configuration de containerd échouée"

# Installer kubeadm, kubelet et kubectl
echo "[7/9] Installation de Kubernetes..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
check_command "Installation de Kubernetes échouée"

# Initialiser le cluster
echo "[8/9] Initialisation du cluster Kubernetes..."
# Obtenir l'adresse IP principale
IP_ADDR=$(ip route get 8.8.8.8 | awk '{print $7; exit}')
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=$IP_ADDR
check_command "Initialisation du cluster échouée"

# Configurer kubectl pour l'utilisateur courant
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
check_command "Configuration de kubectl échouée"

# Installation et configuration du CNI (Calico)
echo "[9/9] Installation et configuration du CNI (Calico)..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml

# Attendre que le nœud soit prêt
echo "Attente que le nœud soit prêt..."
while ! kubectl get nodes | grep -q "Ready"; do
    echo "En attente que le nœud soit prêt..."
    sleep 10
done

# Permettre au master node d'héberger des pods (optionnel - enlever le taint)
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo "Installation et configuration du cluster Kubernetes terminées avec succès!"
echo "Votre cluster single-node est maintenant prêt à être utilisé."
echo "Pour vérifier l'état du cluster:"
echo "  kubectl get nodes"
echo "  kubectl get pods --all-namespaces"
