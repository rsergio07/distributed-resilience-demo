#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="distributed-resilience"

echo "[+] Starting Colima (if not running)"
colima status --runtime docker >/dev/null 2>&1 || colima start --runtime docker

echo "[+] Starting Minikube (if not running)"
minikube status >/dev/null 2>&1 || minikube start

echo "[+] Enabling metrics-server addon"
minikube addons enable metrics-server
kubectl -n kube-system rollout status deployment/metrics-server

echo "[+] Using Minikube Docker daemon to build local image"
eval "$(minikube docker-env)"

echo "[+] Building Docker image 'resilience-demo:1.0'"
docker build -t resilience-demo:1.0 .

echo "[+] Applying Kubernetes manifests"
kubectl apply -f k8s/namespace.yaml
kubectl -n "$NAMESPACE" apply -f k8s/deployment-blue.yaml
kubectl -n "$NAMESPACE" apply -f k8s/deployment-green.yaml
kubectl -n "$NAMESPACE" apply -f k8s/hpa-blue.yaml
kubectl -n "$NAMESPACE" apply -f k8s/hpa-green.yaml
kubectl -n "$NAMESPACE" apply -f k8s/service.yaml

echo "[+] Waiting for deployments to be ready"
kubectl -n "$NAMESPACE" rollout status deployment/web-blue
kubectl -n "$NAMESPACE" rollout status deployment/web-green

echo "[+] Checking cluster metrics"
kubectl top nodes || echo "[!] Warning: metrics not available yet (retry in a few seconds)"
kubectl -n "$NAMESPACE" top pods || echo "[!] No pods to show yet"

echo "[+] Service NodePort URL:"
minikube service web -n "$NAMESPACE" --url
