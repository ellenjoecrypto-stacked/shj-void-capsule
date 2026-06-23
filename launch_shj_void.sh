#!/bin/bash
# launch_shj_void.sh — Shadow Monarch capsule boot script
# Part of the Rimuru Empire AI Capsule Series

set -e

echo "👁️  [shj_void] Shadow Monarch awakening..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check Ollama is running
if ! ollama list &>/dev/null; then
  echo "⚠️  Ollama not running. Starting..."
  ollama serve &
  sleep 3
fi

# Pull model if not present
if ! ollama list | grep -q "mistral:7b-instruct"; then
  echo "📥 Pulling mistral:7b-instruct..."
  ollama pull mistral:7b-instruct
else
  echo "✅ mistral:7b-instruct ready"
fi

# Remove old container if exists
if podman ps -a --format '{{.Names}}' | grep -q '^shj_void_ui$'; then
  echo "🔄 Removing old shj_void_ui container..."
  podman rm -f shj_void_ui
fi

# Ensure empire_net exists
if ! podman network ls --format '{{.Name}}' | grep -q '^empire_net$'; then
  echo "🕸️  Creating empire_net network..."
  podman network create empire_net
fi

# Launch Open-WebUI capsule
echo "🚀 Launching shj_void capsule on port 8004..."
podman run -d \
  --name shj_void_ui \
  --network empire_net \
  -p 8004:8080 \
  -e OLLAMA_BASE_URL=http://host.containers.internal:11434 \
  -e WEBUI_SECRET_KEY="shj_void_shadow_key" \
  -e DEFAULT_MODELS="mistral:7b-instruct" \
  -v open-webui-shj:/app/backend/data \
  ghcr.io/open-webui/open-webui:main

# Wait for startup
echo "⏳ Waiting for capsule to start..."
for i in {1..15}; do
  if curl -s http://localhost:8004 &>/dev/null; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "👁️  [shj_void] Active at http://localhost:8004"
    echo "    Shadow Army standing by."
    echo "    Type: Arise."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
  fi
  sleep 2
  echo -n "."
done

echo ""
echo "⚠️  Container started but UI may still be loading. Check: http://localhost:8004"
echo "    Run: podman logs shj_void_ui"
