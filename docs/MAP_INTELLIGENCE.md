# EmpTracker Phase 5: Map Intelligence & Tracking AI Architecture

## 1. Executive Summary & Core Principles

Phase 5 introduces an AI intelligence layer directly over EmpTracker's deterministic tracking, geofence, and visit telemetry without altering or degrading background GPS tracking or live map engines.

### Fundamental Rules:
1. **Never Run AI for Raw GPS Feeds:** Background location pings (GPS updates) flow exclusively into MySQL tables (`live_locations`, `location_histories`) deterministically. AI is queried **on-demand only** when natural language summarization, ranking, or route telemetry interpretation is requested.
2. **Deterministic-First Calculations:** Business metrics (Haversine distance, overdue days, idle minutes, visit counts, next-shop priority scores) are computed in PHP/Laravel backend services (`MapIntelligenceService`), **never** guessed or approximated by LLMs.
3. **Role & Resource Isolation:** Field employees can only query their own telemetry and assigned tasks. Cross-employee location requests by unauthorized staff trigger immediate `AiPermissionDeniedException` without data leakage.
4. **Zero-Hallucination Guardrails:** If live GPS telemetry or visit records are unavailable, the system deterministically reports `"No live location available"` or `"No recorded visits found"`.
5. **Interactive Map Entities:** Responses contain structured entity tags (`entities: [{ "type": "shop", "id": 101, "name": "..." }]`) allowing the Flutter UI to display interactive `"📍 View on Map"` buttons seamlessly.

---

## 2. Deterministic Intelligence Engine (`MapIntelligenceService`)

All geospatial and tracking math is centralized in `backend/app/AI/Services/MapIntelligenceService.php`.

### A. Haversine Distance Formula
```php
$dLat = deg2rad($lat2 - $lat1);
$dLon = deg2rad($lon2 - $lon1);
$a = sin($dLat / 2) * sin($dLat / 2) +
     cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
     sin($dLon / 2) * sin($dLon / 2);
$c = 2 * atan2(sqrt($a), sqrt(1 - $a));
return round(6371 * $c, 2); // Kilometers
```

### B. Overdue Shop Analysis
- Analyzes shop records joined with `visits` table.
- Identifies shops unvisited for $\ge 7$ days (or custom threshold).
- Returns sorted list with days since last visit and coordinates.

### C. Next-Shop Recommendation Scoring
Pending assigned shops are ranked using the deterministic heuristic:
$$\text{Score} = (\text{Days Since Last Visit} \times 2.0) - (\text{Distance in km} \times 1.2)$$
- Maximizes retail replenishment urgency while minimizing transit distance.
- Includes transparent explanation string in the response.

### D. Route Telemetry & Anomaly Analysis
- Evaluates ordered `location_histories` records for the date.
- Calculates total traversed distance, speed averages, and consecutive idle intervals ($>20$ minutes).
- Checks route deviation events using neutral, factual terminology.

---

## 3. Map Intelligence Tool Matrix

| Tool | Role Required | Sensitivity | Primary Action / Output |
| :--- | :---: | :---: | :--- |
| `get_overdue_shops` | Employee / Admin | `internal` | Unvisited shops list + `filter: "overdue_shops"` |
| `get_next_shop_recommendation` | Self / Admin | `internal` | Top ranked target + `show_entity` map action |
| `get_employee_route_summary` | Self / Admin | `sensitive` | Trajectory distance, idle mins, visits summary |
| `get_area_coverage_summary` | Employee / Admin | `internal` | Territory visit count, pending count, coverage % |

---

## 4. Privacy & Security Matrix

```
┌───────────────────────────┐
│ Authenticated User Token  │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│ Role & Ownership Check    │
│ (Admin vs Subordinate)    │
└─────────────┬─────────────┘
              │
      Pass    ▼    Fail
  ┌──────────────┐   ┌───────────────────────────┐
  │ Local AI/Tool│   │ 403 Forbidden Response    │
  │ Deterministic│   │ (Zero Location Leakage)   │
  └──────────────┘   └───────────────────────────┘
```

1. **Self-Inspection Policy:** Employees can access only their own `employee_id`. Admin can query any employee.
2. **Cloud Egress Safeguard:** High-sensitivity coordinates and route tracking telemetry are flagged `SENSITIVE` or `HIGHLY_SENSITIVE`, preventing unauthorized outbound transmission.

---

## 5. Flutter Map Assistant UI Integration

- Interactive query chips (e.g. *"Kaunse shops 7 din se visit nahi hue?", "Mera route summarize karo"*).
- Assistant bubbles parse `entities` and render interactive `"📍 View on Map (मैप पर देखें)"` buttons.
- Tapping an entity triggers map camera pan or filter without interrupting chat workflow.
