# shj_void Installation Guide

## Requirements

- Windows 11 with WSL2 (Ubuntu 22.04+ recommended)
- Podman Desktop or Docker Desktop
- Ollama installed and running in WSL2
- 8GB RAM minimum (16GB recommended)
- 10GB free disk space for model

## WSL2 + Podman (Recommended)

### Step 1 — Install Ollama in WSL2
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama serve &
```

### Step 2 — Pull the model
```bash
ollama pull mistral:7b-instruct
```

### Step 3 — Clone this repo
```bash
git clone https://github.com/ellenjoecrypto-stacked/shj-void-capsule.git
cd shj-void-capsule
```

### Step 4 — Launch
```bash
chmod +x launch_shj_void.sh
bash launch_shj_void.sh
```

### Step 5 — Configure persona
1. Open http://localhost:8004
2. Create account / sign in
3. Go to Settings → Models
4. Add system prompt from `system_prompt.txt`
5. Type `Arise.` to activate

## Docker (Alternative)
```bash
docker compose -f docker-compose.shj_void.yml up -d
```

## Troubleshooting

**Container not starting:**
```bash
podman logs shj_void_ui
```

**Ollama not reachable from container:**
```bash
# In WSL2, get your host IP:
ip route show default | awk '{print $3}'
# Use that IP instead of host.containers.internal
```

**Port already in use:**
```bash
podman rm -f shj_void_ui
bash launch_shj_void.sh
```

## Uninstall
```bash
podman rm -f shj_void_ui
podman volume rm open-webui-shj
```
