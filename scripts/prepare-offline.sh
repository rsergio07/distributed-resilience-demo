#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-resilience-demo:1.1}"
APP_TAR="images/$(echo "$IMAGE_TAG" | tr ':/' '__').tar"

echo "[+] Using Docker context: colima"
docker context use colima >/dev/null 2>&1 || true
colima start --runtime docker >/dev/null 2>&1 || true

echo "[+] Building image: ${IMAGE_TAG}"
DOCKER_BUILDKIT=0 docker build --pull=false -t "${IMAGE_TAG}" .

echo "[+] Writing TAR: ${APP_TAR}"
mkdir -p images
docker save "${IMAGE_TAG}" -o "${APP_TAR}"

echo "[✓] Prepared offline image: ${IMAGE_TAG}"
echo "[✓] TAR saved at: ${APP_TAR}"
