#!/usr/bin/env bash
set -euo pipefail

# generate_data.sh
# Simple load/data generator for the Cafeteria app.
# Usage: ./generate_data.sh [BASE_URL] [COUNT] [DRINK] [DELAY_SECONDS] [CONCURRENCY]
# Example: ./generate_data.sh http://127.0.0.1:53107 50 LATTE 0.2 5

DEFAULT_BASE="http://127.0.0.1:53107"
BASE="${1:-$DEFAULT_BASE}"
COUNT="${2:-20}"
DRINK="${3:-latte}"
DELAY="${4:-0.5}"
CONCURRENCY="${5:-1}"

if [[ "${BASE}" == "-h" || "${BASE}" == "--help" ]]; then
  cat <<EOF
Usage: $0 [BASE_URL] [COUNT] [DRINK] [DELAY_SECONDS] [CONCURRENCY]

BASE_URL     API base (default: ${DEFAULT_BASE})
COUNT        Number of orders to send (default: 20)
DRINK        Drink name to send (default: latte)
DELAY        Delay between requests in seconds (default: 0.5)
CONCURRENCY  Number of parallel workers (default: 1)

Example:
  $0 http://127.0.0.1:53107 50 LATTE 0.1 5

This script will POST simple orders to ${BASE}/api/orders and can be used
to generate metrics visible from /actuator/prometheus for demo/alerts.
EOF
  exit 0
fi

echo "Starting data generation"
echo "BASE=${BASE} COUNT=${COUNT} DRINK=${DRINK} DELAY=${DELAY} CONCURRENCY=${CONCURRENCY}"

send_order() {
  local idx="$1"
  curl -s -o /dev/null -X POST "${BASE}/api/orders" \
    -H 'Content-Type: application/json' \
    -d "{\"customerName\":\"LoadTest-${idx}\",\"drink\":\"${DRINK}\",\"quantity\":1}"
}

# If concurrency == 1 do a simple loop
if [[ "$CONCURRENCY" -le 1 ]]; then
  for i in $(seq 1 "$COUNT"); do
    send_order "$i" || echo "Warning: send_order $i failed"
    sleep "$DELAY"
  done
else
  # Run with N background workers using a PID array (portable, works on macOS bash)
  pids=()
  for i in $(seq 1 "$COUNT"); do
    send_order "$i" &
    pids+=("$!")

    # If we have reached concurrency, wait for the first PID to finish and remove it
    if [[ "${#pids[@]}" -ge "$CONCURRENCY" ]]; then
      wait "${pids[0]}" || true
      # remove the first element
      pids=("${pids[@]:1}")
    fi

    sleep "$DELAY"
  done

  # Wait for any remaining background jobs
  for pid in "${pids[@]}"; do
    wait "$pid" || true
  done
fi

echo "Sent ${COUNT} orders (drink=${DRINK}) to ${BASE}"

# Optional quick metrics peek
echo "Sample prometheus metrics (coffee_orders_* lines):"
curl -s "${BASE}/actuator/prometheus" | grep -E '^coffee_orders_(created|delivered)_total' || true
