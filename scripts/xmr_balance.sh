#!/usr/bin/env bash
# xmr_balance.sh — Monero balance checker for Ninja Empire
# Requires: monero-wallet-cli OR monero-wallet-rpc (daemon mode)
# WSL2 compatible. Run from any directory.
#
# Usage:
#   bash scripts/xmr_balance.sh [--rpc] [--export]
#
# Modes:
#   default  — spawns monero-wallet-rpc on port 18082, queries balance, kills rpc
#   --rpc    — assumes monero-wallet-rpc is already running on port 18082
#   --export — writes balance to output/xmr_balance.txt

set -euo pipefail

# ── CONFIG ───────────────────────────────────────────────────────────────────
RPC_PORT=18082
RPC_HOST="127.0.0.1"
DAEMON_NODE="node.sethforprivacy.com:18089"
WALLET_FILE="${XMR_WALLET_FILE:-$HOME/.monero/empire_wallet}"
WALLET_PASSWORD="${XMR_WALLET_PASSWORD:-}"
OUTPUT_DIR="$(cd "$(dirname "$0")/../output" 2>/dev/null && pwd || echo "$HOME/output")"
RPC_PID=""
MODE="auto"
EXPORT=false

# ── ARGS ─────────────────────────────────────────────────────────────────────
for arg in "$@"; do
  case $arg in
    --rpc)    MODE="rpc" ;;
    --export) EXPORT=true ;;
  esac
done

# ── CLEANUP TRAP ─────────────────────────────────────────────────────────────
cleanup() {
  if [[ -n "$RPC_PID" ]]; then
    echo "Stopping monero-wallet-rpc (PID $RPC_PID)..."
    kill "$RPC_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# ── CHECK DEPS ───────────────────────────────────────────────────────────────
if ! command -v monero-wallet-rpc &>/dev/null && ! command -v monero-wallet-cli &>/dev/null; then
  echo "❌ monero-wallet-rpc not found in PATH."
  echo "Install: https://www.getmonero.org/downloads/"
  echo "WSL2 tip: sudo apt install monero  OR  download binary to ~/bin/"
  exit 1
fi

if ! command -v curl &>/dev/null; then
  echo "❌ curl required. Install: sudo apt install curl"
  exit 1
fi

# ── START RPC (auto mode) ─────────────────────────────────────────────────────
if [[ "$MODE" == "auto" ]]; then
  if [[ ! -f "$WALLET_FILE" ]]; then
    echo "❌ Wallet file not found: $WALLET_FILE"
    echo "Set env: export XMR_WALLET_FILE=/path/to/wallet (no extension)"
    echo "Restore from vault seed: monero-wallet-cli --restore-deterministic-wallet --restore-height 3679000 --daemon-host $DAEMON_NODE"
    exit 1
  fi

  echo "Starting monero-wallet-rpc..."
  monero-wallet-rpc \
    --wallet-file "$WALLET_FILE" \
    --password "$WALLET_PASSWORD" \
    --rpc-bind-port $RPC_PORT \
    --rpc-bind-ip $RPC_HOST \
    --daemon-address $DAEMON_NODE \
    --trusted-daemon \
    --disable-rpc-login \
    --log-level 0 &>/tmp/xmr_rpc.log &
  RPC_PID=$!

  echo "Waiting for RPC to be ready (PID $RPC_PID)..."
  for i in {1..30}; do
    if curl -sf "http://$RPC_HOST:$RPC_PORT/json_rpc" -d '{"jsonrpc":"2.0","id":"0","method":"get_version"}' -H 'Content-Type: application/json' &>/dev/null; then
      echo "RPC ready."
      break
    fi
    sleep 1
    if [[ $i -eq 30 ]]; then
      echo "❌ RPC failed to start. Log: /tmp/xmr_rpc.log"
      cat /tmp/xmr_rpc.log
      exit 1
    fi
  done
fi

# ── QUERY BALANCE ──────────────────────────────────────────────────────────────
echo ""
echo "Querying XMR balance..."

RESPONSE=$(curl -sf \
  "http://$RPC_HOST:$RPC_PORT/json_rpc" \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":"0","method":"get_balance","params":{"account_index":0}}'
)

if [[ -z "$RESPONSE" ]]; then
  echo "❌ No response from wallet RPC"
  exit 1
fi

# Parse balance (in piconeros, divide by 1e12 for XMR)
BALANCE_RAW=$(echo "$RESPONSE" | grep -oP '"balance":\s*\K[0-9]+'  | head -1)
UNLOCKED_RAW=$(echo "$RESPONSE" | grep -oP '"unlocked_balance":\s*\K[0-9]+' | head -1)

if [[ -z "$BALANCE_RAW" ]]; then
  echo "❌ Could not parse balance from response:"
  echo "$RESPONSE"
  exit 1
fi

BALANCE_XMR=$(awk "BEGIN { printf \"%.12f\", $BALANCE_RAW / 1000000000000 }")
UNLOCKED_XMR=$(awk "BEGIN { printf \"%.12f\", $UNLOCKED_RAW / 1000000000000 }")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "======================================"
echo "   XMR WALLET BALANCE"
echo "======================================"
echo "  Total:    $BALANCE_XMR XMR"
echo "  Unlocked: $UNLOCKED_XMR XMR"
echo "  Time:     $TIMESTAMP"
echo "======================================"

# ── EXPORT ─────────────────────────────────────────────────────────────────────
if [[ "$EXPORT" == true ]]; then
  mkdir -p "$OUTPUT_DIR"
  OUT="$OUTPUT_DIR/xmr_balance.txt"
  {
    echo "Chain,Wallet,Balance,Unlocked,Unit,Timestamp"
    echo "XMR,$WALLET_FILE,$BALANCE_XMR,$UNLOCKED_XMR,XMR,$TIMESTAMP"
  } > "$OUT"
  echo "✅ Exported -> $OUT"
fi
