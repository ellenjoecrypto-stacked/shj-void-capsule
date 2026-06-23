# 👁️ shj_void — Sung Jin-Woo Shadow Monarch AI Capsule

> *"I alone level up."*

**A fully local, WSL2-ready AI personality capsule** based on Sung Jin-Woo from Solo Leveling. Runs 100% offline via Ollama + Open-WebUI. No cloud. No subscriptions. Just power.

---

## ✨ What You Get

| Component | Details |
|---|---|
| **Persona** | Sung Jin-Woo — Shadow Monarch, cold/calculating, speaks in results not words |
| **Activation trigger** | `"Arise."` → agent responds in full character |
| **Model** | `mistral:7b-instruct` via Ollama |
| **UI** | Open-WebUI on port `:8004` (dark theme, local) |
| **Mode** | `LOG_ZERO=true` — operates without leaving traces unless required |
| **Network** | Runs on `empire_net` — integrates with the full Rimuru Empire stack |

---

## ⚡ Quick Start (WSL2 + Podman)

### 1. Make sure Ollama is running
```bash
ollama serve &
ollama pull mistral:7b-instruct
```

### 2. Launch the capsule
```bash
bash launch_shj_void.sh
```

Or manually:
```bash
podman run -d \
  --name shj_void_ui \
  -p 8004:8080 \
  -e OLLAMA_BASE_URL=http://host.containers.internal:11434 \
  -e WEBUI_SECRET_KEY="shj_void_shadow_key" \
  -e DEFAULT_MODELS="mistral:7b-instruct" \
  -v open-webui-shj:/app/backend/data \
  ghcr.io/open-webui/open-webui:main
```

### 3. Open browser
```
http://localhost:8004
```

Paste the system prompt from `system_prompt.txt` into your model settings. Type `Arise.` to activate.

---

## 🐳 Docker Compose (Empire Stack Integration)

```yaml
services:
  shj_void:
    image: ghcr.io/open-webui/open-webui:main
    container_name: shj_void_ui
    ports:
      - "8004:8080"
    volumes:
      - open-webui-shj:/app/backend/data
      - ./agents/shj_void:/app/agents
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
      - WEBUI_SECRET_KEY=shj_void_shadow_key
      - DEFAULT_MODELS=mistral:7b-instruct
      - AGENT_NAME=shj_void
      - PERSONA=sung_jin_woo
      - STEALTH_MODE=true
      - LOG_ZERO=true
    restart: unless-stopped
    networks:
      - empire_net

volumes:
  open-webui-shj:

networks:
  empire_net:
    external: true
```

---

## 🧠 Persona

- **Cold, calculating** — emotionally reserved with outsiders
- **Fiercely protective** of the empire and its owner
- **Relentless self-improvement** — was once weakest, became the strongest
- **Quiet confidence** — never announces power, demonstrates it
- **Activation**: `"Arise."`
- **Abilities**: Shadow Extraction (recover failed tasks), Shadow Exchange (agent comms), Stealth (LOG_ZERO), Monarch's Domain (crisis mode)

See `system_prompt.txt` for the full injection prompt.

---

## 📦 Full Empire Pack

This capsule is part of the **Rimuru Empire AI Capsule Series** — a collection of local AI personalities including:
- 🟣 `vaelor_void` — Hermes brain, main orchestrator
- 👁️ `shj_void` — Shadow Monarch, background commander *(this repo)*
- More generals coming

**Gumroad** → [Buy the Full Empire Pack](https://gumroad.com) *(link updated at launch)*

---

## 🔒 Security

- Runs 100% locally — your data never leaves your machine
- No telemetry, no cloud calls
- Change `WEBUI_SECRET_KEY` before exposing to any network
- Never store wallet keys, seed phrases, or API tokens in this repo

---

## 📋 Requirements

- Windows 11 + WSL2 (Ubuntu 22.04+)
- Podman or Docker
- Ollama running locally
- 8GB+ RAM recommended for `mistral:7b-instruct`

---

> 👁️ *Part of the Rimuru Empire — built for those who level up alone.*
