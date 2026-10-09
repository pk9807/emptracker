# EmpTracker AI System Architecture

**Version:** 1.0.0-PROD  
**Design Pattern:** Local-First Hybrid AI with Deterministic Tool Abstraction

---

## 1. System Topology

```
                         EMPTRACKER APP / CONSOLE
                                    |
                       [ User Natural Language Input ]
                                    |
                                    v
                     +------------------------------+
                     |    Flutter AI Gateway/Client |
                     +------------------------------+
                                    |
                     +------------------------------+
                     |    Laravel AI Gateway API    |
                     |     (Sanctum Authenticated)  |
                     +------------------------------+
                                    |
                                    v
                        +-----------------------+
                        |  AI Intent Router     |
                        +-----------------------+
                                    |
             +----------------------+----------------------+
             |                      |                      |
             v                      v                      v
    [ Local AI Engine ]    [ Laravel Tool Engine ]  [ Cloud AI Fallback ]
    (Qwen2.5 / Gemma2)     (Eloquent / Geofence)    (OpenAI/Gemini/Claude)
             |                      |                      |
             +----------------------+----------------------+
                                    |
                                    v
                     +------------------------------+
                     |   AI Response Validator      |
                     |  & 2-Step Action Confirmation|
                     +------------------------------+
                                    |
                                    v
                     [ Verified Natural Language +  ]
                     [ Interactive Structured Cards ]
```

---

## 2. Intent Routing & Execution Pipeline

1. **Request Intake & Privacy Classification:** Incoming request is classified (`PUBLIC`, `INTERNAL`, `SENSITIVE`, `HIGHLY_SENSITIVE`).
2. **Intent Matching:** Classifies whether the query is:
   * **Deterministic operational query** (e.g. "Show my attendance", "Who is near Shop X?") $\rightarrow$ Routes to Laravel Tool Engine.
   * **Conversational explanation / summary** $\rightarrow$ Routes to Local AI with deterministic context payload.
   * **Complex cross-domain synthesis** $\rightarrow$ Routes to Cloud AI (only if allowed by privacy policy and tenant configuration).
3. **Tool Execution Guardrails:**
   * Tools verify `auth()->user()`, role permissions, and tenant isolation.
   * Read operations execute immediately; write actions return a structured `confirmation_required` payload.
4. **Validation & Audit Logging:** All tool calls and responses are validated against JSON schemas and logged to `ai_audit_logs`.

---

## 3. Tool Calling Registry Specification

```
Tools/
├── Employee/
│   ├── GetMyTodayTasksTool
│   ├── GetMyAttendanceTool
│   ├── GetMyAssignedShopsTool
│   └── GetMyVisitHistoryTool
├── Admin/
│   ├── GetLiveRadarOverviewTool
│   ├── SearchEmployeesTool
│   ├── GetShopCoverageAnalyticsTool
│   ├── DetectInactivityAnomaliesTool
│   └── GetRouteHistorySummaryTool
└── Shared/
    ├── GetNearbyShopsTool
    └── GetKnowledgeFaqTool
```

---

## 4. Configuration & Feature Flags (`.env`)

```env
AI_ENABLED=true
AI_LOCAL_FIRST=true
AI_LOCAL_PROVIDER=local_embedded
AI_CLOUD_FALLBACK_ENABLED=true
AI_CLOUD_PROVIDER=gemini # or openai / anthropic
AI_CLOUD_API_KEY=your_secure_key_here
AI_MAX_CONTEXT_TOKENS=2048
AI_RATE_LIMIT_PER_MINUTE=30
```

---

## 5. Flutter AI Integration Architecture (Phase 3)

### 5.1 Architecture & Layers

```
Flutter App (Admin / Employee)
   │
   ├── UI Layer: [AiAssistantModal] (design_system)
   │     - Glassmorphic / Cyberpunk UI
   │     - Role-specific fast prompt chips (Hindi / Hinglish / English)
   │     - Chat message bubbles with provider engine badges & latency indicators
   │     - Zero business-logic / zero privileged database operations
   │
   ├── Repository Layer: [AiRepository] / [LaravelAiRepository] (firebase_repository)
   │     - Uses existing ApiClient (pure Dart, web & mobile compatible)
   │     - Sends authenticated request with bearer token & optional ephemeral client coordinates
   │     - Deserializes structured responses into [AiMessage]
   │
   └── Network Gateway: Laravel `/api/ai/chat`
         - Sanctum user authentication & permission enforcement
         - AiPermissionService & ToolRegistry execution
         - Response Sanitizer & Structured JSON delivery
```

### 5.2 Flutter State Management Pattern
* Strictly follows the project's native `StatefulWidget` / `ValueNotifier` pattern without introducing unneeded third-party state managers (No Bloc/Riverpod/GetX).
* Seamless integration with existing `ApiClient` and authentication tokens stored in `shared_preferences`.

### 5.3 Error Recovery & Offline Fallbacks
* If offline or backend unreachable: gracefully catches network timeouts/HTTP errors and displays localized feedback (`"AI Sahayak se connect nahi ho pa raha hai..."`) without interfering with background location tracking, attendance, or map rendering.
* Unauthorized/Forbidden queries: Displays explicit permission rejection without crashing or retrying repeatedly.

---

## 6. Map Intelligence & Tracking AI Layer (Phase 5)

```
                       [ Field Tracking Telemetry ]
                       (live_locations / visits / routes)
                                     │
                                     ▼
                      +------------------------------+
                      |   MapIntelligenceService     |
                      |  (Deterministic Calculations)|
                      +------------------------------+
                                     │
       ┌─────────────────────────────┼─────────────────────────────┐
       ▼                             ▼                             ▼
 [ Haversine Math ]         [ Overdue Analysis ]        [ Route Telemetry & Anomaly ]
 (Spatial Proximity)        (7+ Days Unvisited)         (Checkpoints, Distance, Idle)
       │                             │                             │
       └─────────────────────────────┼─────────────────────────────┘
                                     │
                                     ▼
                      +------------------------------+
                      |       Map Tools Engine       |
                      |  (get_overdue_shops,         |
                      |   get_next_recommendation,   |
                      |   get_route_summary,         |
                      |   get_area_coverage)         |
                      +------------------------------+
                                     │
                                     ▼
                      +------------------------------+
                      |    Interactive Entity Tag    |
                      |   & Map Action Deliverable   |
                      +------------------------------+
                                     │
                                     ▼
                      [ Flutter UI Interactive View ]
                      [ (📍 View on Map Action Tag)   ]
```

### 6.1 Strict Invariants:
1. **No LLM GPS Loop:** High-frequency GPS updates are stored and indexed deterministically in the database. AI is called only upon user request.
2. **Deterministic Recommendation Scoring:** Next shop candidate ranking uses $(\text{Days} \times 2.0) - (\text{Distance} \times 1.2)$ rather than opaque generative approximations.
3. **Structured Entity Interoperability:** Responses provide clean `entities` lists that the Flutter client uses to highlight map markers and trigger fly-to animations.

---

## 7. Voice, Multilingual & Offline Architecture (Phase 6)

```
                       [ Spoken / Typed User Query ]
                      (Hindi / Hinglish / English)
                                    │
                                    ▼
                     +------------------------------+
                     |    On-Device Speech & STT    |
                     |  (SpeechRecognitionProvider) |
                     +------------------------------+
                                    │
                                    ▼
                     +------------------------------+
                     |    Language & Script Engine  |
                     |  (AiLanguageDetector: hi/en) |
                     +------------------------------+
                                    │
                  ┌─────────────────┴─────────────────┐
                  │ Online                            │ Offline
                  ▼                                   ▼
   +------------------------------+    +------------------------------+
   |    Laravel AI Gateway API    |    |       OfflineAiService       |
   |   (Sanctum Authenticated)    |    |  (Zero Authorization Bypass) |
   +------------------------------+    +------------------------------+
                  │                                   │
                  ▼                                   ▼
   [ Natural Response + 2-Step    ]    [ Local FAQ Guidance OR        ]
   [ Confirmation Cards (Phase 4) ]    [ "Online Connection Required" ]
                  │                                   │
                  └─────────────────┬─────────────────┘
                                    │
                                    ▼
                     +------------------------------+
                     |    On-Device Voice Output    |
                     |   (TextToSpeechProvider)     |
                     +------------------------------+
```

### 7.1 Safety Invariants:
1. **Zero Spoken Auto-Execution:** Spoken voice commands proposing write actions generate 2-step confirmation cards. Spoken confirmation is rejected; physical confirmation on the card is strictly required.
2. **No Stale GPS Fabrication:** When offline, live location queries are blocked with a clear notice. Stale coordinates are never fabricated as live telemetry.
3. **Native Hinglish Support:** Intent extraction directly matches Roman Hindi tokens without lossy pre-translation layers.

---

## 8. Phase 7: Proactive AI Agent & Predictive Intelligence Architecture

```
                      +------------------------------+
                      |   EmpTracker Telemetry DB    |
                      |  (Shops, Visits, Attendance) |
                      +------------------------------+
                                     │
                                     ▼
                      +------------------------------+
                      |       AiSignalDetector       |
                      |  (Overdue, Idle, Attendance) |
                      +------------------------------+
                                     │
                                     ▼
                      +------------------------------+
                      |        AiInsightEngine       |
                      |  (Severity, RBAC & Dedup)    |
                      +------------------------------+
                                     │
                    ┌────────────────┴────────────────┐
                    │                                 │
                    ▼                                 ▼
    +------------------------------+   +------------------------------+
    |       Admin Operations       |   |       Employee Scoped        |
    |  - Territory Risk Insights   |   |  - Self Telemetry Alerts     |
    |  - Executive Daily Summary   |   |  - Assigned Store Follow-ups |
    |  - Alert State Management    |   |  - Map Waypoint Navigation   |
    +------------------------------+   +------------------------------+
                    │                                 │
                    └────────────────┬────────────────┘
                                     │
                                     ▼
                      +------------------------------+
                      |  Human Decision & Action     |
                      | (Acknowledge / Confirmation) |
                      +------------------------------+
```

### 8.1 Key Phase 7 Invariants:
1. **AI is NOT Source of Truth:** Relational database records, GPS breadcrumbs, and timestamped check-ins remain deterministic ground truth; AI provides predictive signals, executive summaries, and recommendations.
2. **Deterministic Thresholds:** All signal triggers are bound to configurable settings in `config/ai.php` (`idle_threshold_minutes`, `shop_overdue_days`, `deduplication_cooldown_hours`).
3. **Zero Autonomous Business Mutation:** All recommendations require manager acknowledgment or routing through Phase 4 2-step cryptographic confirmation.



