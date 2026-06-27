-- Jarvis memory store: SQLite + sqlite-vec
-- Dua koleksi dalam satu file: route_exemplars (L1 routing) + artifact_memory (R9 RAG)
-- Install di Acer: pip install sqlite-vec   (atau load extension .so/.dll)
-- Dimensi vektor = 384 (paraphrase-multilingual-MiniLM-L12-v2). Sesuaikan kalau ganti model.

-- ============ Routing exemplars (Layer 1) ============
CREATE TABLE IF NOT EXISTS route_exemplars_meta (
    id        INTEGER PRIMARY KEY,
    branch    TEXT NOT NULL,
    text      TEXT NOT NULL,
    created_at INTEGER DEFAULT (unixepoch())
);

CREATE VIRTUAL TABLE IF NOT EXISTS route_exemplars_vec USING vec0(
    embedding FLOAT[384]
);

-- ============ Artifact memory (R9 RAG, anti-amnesia) ============
CREATE TABLE IF NOT EXISTS artifact_meta (
    id         INTEGER PRIMARY KEY,
    task_id    TEXT NOT NULL,
    pipa_stage TEXT,             -- PIPA1..4
    kind       TEXT,             -- schema | draft | verdict | note
    content    TEXT NOT NULL,
    sha256     TEXT,             -- evidence integrity
    created_at INTEGER DEFAULT (unixepoch())
);

CREATE VIRTUAL TABLE IF NOT EXISTS artifact_vec USING vec0(
    embedding FLOAT[384]
);

CREATE INDEX IF NOT EXISTS idx_artifact_task ON artifact_meta(task_id);
CREATE INDEX IF NOT EXISTS idx_artifact_kind ON artifact_meta(kind);

-- ============ Append-only event ledger (state history) ============
-- Tidak ada UPDATE/DELETE pada tabel ini by convention. Hanya INSERT.
CREATE TABLE IF NOT EXISTS event_ledger (
    id          INTEGER PRIMARY KEY,
    task_id     TEXT NOT NULL,
    event_type  TEXT NOT NULL,  -- route | pipa_output | verdict | status_change
    actor       TEXT,           -- branch/combo/model atau 'pipa4_gate'
    payload     TEXT,           -- JSON
    created_at  INTEGER DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_ledger_task ON event_ledger(task_id);

-- Contoh KNN query (R9 retrieval):
--   SELECT m.task_id, m.kind, m.content,
--          distance
--   FROM artifact_vec v JOIN artifact_meta m ON m.id = v.rowid
--   WHERE v.embedding MATCH :query_vec AND k = 5
--   ORDER BY distance;
