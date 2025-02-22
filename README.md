# D-ployementAppwithK8s_MonitorwithPrometheus-Grafana
Déployement une application NextJs sur K8s et la surveiller en utilisant Prometheus et Grafana

// Install Docker - K8s 
nano or vim install-k8s.sh
chmod +x install-k8s.sh
./install-k8s.sh

// install Helm 
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

// Create Namespace
kubectl create namespace monitoring

// Ajouter le Repo Helm pour Prometheus & Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

//Installer Prometheus, Grafana et Alertmanager

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.service.type=ClusterIP \
  --set prometheus.service.type=ClusterIP \
  --set alertmanager.service.type=ClusterIP


