# EmpTracker AI Security & Privacy Architecture

**Standard:** Zero Trust AI / Defense in Depth  
**Status:** Enforced in Phase 1 Baseline  

---

## 1. Core Security Principles

1. **AI Is Untrusted:** The AI engine is treated as an untrusted reasoning component. It is NEVER granted direct database connection credentials, raw SQL execution capabilities, or permission-bypass authority.
2. **Laravel Authorization Is Supreme:** Every tool execution runs within the authenticated context of `auth()->user()`. Laravel policies and `AiPermissionService` validate actor roles before any query executes.
3. **Strict Employee Isolation:** Non-admin employees can only inspect their own attendance, location, and route data. Attempting to query another employee triggers an immediate `AiPermissionDeniedException` (HTTP 403).
4. **Data Minimization & Aggregation:** Raw GPS point clouds are pre-aggregated into human-readable metrics (e.g. "Stayed 28 minutes at Shop A, traveled 14.8 km") before context injection.
5. **No Cloud Leakage of Sensitive Data:** Data marked as `SENSITIVE` or `HIGHLY_SENSITIVE` (real-time GPS telemetry, personal attendance) is blocked from external cloud API transmission by the `CloudAiProvider` guard.
6. **Response Sanitization:** The `AiResponseValidator` strips any accidentally echoed tokens, database passwords, or connection strings prior to client transmission.
7. **Complete Audit Trail:** Every interaction, tool invocation, response classification, and latency measurement is recorded in the `ai_audit_logs` table.

---

## 2. Threat Modeling & Mitigations

| Threat Vector | Risk Level | Mitigation Architecture |
| :--- | :---: | :--- |
| **Prompt Injection** | High | `AiContextBuilder::sanitizeInput()` strips XML/HTML injection tags (`<system>`, `<instruction>`, `<tool_call>`). System prompt enforces non-overridable developer constraints. |
| **Unauthorized Data Exfiltration** | Critical | `AiPermissionService::enforceEmployeeIsolation()` forces `$parameters['employee_id'] = $user->id` for non-admin actors. |
| **SQL Injection** | Critical | Zero raw SQL. All tools use Laravel Eloquent ORM parameterized queries with typed bindings. |
| **Accidental State Mutation** | High | Phase 1 is strictly Read-Only. Future write tools require explicit 2-step user confirmation. |
| **Denial of Service (DoS)** | Medium | AI endpoints are rate-limited via Laravel Sanctum middleware and `config('ai.rate_limit')`. |
| **Total System Rollback** | Low | Setting `AI_ENABLED=false` in `.env` disables the AI gateway instantly with zero degradation to existing tracking or attendance features. |

---

## 3. Flutter Client Security & Zero-Trust Boundaries (Phase 3)

1. **No Embedded Secrets / Model Keys:** Flutter binaries (web & APK) contain zero cloud model keys, database connection strings, or administrative master keys.
2. **Backend Authentication Enforced:** Every request must carry a valid Laravel Sanctum Bearer token.
3. **No Client-Side Authorization Trust:** Role-based visibility in the Flutter UI is purely for UX convenience; authorization and data isolation are strictly evaluated on Laravel server-side.
4. **No Local GPS Memory Persistence:** AI chat histories do not store sensitive high-frequency GPS coordinate breadcrumbs in permanent client storage.

---

## 4. Two-Step Write Action Security & Idempotency (Phase 4)

1. **Confirmation Token Is Not Authorization:** When the AI proposes a write action, Laravel generates a cryptographically signed HMAC-SHA256 token tied specifically to `auth()->user()->id` and valid for 10 minutes.
2. **Re-Authorization and Parameter Re-Validation:** When the client confirms the action via `POST /api/ai/actions/confirm`, Laravel re-authorizes the user against RBAC rules and re-validates all parameters against the live database state.
3. **Strict Idempotency Guard:** Consumed confirmation tokens are immediately transitioned to `CONFIRMED` or deleted, preventing replay or double-execution attacks.
4. **Database Transactions:** All state mutations execute within atomic `DB::transaction(...)` blocks with rollbacks on failure.
---

## 5. Map Intelligence & Location Privacy Guardrails (Phase 5)

1. **No Continuous GPS Processing:** Location pings are stored deterministically in SQL without invoking LLM tokens. AI is queried only on-demand when authorized human operators request route or area insights.
2. **Deterministic Distance & Anomaly Verification:** All proximity and route calculations use server-side Haversine math and timestamp verification, preventing generative hallucinations of employee whereabouts.
3. **Cross-Subordinate Isolation:** Employees querying location or route summaries of other team members are blocked with HTTP 403 `AiPermissionDeniedException`.
4. **Neutral Terminology Standard:** Deviations or unexpected movements are reported factually (e.g. `"Route deviation of 2.4 km observed between 11:20 and 11:45"`) without speculative disciplinary labels.
5. **Zero-Data Hallucination Safeguard:** When live telemetry or visit history is absent, responses explicitly state lack of data rather than interpolating or synthesizing coordinates.

---

## 6. Voice, Multilingual & Offline Safety Protocols (Phase 6)

1. **Explicit Voice Initiation:** The microphone stream is initiated only via physical button taps. Continuous background recording is prohibited.
2. **Spoken Write Actions Confirmation Gate:** Spoken voice commands proposing write operations generate an interactive 2-step confirmation card. Spoken confirmation is strictly rejected—the user must physically tap "Confirm & Execute" on the screen.
3. **Zero Offline Authorization Bypass:** Offline AI operates only over static, pre-authorized app FAQ guidance. Unauthenticated or privilege-escalating queries are blocked.
4. **Stale Data Rejection:** When disconnected from the internet, real-time telemetry queries explicitly state that live data requires a server connection, preventing false or outdated telemetry delivery.




