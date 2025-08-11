#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Distributed Resilience Demo - OFFLINE Deploy (tag-aware)
# ============================================================

NAMESPACE="distributed-resilience"
IMAGE_TAG="${IMAGE_TAG:-resilience-demo:1.1}"   # <— default new tag
APP_TAR="images/$(echo "$IMAGE_TAG" | tr ':/' '__').tar"

METRICS_IMAGE="registry.k8s.io/metrics-server/metrics-server:v0.7.2"
METRICS_TAR="images/metrics-server_v0.7.2.tar"

info()  { echo "[+] $*"; }
warn()  { echo "[!] $*" >&2; }
error() { echo "[x] $*" >&2; exit 1; }
need()  { command -v "$1" >/dev/null 2>&1 || error "Missing: $1"; }

need colima; need docker; need minikube; need kubectl

# 1) Runtime & driver
info "Ensuring Colima (Docker) is running with 4 CPUs / 6 GB RAM"
colima status --runtime docker >/dev/null 2>&1 || colima start --runtime docker --cpu 4 --memory 6 --disk 30
docker context use colima >/dev/null 2>&1 || true

info "Starting Minikube (docker driver, 4 CPU / 4 GB)"
minikube status >/dev/null 2>&1 || minikube start --driver=docker --cpus=4 --memory=4096

# 2) Preload metrics-server (from local or TAR)
if docker image inspect "${METRICS_IMAGE}" >/dev/null 2>&1; then
  info "Preloading metrics-server from local cache"
  minikube image load "${METRICS_IMAGE}" || true
elif [[ -f "${METRICS_TAR}" ]]; then
  info "Preloading metrics-server from TAR: ${METRICS_TAR}"
  minikube image load "${METRICS_TAR}" || true
else
  warn "metrics-server image not preloaded; addon will try to pull."
fi

info "Enabling metrics-server addon"
minikube addons enable metrics-server
kubectl -n kube-system rollout status deployment/metrics-server

# 3) Ensure APP image is available offline (cache or TAR), then preload to Minikube
if docker image inspect "${IMAGE_TAG}" >/dev/null 2>&1; then
  info "Found app image locally: ${IMAGE_TAG}"
else
  if [[ -f "${APP_TAR}" ]]; then
    info "Loading app image from TAR: ${APP_TAR}"
    docker load -i "${APP_TAR}"
  else
    error "App image ${IMAGE_TAG} not found and ${APP_TAR} missing. Run scripts/prepare-offline.sh first."
  fi
fi

info "Preloading app image into Minikube: ${IMAGE_TAG}"
minikube image load "${IMAGE_TAG}"

# 4) Apply manifests
info "Applying Kubernetes manifests"
kubectl apply -f k8s/namespace.yaml
kubectl -n "${NAMESPACE}" apply -f k8s/deployment-blue.yaml
kubectl -n "${NAMESPACE}" apply -f k8s/deployment-green.yaml
kubectl -n "${NAMESPACE}" apply -f k8s/hpa-blue.yaml
kubectl -n "${NAMESPACE}" apply -f k8s/hpa-green.yaml
kubectl -n "${NAMESPACE}" apply -f k8s/service.yaml

# 5) Point deployments to the desired tag (avoids editing YAMLs on stage)
info "Setting deployment images to ${IMAGE_TAG}"
kubectl -n "${NAMESPACE}" set image deployment/web-blue  web="${IMAGE_TAG}"
kubectl -n "${NAMESPACE}" set image deployment/web-green web="${IMAGE_TAG}"

# 6) Wait for readiness
info "Waiting for deployments to be ready"
kubectl -n "${NAMESPACE}" rollout status deployment/web-blue
kubectl -n "${NAMESPACE}" rollout status deployment/web-green

# 7) Quick metrics check
info "Checking cluster metrics (may need ~15–30s)"
kubectl top nodes || warn "metrics not ready yet"
kubectl -n "${NAMESPACE}" top pods || true

# 8) Show URL
info "Service NodePort URL:"
minikube service web -n "${NAMESPACE}" --url
