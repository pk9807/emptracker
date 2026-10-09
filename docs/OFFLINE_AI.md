# EmpTracker Offline AI Architecture & Capability Matrix

## 1. Principles & Threat Invariants

1. **Zero Authorization Bypass:** Offline AI operates strictly over authorized on-device caches and local guidance files. It NEVER grants root access or bypasses role permissions.
2. **Deterministic Freshness Standard:**
   - Real-time GPS locations and active speed telemetry **require a live server connection**.
   - Offline queries for live coordinates explicitly return: *"Live employee location requires an active internet connection. It is not available in offline mode."*
   - Stale coordinates are NEVER presented as live ground truth.
3. **No Offline Write Actions:** State modifications (task allocations, shop assignment, leave approvals) are strictly online-only and require atomic 2-step verification on the Laravel server.

---

## 2. Feature Capability Matrix

| Feature / Domain | Offline Capable? | Fresh Server Data Required? | Role Access | Offline Fallback Action |
| :--- | :---: | :---: | :---: | :--- |
| **App Navigation & General FAQ** | Yes | No | All Users | Local deterministic knowledge base reply |
| **Punch In & Attendance Guidance** | Yes | No | All Users | Step-by-step local guidance |
| **Shop Visit Check-in Policy** | Yes | No | All Users | Geofence rules and instructions |
| **Cached Route Agenda** | Yes | No | Self / Admin | Displays previously synced store targets |
| **Live Employee Radar Telemetry** | No | Yes | Self / Admin | `[BLOCKED]` Returns offline notice |
| **Live Route Deviations** | No | Yes | Self / Admin | `[BLOCKED]` Returns connection required message |
| **Assign Store / Add Note (Write)** | No | Yes | Admin / Employee | `[BLOCKED]` Online verification required |

---

## 3. Client Offline Fallback Pipeline

```
[ User Input ]
      │
      ▼
[ Network Gateway Check ]
      ├── Online  ────────> [ Laravel AI API Gateway ] ───> [ Local/Cloud AI Engine ]
      │
      └── Offline ────────> [ OfflineAiService ]
                                  │
                  ┌───────────────┴───────────────┐
                  ▼                               ▼
        [ Knowledge / FAQ ]             [ Live Query / Write ]
        (Punch In, Guides)              (Location, Assign)
                  │                               │
                  ▼                               ▼
        [ Instant Local Answer ]        [ Safe Offline Warning ]
                                        (Zero Data Leakage)
```
