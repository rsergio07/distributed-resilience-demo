#!/usr/bin/env bash
set -euo pipefail

NS="distributed-resilience"
SVC="web"

READY_MIN=1
BLUE_STABLE_SECONDS=20
CHECK_EVERY=3

echo "[watcher] starting automatic failover watcher (svc/${SVC})"

blue_stable_since=0

get_ready_count () {
  local version="$1"
  kubectl -n "$NS" get pods -l "app=web,version=${version}" \
    -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{"\n"}{end}' \
  | grep -c '^true$' || true
}

get_current_selector_version () {
  kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo ""
}

switch_to () {
  local version="$1"
  local VUP
  VUP="$(printf "%s" "$version" | tr '[:lower:]' '[:upper:]')"   # macOS-safe uppercase
  echo "[watcher] switching Service to ${VUP}"
  kubectl -n "$NS" patch svc "$SVC" \
    -p "{\"spec\":{\"selector\":{\"app\":\"web\",\"version\":\"${version}\"}}}" >/dev/null
}

while true; do
  BLUE_READY=$(get_ready_count blue)
  GREEN_READY=$(get_ready_count green)
  CUR=$(get_current_selector_version)

  if (( BLUE_READY >= READY_MIN )); then
    if (( blue_stable_since == 0 )); then blue_stable_since=$(date +%s); fi
    since=$(( $(date +%s) - blue_stable_since ))
    if [[ "$CUR" != "blue" && $since -ge $BLUE_STABLE_SECONDS ]]; then
      switch_to blue
    fi
  else
    blue_stable_since=0
    if [[ "$CUR" != "green" && $GREEN_READY -ge $READY_MIN ]]; then
      switch_to green
    fi
  fi

  echo "[watcher] blue_ready=${BLUE_READY} green_ready=${GREEN_READY} svc=${CUR}"
  sleep "$CHECK_EVERY"
done