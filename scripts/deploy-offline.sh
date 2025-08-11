#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Distributed Resilience Demo - OFFLINE Deploy
# - Uses Colima (Docker runtime) + Minikube (docker driver)
# - Never pulls from internet; relies on local images or TARs
# - Preloads images, enables metrics-server, applies manifests
# ============================================================

NAMESPACE="distributed-resilience"
APP_IMAGE="resilience-demo:1.0"
APP_TAR="images/resilience-demo_1.0.tar"

METRICS_IMAGE="registry.k8s.io/metrics-server/metrics-server:v0.7.2"
METRICS_TAR="images/metrics-server_v0.7.2.tar"

info()  { echo "[+] $*"; }
warn()  { echo "[!] $*" >&2; }
error() { echo "[x] $*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || error "Missing required command: $1"
}

# --- 0) Pre-flight checks
require_cmd colima
require_cmd docker
require_cmd minikube
require_cmd kubectl

# --- 1) Ensure Colima is the current Docker context (no Docker Desktop)
info "Ensuring Colima (Docker) is running"
colima status --runtime docker >/dev/null 2>&1 || colima start --runtime docker
docker context use colima >/dev/null 2>&1 || true

# --- 2) Start Minikube with docker driver (uses current docker context: Colima)
if ! minikube status >/dev/null 2>&1; then
  info "Starting Minikube with docker driver"
  minikube start --driver=docker
else
  info "Minikube already running"
fi

# --- 3) Preload metrics-server image (from TAR if available, else from local cache)
if docker image inspect "${METRICS_IMAGE}" >/dev/null 2>&1; then
  info "Found local metrics-server image: ${METRICS_IMAGE}"
  minikube image load "${METRICS_IMAGE}"
elif [[ -f "${METRICS_TAR}" ]]; then
  info "Loading metrics-server from TAR: ${METRICS_TAR}"
  minikube image load "${METRICS_TAR}"
else
  warn "metrics-server image not found locally and TAR missing (${METRICS_TAR})."
  warn "If offline, enable addon may fail to pull. Consider preloading via TAR beforehand."
fi

# --- 4) Enable metrics-server addon (will use preloaded image)
info "Enabling metrics-server addon"
minikube addons enable metrics-server
kubectl -n kube-system rollout status deployment/metrics-server

# --- 5) Ensure app image exists locally or via TAR; avoid network pulls
if docker image inspect "${APP_IMAGE}" >/dev/null 2>&1; then
  info "Found local app image: ${APP_IMAGE}"
else
  if [[ -f "${APP_TAR}" ]]; then
    info "Loading app image from TAR: ${APP_TAR}"
    docker load -i "${APP_TAR}"
  else
    warn "App image ${APP_IMAGE} not found, and ${APP_TAR} not present."
    warn "Attempting local build (requires base image already cached):"
    info "Building ${APP_IMAGE} from Dockerfile (no network pulls)..."
    # Build without pulling new layers (fails fast if base not cached)
    DOCKER_BUILDKIT=0 docker build --pull=false -t "${APP_IMAGE}" .
  fi
fi

# --- 6) Preload app image into Minikube cache
info "Preloading app image into Minikube: ${APP_IMAGE}"
minikube image load "${APP_IMAGE}" || {
  # Fallback: allow loading from TAR if cluster path is required
  if [[ -f "${APP_TAR}" ]]; then
    info "Fallback: loading TAR directly into Minikube"
    minikube image load "${APP_TAR}"
  else
    error "Could not load app image into Minikube"
  fi
}

# --- 7) Apply Kubernetes manifests
info "Applying Kubernetes manifests"
kubectl apply -f k8s/namespace.yaml
kubectl -n "${NAMESPACE}" apply -f k8s/deployment-blue.yaml
kubectl -n "${NAMESPACE}" apply -f k8s/deployment-green.yaml
kubectl -n "${NAMESPACE}" apply -f k8s/hpa-blue.yaml
kubectl -n "${NAMESPACE}" apply -f k8s/hpa-green.yaml
kubectl -n "${NAMESPACE}" apply -f k8s/service.yaml

# --- 8) Wait for readiness
info "Waiting for deployments to be ready"
kubectl -n "${NAMESPACE}" rollout status deployment/web-blue
kubectl -n "${NAMESPACE}" rollout status deployment/web-green

# --- 9) Quick metrics check (may take a few seconds)
info "Checking cluster metrics (may be empty for ~15–30s)"
kubectl top nodes || warn "metrics not ready yet"
kubectl -n "${NAMESPACE}" top pods || true

# --- 10) Show service URL
info "Service NodePort URL:"
minikube service web -n "${NAMESPACE}" --url
