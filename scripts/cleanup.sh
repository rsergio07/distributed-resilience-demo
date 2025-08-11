#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Distributed Resilience Demo - CLEANUP
# - Default: remove demo namespace only (soft reset)
# - --cluster: delete entire Minikube cluster (hard reset)
# - Leaves local Docker images and TARs untouched (for offline use)
# ============================================================

NAMESPACE="distributed-resilience"

info()  { echo "[+] $*"; }
warn()  { echo "[!] $*" >&2; }
error() { echo "[x] $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [--cluster]

Options:
  --cluster   Hard reset: delete the entire Minikube cluster
              (use when you want a truly fresh environment)
  -h, --help  Show this help
EOF
}

# --- Parse args
HARD_RESET=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cluster) HARD_RESET=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) error "Unknown argument: $1" ;;
  esac
done

# --- Check required commands
for cmd in minikube kubectl; do
  command -v "$cmd" >/dev/null 2>&1 || error "Missing required command: $cmd"
done

if $HARD_RESET; then
  info "Hard reset selected: deleting Minikube cluster"
  minikube delete || warn "Minikube delete returned a non-zero code (already gone?)"
  info "Done. Start again with: ./scripts/deploy-offline.sh"
  exit 0
fi

# --- Soft reset: delete only the demo namespace
if kubectl get ns "${NAMESPACE}" >/dev/null 2>&1; then
  info "Deleting namespace: ${NAMESPACE}"
  kubectl delete ns "${NAMESPACE}" --wait=false

  info "Waiting for namespace to terminate..."
  # Poll until namespace is truly gone
  for i in {1..60}; do
    if ! kubectl get ns "${NAMESPACE}" >/dev/null 2>&1; then
      info "Namespace ${NAMESPACE} deleted."
      break
    fi
    sleep 1
  done

  if kubectl get ns "${NAMESPACE}" >/dev/null 2>&1; then
    warn "Namespace still terminating; Kubernetes GC may need more time."
  fi
else
  warn "Namespace ${NAMESPACE} not found (nothing to delete)."
fi

info "Soft reset complete. You can redeploy with: ./scripts/deploy-offline.sh"
