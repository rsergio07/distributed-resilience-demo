#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="distributed-resilience"
IMAGE_TAG="resilience-demo:1.0"

echo "[+] Ensuring Colima (Docker runtime) is running"
colima status --runtime docker >/dev/null 2>&1 || colima start --runtime docker

echo "[+] Starting Minikube with docker driver (uses current docker context)"
# If cluster already exists, this is a no-op
minikube status >/dev/null 2>&1 || minikube start --driver=docker

echo "[+] Enabling metrics-server addon"
minikube addons enable metrics-server
kubectl -n kube-system rollout status deployment/metrics-server

echo "[+] Building image on host Docker (Colima): ${IMAGE_TAG}"
# Build on the host so we don’t depend on network inside Minikube
docker build -t "${IMAGE_TAG}" .

echo "[+] Loading image into Minikube cache"
minikube image load "${IMAGE_TAG}"

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
kubectl top nodes || echo "[!] metrics may take ~15-30s to appear"
kubectl -n "$NAMESPACE" top pods || true

echo "[+] Service NodePort URL:"
minikube service web -n "$NAMESPACE" --url
