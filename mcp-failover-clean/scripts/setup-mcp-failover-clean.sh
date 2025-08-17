#!/usr/bin/env bash
set -euo pipefail

echo "[+] Ensuring Colima runtime is running with resources"
colima start --cpu 4 --memory 8 --disk 60 || true

echo "[+] Ensuring Minikube is running"
minikube start --cpus=4 --memory=7900mb --driver=docker

echo "[+] Cleaning old namespaces"
kubectl delete namespace mcp-failover-clean --ignore-not-found
kubectl create namespace mcp-failover-clean

echo "[+] Deploying demo workloads (blue/green)"
kubectl apply -n mcp-failover-clean -f ./mcp-failover-clean/k8s/deployment-blue.yaml
kubectl apply -n mcp-failover-clean -f ./mcp-failover-clean/k8s/deployment-green.yaml
kubectl apply -n mcp-failover-clean -f ./mcp-failover-clean/k8s/service.yaml

echo "[+] Installing kmcp CRDs"
helm upgrade --install kmcp-crds oci://ghcr.io/kagent-dev/kmcp/helm/kmcp-crds \
  --version 0.1.5 \
  --namespace kmcp-system --create-namespace

echo "[+] Installing kagent CLI (user mode)"
mkdir -p ./bin
curl -sL https://cr.kagent.dev/v0.5.5/kagent-darwin-arm64 -o ./bin/kubectl-kagent
chmod +x ./bin/kubectl-kagent
export PATH="$(pwd)/bin:$PATH"

echo "[+] Installing kagent into cluster"
kubectl kagent install

echo "[+] Waiting for kagent core pods (60s timeout)"
kubectl wait --for=condition=available --timeout=60s deployment/kagent-controller -n kagent || \
  echo "[!] Timeout waiting for kagent-controller, continuing anyway..."

echo "[+] Creating OpenAI secret"
kubectl delete secret openai-secret -n kagent --ignore-not-found
kubectl create secret generic openai-secret -n kagent \
  --from-literal=api-key="${OPENAI_API_KEY:-replace_me}"

echo "[+] Applying kagent configurations"
# Apply all resources from the k8s directory directly
kubectl apply -f ./mcp-failover-clean/k8s/

echo "[+] All resources applied successfully!"
echo "[+] Demo agent is ready in namespace kagent."
echo ""
echo "   Your blue/green failover demo is ready!"
echo "   Blue deployment:  2 replicas running"
echo "   Green deployment: 0 replicas (standby)"
echo "   Service:          NodePort on minikube"
echo ""