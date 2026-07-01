# RESUME / HANDOFF - Jarvis Tuning (sumber kebenaran tunggal)
_Update: 2026-07-01 22:15 (sesi lanjutan malam)._

## 0. TL;DR
4 PIPA TERSAMBUNG & TERVERIFIKASI (2026-07-01 22:15):
- PIPA1-3: skills advisory (pipa-routing, neuro-arc, arsi-doctrine)
- PIPA4 gate factory: 7 cek deterministik (auto di run.py)
- PIPA4 council: LLM audit auto-fire via hook (VERIFIED: triggered=true, NEEDS_PAGE_TOPUP, false_ready=0)

SESI INI: 7 ITEM VERIFIED.

## 1. INFRA
Server: Acer (Tailscale). Kode: Joki-tugas- = factory. jarvis = infra/scripts/deploy.

## 2. ATURAN KERJA
VERDICT, evidence-first, anti-False-READY, SOFT vs HARD.

## 3. JARVIS-DOCUMENT-FACTORY
- Kode: Joki-tugas-, jarvis_document_factory/. Deploy: bash deploy_document_factory.sh
- Pipeline: SPEC → humanizer+citation+images → validate → render → gate 7-cek → PIPA4 council (academic)
- PIPA4 AUTO-WIRING (VERIFIED 22:10): Council auto-fire via ~/.hermes/scripts/pipa4_hook.py. Factory import _load_pipa4_hook() fail-open. Council detected NEEDS_PAGE_TOPUP (real issue, false_ready=0), factory tetap exit 0.

## 3b. ACADEMIC-SEARCH (VERIFIED)

## 4. 4 PIPA STATUS
PIPA1-3 (skills advisory) + PIPA4 gate (7 cek) + PIPA4 council (LLM auto-fire) = ALL CONNECTED.

## 5. STATUS KEMAMPUAN
Semua PROVEN: factory, academic-search, routing, web, mistake-logger, council swap, humanizer, word-count, relevance, PIPA4 wiring.

## 6. OPEN ITEMS
1-6. KELAR (validate, anti-fallback, template, relevance, word-count, PIPA4 wiring)
7. action-gate v2 LIVE (shadow, nunggu GO Arif)
8. sub-agent architecture
9. Opsional + checkpoint items

## 7. DEPLOY
- Factory: cd ~/Joki-tugas- && bash jarvis_document_factory/deploy_document_factory.sh
- PIPA4 hook: cp ~/jarvis/scripts/pipa4_hook.py ~/.hermes/scripts/
- Kill-switch: PIPA4_AUTO=off

## 8. PEMISAHAN REPO
- Joki-tugas- = SKILL PRODUKSI SAJA (renderer, gate, spec, examples)
- jarvis = INFRA/TUNING (scripts, pipa4_hook, academic-search, handoff)
- JANGAN campur.
