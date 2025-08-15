#!/usr/bin/env bash
#
# Generates sustained CPU load on the "blue" deployment by port-forwarding
# directly to the service and waiting for the duration.
#

NAMESPACE="distributed-resilience"
SERVICE="web"
TARGET="blue"
DURATION="${1:-30}"

info() { echo "[+] $*"; }
error() { echo "[x] $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || error "Missing: $1"; }

need kubectl
need curl

info "Starting CPU load test on ${TARGET} deployment for ${DURATION} seconds..."

# Use kubectl port-forward to create a stable connection to the service.
kubectl port-forward -n "${NAMESPACE}" service/"${SERVICE}" 8080:80 > /dev/null 2>&1 &
PF_PID=$!

sleep 5 # give port-forward time to establish the connection

# Use curl to send the load request to the local port.
info "Targeting service via port-forward..."
curl --silent --show-error --output /dev/null \
    "http://localhost:8080/stress?duration=${DURATION}&target=${TARGET}" &

# Wait for the load to finish.
info "Waiting for the stress test to complete on the server..."
sleep "${DURATION}"

# Kill the port-forward process after the test is complete.
kill $PF_PID
info "Load test finished. Port-forward killed."