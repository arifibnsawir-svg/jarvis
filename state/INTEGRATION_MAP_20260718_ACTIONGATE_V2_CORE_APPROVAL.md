# ACTION-GATE V2 / CORE HERMES APPROVAL INTEGRATION MAP
**Date:** 18 Jul 2026, ~21:30 WIB
**Mode:** READ-ONLY — No patches, no activation, no config changes

---

## 1. EXISTING COMPONENTS FOUND

### Action-Gate v2 (jarvis/action_gate/)

| File | Function | Role |
|------|----------|------|
| `action_gate.py` | `_classify_single()` | Classifies commands → AUTO_OK / NEEDS_APPROVAL / REFUSE |
| `action_gate.py` | `classify_tool()` | Classifies tool calls |
| `action_gate.py` | `to_unified()` | Maps verdict → allow/block based on enforce mode |
| `gate_hook.py` | `gate_tool()` | Integration shim between plugin and action_gate |
| `plugins/action_gate_v2/__init__.py` | `pre_tool_call()` | Plugin hook on every tool call |

### Core Hermes Approval (hermes-agent/tools/approval.py)

| File | Function | Role |
|------|----------|------|
| `tools/approval.py` | `detect_dangerous_command()` | Regex-based pattern detection (~50+ shell patterns) |
| `tools/approval.py` | `check_all_command_guards()` | **Main entry point** — combined tirith + dangerous command gate |
| `tools/approval.py` | `check_dangerous_command()` | Simpler dangerous-command-only gate |
| `tools/approval.py` | `_await_gateway_decision()` | Blocks agent thread until user resolves via Telegram |
| `tools/approval.py` | `resolve_gateway_approval()` | Called by /approve or /deny to unblock agent |
| `tools/approval.py` | `submit_pending()` | Stores pending approval queue |
| `tools/approval.py` | `register_gateway_notify()` | Registers callback to send approval to Telegram |
| `tools/terminal_tool.py` | calls `check_all_command_guards()` | Terminal tool invokes the guard |
| `gateway/run.py` | `_handle_approve_command()` | Telegram /approve handler (once/session/always) |
| `gateway/run.py` | `_handle_deny_command()` | Telegram /deny handler |
| `acp_adapter/permissions.py` | `PermissionOption` | Defines allow_once/session/always/deny options |

---

## 2. CURRENT NEEDS_APPROVAL PASS-THROUGH

### What Action-Gate flags as NEEDS_APPROVAL:
- Force-push to main/master
- Stop/disable/kill protected services
- `kill -9`
- Install/update packages
- Publication/send to third party
- `curl POST` to external
- Modifying PROTECTED_PATH
- Interpreter inline code (`-c`/`-e`)
- Unknown commands (default conservative)

### The pass-through chain:
```
Tool call → plugin.pre_tool_call()
  → gate_hook.gate_tool()
    → action_gate.classify_tool() → verdict="NEEDS_APPROVAL"
    → action_gate.to_unified(mode="live")
      → ACTION_GATE_ENFORCE="refuse_only"
      → allow = v != "REFUSE"     ← KEY LINE (action_gate.py:294)
      → allow = True              ← PASSES THROUGH
    → plugin sees allow=True → returns None → tool executes
```

### Root cause (single line):
`action_gate.py` line 294 in `refuse_only` mode:
```python
allow = v != "REFUSE"  # Only REFUSE is blocked, NEEDS_APPROVAL = True
```

---

## 3. CORE APPROVAL FULL LIFECYCLE

### Config (already active):
```yaml
approvals:
  mode: manual
  timeout: 60
  gateway_timeout: 300   # defaults to 300
  cron_mode: deny
```

### Lifecycle flow:

1. `check_all_command_guards(command, "local")` detects dangerous pattern
2. Gateway context detected → `_await_gateway_decision()` called
3. Creates `_ApprovalEntry(data)` with `threading.Event`
4. Enqueues in `_gateway_queues[session_key]`
5. Core calls `notify_cb(approval_data)` — sends Telegram inline buttons
6. Agent thread blocks via `entry.event.wait(timeout=300)`
7. User replies `/approve` or `/deny` (or `/approve session` / `/approve all always`)
8. Gateway calls `resolve_gateway_approval(session_key, choice)`
9. Sets `entry.result`, signals `entry.event`
10. Agent thread unblocks → tool output or BLOCKED message

### State management (thread-safe):
```python
_lock = threading.Lock()
_pending: dict[str, dict] = {}
_session_approved: dict[str, set] = {}      # session-scoped allow
_session_yolo: set[str] = set()             # session-scoped bypass
_permanent_approved: set = set()            # persisted to config
_gateway_queues: dict[str, list] = []       # FIFO blocking queue
_gateway_notify_cbs: dict[str, callable] = {}  # Telegram send callback
```

---

## 4. GUARANTEE ANALYSIS

| Property | Core Hermes Status | Mechanism |
|----------|--------------------|-----------|
| Pending blocks execution | YES | `threading.Event.wait()` blocks agent |
| Deny blocks execution | YES | Returns `{"approved": False}` + BLOCKED message |
| Expiry blocks execution | YES | Default 300s timeout → denied |
| Approval bound to original action | YES | `approval_data` captures command + pattern_key |
| Concurrent resolution safe | YES | `threading.Lock()` + FIFO queue |
| Session scoping | YES | `_session_approved[session_key]` + pattern keys |
| Permanent scoping | YES | `_permanent_approved` + config.yaml persistence |
| User notification | YES | Telegram inline buttons (Allow Once, Session, Always, Deny) |
| Plugin hooks | YES | `pre_approval_request`, `post_approval_response` |

---

## 5. MINIMAL INTEGRATION SEAM

### Where to patch: `gate_hook.py` (or `action_gate_v2/__init__.py`)

When verdict is NEEDS_APPROVAL and mode is not refuse_only:

```python
from tools.approval import (
    _await_gateway_decision, _gateway_notify_cbs,
    get_current_session_key
)

if dec["verdict"] == "NEEDS_APPROVAL":
    session_key = get_current_session_key()
    notify_cb = _gateway_notify_cbs.get(session_key)
    if notify_cb:
        approval_data = {
            "command": command_str,
            "pattern_key": f"action_gate:{dec.get('reason', 'unknown')}",
            "description": dec.get("reason", "Action-Gate flagged this command"),
        }
        decision = _await_gateway_decision(session_key, notify_cb, approval_data)
        if not decision.get("resolved") or decision.get("choice") == "deny":
            return False, "BLOCKED", dec
```

### What this uses from Core (already exists):
- `_await_gateway_decision()` — blocking approval with heartbeat
- `_gateway_notify_cbs` — per-session Telegram callback
- `get_current_session_key()` — session identity
- `resolve_gateway_approval()` — /approve and /deny handlers
- `_gateway_queues` — FIFO queue with concurrent safety
- `_session_approved` / `_permanent_approved` — scoping

### What stays untouched:
- Action-Gate pattern detection (unchanged)
- Core Hermes pattern detection (unchanged)
- Telegram config/secrets/routing (unchanged)
- Scheduler/cron (unchanged)
- Real-sandbox (unchanged)
- Real Telegram wiring (unchanged)

---

## 6. EXISTING TESTS (reusable)

| Test File | Coverage | Use for |
|-----------|----------|---------|
| `tests/tools/test_approval.py` | 60+ — Core approval lifecycle | Validate Core approval still works after patch |
| `tests/gateway/test_approve_deny_commands.py` | Gateway /approve, /deny, concurrency | Validate Telegram callback flow |
| `tests/tools/test_command_guards.py` | `check_all_command_guards()` | Validate guard orchestration unchanged |
| `tests/tools/test_approval_plugin_hooks.py` | Plugin hook firing | Validate hooks fire correctly |
| `tests/tools/test_approval_heartbeat.py` | Heartbeat during blocking | Validate no watchdog kill |

### Missing tests (Action-Gate + Core integration):
- Action-Gate NEEDS_APPROVAL → `_await_gateway_decision()` routing
- Action-Gate PROTECTED_PATH patterns triggering Core approval
- Action-Gate + Core resolution (approve/deny/timeout)
- Action-Gate + Core session/permanent scoping

---

## 7. VERDICT

**A. EXISTING_CORE_APPROVAL_REUSABLE — MINIMAL INTEGRATION PATCH REQUIRED**

The Core Hermes approval system already provides the full lifecycle:
- Blocking approval with `threading.Event`
- Telegram inline button UI (Allow Once, Session, Always, Deny)
- Thread-safe concurrent resolution
- Session and permanent scoping
- Timeout and expiry
- Plugin hooks

Action-Gate v2 only needs to route its NEEDS_APPROVAL verdicts into the existing `_await_gateway_decision()` function. No new state store, no new transport, no new persistence model, no new Telegram callbacks.

### Previous commit reverted
The `00f34de` commit (new approval_flow.py, approval tests, and patches) has been reverted. The working tree is clean at `a5897ad`.

### Caveats
- Action-Gate's pattern set is complementary to Core's DANGEROUS_PATTERNS — not overlapping
- Description text in Telegram will show Action-Gate's reason, not Core's
- Integration test coverage does not yet exist

---

## FINAL STATUS

`REAL TELEGRAM CALLBACK NOT ACTIVATED`
`REAL-SANDBOX PROMOTION NOT AUTHORIZED`
`PREVIOUS COMMIT REVERTED — TREE CLEAN`
`AWAITING ARIF REVIEW — NO PRODUCTION CODE WRITTEN`