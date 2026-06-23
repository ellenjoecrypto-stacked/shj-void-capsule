# 🤖 Rimuru Empire — Agent Roster
> Last updated: 2026-06-22

| Agent | Role | Port | Model | Status | Notes |
|---|---|---|---|---|---|
| **Vaelor** | Main Brain / Orchestrator | 8003 / 8023 | hermes3:8b | ✅ Deployed | Hermes Ollama; `/chat` + `/exec` + `/remote` |
| **Raga** | Ops Vault Commander | 9000 | — | 🔴 HIGH ALERT | All secrets routed through Raga Vault |
| **Sukuna** | Security Sentinel | 8006 | — | 🔴 HIGH ALERT | ufw + watchdog + intrusion detection |
| **shj_void** | Shadow Monarch / BG Commander | 8004 | mistral:7b-instruct | ✅ Capsule Built | `Arise.` trigger; LOG_ZERO=true; Open-WebUI |
| **Nami** | Price Intelligence | — | — | ✅ Edge Function Live | CoinGecko poller; 17 airdrop tokens |
| **Ellen Joe** | On-Chain Executor | — | — | ⏳ Queue Ready | 11 tasks queued; say "queue it" to activate |
| **Asclepius** | System Health | — | — | ✅ Active | 16 system monitors in Supabase |
| **Mantis** | Claim Scanner | — | — | ✅ Active | Faucet + claim window scanner |
| **Iris** | Airdrop Discovery | — | — | ✅ Active | 12 sources scraped every 6–24h |
| **Brook** | Telegram Alerts | — | — | ⏳ Pending | BotFather config needed |

## Port Map
| Port | Service |
|---|---|
| 8003 | Vaelor brain (Hermes/Ollama) |
| 8004 | shj_void Open-WebUI capsule |
| 8005 | Prometheus metrics |
| 8006 | Sukuna security |
| 8023 | Vaelor agent API |
| 9000 | Raga Vault |
| 3001 | Grafana dashboard |

## Network
All agents run on `empire_net` (Podman bridge). Vaelor is the primary orchestrator.

## Wallet Addresses (Public — No Private Keys)
| Chain | Address | Used By |
|---|---|---|
| Solana | `Dqnq2iLH33WnwdFsQvSkzNWwZDRvDMkHvpT2RXkUGkNb` | Airdrop portfolio, Nodepay, Grass |
| EVM (BSC/ETH) | `0x9349b6Ef2d8C3a7F1e4B9D05c82aA1f32aaC549` | Airdrop portfolio, Gradient, Rivalz, Blockmesh |
| TON Main | `UQBkgWhgQcSTwTxDHfXzS7vZl2AGBI83TgZxyX_kRov0_sZ1` | TON faucets, rimuru-faucet |
| BTC (Kraken) | `3B3CrGKMjTdMpFMQNvJyvSj9nhmkweRP2w` | Kraken deposit |

> 🔐 Private keys managed exclusively by Raga Vault (`~/.raga_key`). Never stored in this repo.
