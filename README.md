Je vais créer un README.md complet pour votre projet.

```markdown
# Kubernetes Cluster Deployment with Prometheus & Grafana Monitoring

## 📋 Projet Overview
Ce projet automatise le déploiement d'une infrastructure Kubernetes avec surveillance complète utilisant Prometheus, Grafana et Alertmanager.

## 🚀 Fonctionnalités
- Configuration de cluster Kubernetes
- Installation de Prometheus
- Monitoring avec Grafana
- Alertes via Alertmanager
- Déploiement d'applications conteneurisées

## 🔧 Prérequis
- 3 machines Linux (1 master, 2 workers)
- Ubuntu 20.04+ recommandé
- Minimum requis :
  * Master : 2 CPU, 4 Go RAM
  * Workers : 2 CPU, 4 Go RAM chacun
- Accès sudo
- Connexion internet stable

## 📦 Préparation de l'Infrastructure

### 1. Configuration Initiale (Sur toutes les machines)
```bash
# Mise à jour système
sudo apt update && sudo apt upgrade -y

# Désactiver le swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Configuration modules réseau
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configuration sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### 2. Installation de Docker et Containerd
```bash
# Installation Docker
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Configuration Containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
```

### 3. Installation de Kubernetes
```bash
# Dépôts et clés Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Installation des composants
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### 4. Initialisation du Cluster Kubernetes (Master uniquement)
```bash
# Initialisation
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configuration kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Installation réseau (Flannel)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

### 5. Jointure des Workers
Sur le master :
```bash
kubeadm token create --print-join-command
```
Exécutez la commande générée sur CHAQUE worker avec sudo.

### 6. Installation de Helm
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 7. Déploiement de Prometheus, Grafana et Alertmanager
```bash
# Ajout des dépôts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Création namespace
kubectl create namespace monitoring

# Installation
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring \
  --set grafana.service.type=NodePort \
  --set prometheus.service.type=NodePort \
  --set alertmanager.service.type=NodePort
```

## 🔍 Vérification des Services
```bash
kubectl get services -n monitoring
```

## 🛠️ Configuration Supplémentaire
- Personnalisez les dashboards Grafana
- Configurez des règles d'alerte personnalisées
- Ajustez les métriques selon vos besoins

## 📈 Métriques Suivies
- Utilisation CPU/Mémoire
- État des pods et nœuds
- Performances réseau
- Métriques applicatives personnalisées

## 🚨 Alertes
Configuration des alertes via Alertmanager avec notifications Slack/Email.

