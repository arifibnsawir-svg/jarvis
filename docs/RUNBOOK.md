# Runbook

Perintah operasional. Balik ke [`START_HERE.md`](../START_HERE.md).

> Semua dijalankan di server Acer (akses via Tailscale). Deploy script dirancang **idempoten & marker-guarded** — aman diulang.

---

## Deploy factory (repo `Joki-tugas-`)

```bash
cd ~/Joki-tugas- && git pull && \
  bash jarvis_document_factory/deploy_document_factory.sh
```

## Deploy memory + infra (repo ini)

```bash
cd ~/jarvis && git pull && \
  bash scripts/deploy_shadow_resolver.sh && \
  bash scripts/deploy_temporal_memory.sh && \
  bash scripts/deploy_context_ingestion.sh && \
  bash scripts/deploy_main_loop_memory.sh && \
  bash scripts/deploy_fable_mythos_prompts.sh && \
  bash scripts/deploy_routing_decision_table.sh && \
  bash scripts/deploy_dream_cycle.sh
```

## Pasang PIPA4 hook

```bash
cp ~/jarvis/scripts/pipa4_hook.py ~/.hermes/scripts/
```

---

## Kill-switch

Kalau ada komponen ngamuk, matiin dulu sebelum debugging:

```bash
PIPA4_AUTO=off        # nonaktifkan council auto-fire
MISTAKE_LOGGER_OFF=1  # nonaktifkan mistake logger
ACTION_GATE_MODE=off  # nonaktifkan action gate
```

---

## Verifikasi

```bash
bash scripts/integrity_check.sh      # integritas file
bash scripts/proof_check.sh          # bukti klaim
bash scripts/model_health_check.sh   # kesehatan provider/model
python scripts/verify_deep_analysis.py
python scripts/combo_quality_test.py
```

---

## Pelajaran operasional (jangan diulang)

1. **Jarvis pernah ngaku "lagi jalan di background" padahal file identik (SHA256 match).** Selalu verifikasi pakai hash, jangan percaya laporan.
2. Regex `CITE_SINGLE` butuh spasi sebelum kurung — format APA `Name (Year)` paling umum.
3. SPEC `blocks` vs `content` — sumber miskomunikasi akut. Pastikan istilahnya jelas.
4. Filter `*.py` pernah kelewat file executable tanpa ekstensi (`pipa4_audit`). Patch harus nyisir keduanya.
5. Memory berbasis tag jauh lebih fleksibel daripada hardcode per domain.
