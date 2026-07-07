# Infra Jalur B — Setup & State

**Tanggal:** 7 Jul 2026
**Host:** Acer (arif@100.86.42.113) — Linux Mint zena (Ubuntu Noble 24.04)
**Tujuan sesi:** pasang & nyalain infra Jalur B (browser automation) + buktiin jembatan n8n -> Jarvis-side.

## 1. Komponen Terpasang

### Scrapling (Reader / "Mata") — v0.4.10
- Lokasi: venv `~/.hermes/recon-venv` (Python 3.12.3, pip 26.1.2)
- Install: `pip install "scrapling[fetchers]"` lalu `scrapling install`
- Deps kunci: playwright 1.61.0, patchright 1.61.1, curl_cffi 0.15.0, browserforge 1.2.4, lxml 6.1.1
- Verify: `scrapling OK 0.4.10` + `fetchers OK`

### agent-browser (Actor / "Tangan") — v0.31.1
- Binary: `/usr/local/bin/agent-browser`
- Chrome: 150.0.7871.46 di `~/.agent-browser/browsers/`
- Install: `sudo npm install -g agent-browser` lalu `agent-browser install --with-deps`
- Catatan: warning EBADENGINE (node>=24) harmless — binary Rust, node cuma buat build-from-source

### n8n (Scheduler) — v2.29.7 via Docker
- Install npm 2.28.7 GAGAL (bug langchain #33370: @langchain/core subpath ./utils/uuid ilang)
- Solusi: Docker image docker.n8n.io/n8nio/n8n. Command:

      sudo docker volume create n8n_data
      sudo docker run -d --name n8n --restart unless-stopped -p 5678:5678 -e GENERIC_TIMEZONE="Asia/Jakarta" -e TZ="Asia/Jakarta" -e N8N_SECURE_COOKIE=false -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n

- Akses: http://100.86.42.113:5678 (Tailscale) / localhost:5678 di Acer
- Data: volume n8n_data -> /home/node/.n8n
- Catatan: Python task runner di container skip (Python 3 gak ada di image) — gak ngaruh workflow non-Python

## 2. Environment
- Node normal: v22.22.3 / npm 10.9.8 (~/.local/bin/node); npm prefix ~/.hermes/node, bin ditambah ke PATH permanen di ~/.bashrc
- Node via sudo: v18.19.1 / npm 9.2.0 (JANGAN buat install global)
- Docker: 29.1.3 (perlu sudo; user arif belum di grup docker — opsional: sudo usermod -aG docker $USER + re-login)

## 3. Jembatan n8n -> Jarvis-side (KEBUKTI)
- Constraint: n8n di Docker (isolated) -> nyapa Jarvis lewat HTTP, bukan shell
- Port map (ss -tlnp):
  - 9router (next-server): 20128, bind 0.0.0.0 -> reachable dari container (OK)
  - n8n (docker-proxy): 5678, bind 0.0.0.0
  - approval (python3): 20129, bind 127.0.0.1 -> localhost-only (tidak reachable)
- Bukti CLI: docker exec n8n wget -qO- http://100.86.42.113:20128/ -> balik HTML 9router
- Bukti UI: workflow Manual Trigger -> HTTP Request GET http://100.86.42.113:20128/ -> Node executed successfully

## 4. Keputusan LOCKED
- Jalur B (browser automation) = PRIMARY (Scrapling + agent-browser, throttle pelan anti-bot); Jalur A (API resmi) = SECONDARY opsional
- Humanizer WAJIB (langkah 7 alur produksi, non-skippable)
- Content Gate 2 pos (Pos 1 deterministik sacred-IP fail-closed + Pos 2 hakim combo jarvis-reason); Reply Gate 2 lapis (Stage 4)
- OCR fallback: OCR model gagal -> pakai OCR default bawaan
- Skill backlog (awesome-claude-skills): perlu verif kompatibilitas runtime Jarvis; Composio/Rube-MCP social automation = SKIP (nabrak Jalur B no-API)

## 5. Pending / Next
- [ ] Petain endpoint gateway/agent buat trigger tugas Jarvis (bukan cuma GET HTML)
- [ ] Workflow beneran: Daily Report + Posting Scheduler
- [ ] Benerin kendala OCR Jarvis (model apa yg gagal + lokasi aturan fallback)
- [ ] Verif kompatibilitas Claude Skills (SKILL.md) sama runtime Jarvis
- [ ] Implementasi content_gate_rules.json (Pos 1) + wiring gate -> combo jarvis-reason
- [ ] Confirm rotasi token Telegram
- [ ] Opsional: masukin arif ke grup docker
