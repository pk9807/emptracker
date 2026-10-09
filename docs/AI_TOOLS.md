# EmpTracker AI Tool Registry Documentation

**Version:** 1.0.0 (Phase 1 Baseline)  
**Security Model:** Role-Based Access Control + Employee Resource Isolation  

---

## 1. Tool Catalog Overview

| Tool Name | Purpose | Role Required | Data Sensitivity | Write Action |
| :--- | :--- | :---: | :---: | :---: |
| [`search_employees`](#1-search_employees) | Search employee directory with filters | `admin` | Sensitive | No |
| [`get_employee_profile`](#2-get_employee_profile) | Get employee profile & department | `employee` (Self) / `admin` (Any) | Sensitive | No |
| [`get_employee_location`](#3-get_employee_location) | Get latest verified GPS telemetry | `employee` (Self) / `admin` (Any) | Highly Sensitive | No |
| [`get_employee_attendance`](#4-get_employee_attendance) | Get attendance log & duty distance | `employee` (Self) / `admin` (Any) | Sensitive | No |
| [`get_employee_visits`](#5-get_employee_visits) | Get shop visit history & geofence flags | `employee` (Self) / `admin` (Any) | Sensitive | No |
| [`search_shops`](#6-search_shops) | Search shop directory by keywords | `employee` | Internal | No |
| [`get_shop_details`](#7-get_shop_details) | Get shop geofence radius & coordinates | `employee` | Internal | No |
| [`get_shop_visits`](#8-get_shop_visits) | Get visits for a specific shop | `employee` (Self) / `admin` (All) | Sensitive | No |
| [`get_nearby_shops`](#9-get_nearby_shops) | Find shops within radius using Haversine | `employee` | Internal | No |
| [`get_today_route`](#10-get_today_route) | Get assigned shops & pending visit agenda | `employee` (Self) / `admin` (Any) | Sensitive | No |
| [`assign_employee_shop`](#11-assign_employee_shop) | Assigns retail shop to employee route | `admin` | Internal | Yes (2-Step) |
| [`add_shop_urgent_note`](#12-add_shop_urgent_note) | Appends urgent operational note to shop | `employee` / `admin` | Internal | Yes (2-Step) |
| [`get_overdue_shops`](#14-get_overdue_shops) | Identifies shops unvisited for N days with map metadata | `employee` / `admin` | Internal | No |
| [`get_next_shop_recommendation`](#15-get_next_shop_recommendation) | Deterministic ranking for next optimal visit target | `employee` (Self) / `admin` (Any) | Internal | No |
| [`get_employee_route_summary`](#16-get_employee_route_summary) | Telemetry route distance, idle time, and visits | `employee` (Self) / `admin` (Any) | Sensitive | No |
| [`get_area_coverage_summary`](#17-get_area_coverage_summary) | Analyzes assigned vs visited coverage percentage | `employee` / `admin` | Internal | No |
| [`get_proactive_insights`](#18-get_proactive_insights) | Fetches ranked proactive operational risk alerts & signals | `employee` / `admin` | Internal | No |
| [`get_daily_operational_summary`](#19-get_daily_operational_summary) | Generates executive daily operational status & risk breakdown | `admin` | Sensitive | No |

---

## 2. Detailed Tool Specifications

### 1. `search_employees`
* **Purpose:** Allows administrators to filter active/inactive employees by keyword, department, or designation.
* **Input Schema:**
  ```json
  {
    "type": "object",
    "properties": {
      "query": { "type": "string", "description": "Keyword to match against name, email, employee code" },
      "is_active": { "type": "boolean", "description": "Filter by active status" },
      "department": { "type": "string", "description": "Filter by department" },
      "limit": { "type": "integer", "description": "Max records (default 10, max 50)" }
    }
  }
  ```
* **Output Schema:** Returns array of employee objects (`id`, `name`, `email`, `employee_code`, `department`, `designation`, `is_active`).
* **Role & Security:** Admin only. Employees receive `AiPermissionDeniedException`.
* **Data Sensitivity:** `sensitive`.
* **Audit Requirement:** Logged with search parameters and result count.

---

### 2. `get_employee_profile`
* **Purpose:** Inspect profile details for self or subordinate.
* **Input Schema:** `{ "employee_id": { "type": "integer" } }`
* **Output Schema:** `{ "id", "name", "email", "phone", "employee_code", "department", "designation", "is_active" }`
* **Role & Isolation:** Employees are restricted strictly to their own user ID. Passing another ID throws `AiPermissionDeniedException`.
* **Data Sensitivity:** `sensitive`.

---

### 3. `get_employee_location`
* **Purpose:** Fetches the latest live GPS coordinate, battery level, online status, and activity state from `live_locations`.
* **Input Schema:** `{ "employee_id": { "type": "integer" } }`
* **Output Schema:** `{ "employee_id", "employee_name", "latitude", "longitude", "accuracy", "speed", "battery_level", "is_online", "activity_type", "last_ping_at" }`
* **Role & Isolation:** Employee (self only) or Admin (any).
* **Data Sensitivity:** `highly_sensitive` (Strictly prohibited from cloud transmission).

---

### 4. `get_employee_attendance`
* **Purpose:** Fetches check-in/out timestamps, duty hours, battery levels, and distance traveled.
* **Input Schema:** `{ "employee_id": { "type": "integer" }, "date": { "type": "string" }, "days": { "type": "integer" } }`
* **Output Schema:** `{ "employee_id", "employee_name", "total_records", "records": [] }`
* **Role & Isolation:** Employee (self only) or Admin (any).
* **Data Sensitivity:** `sensitive`.

---

### 5. `get_employee_visits`
* **Purpose:** Fetches completed visits with geofence verification flag and order amounts.
* **Input Schema:** `{ "employee_id": { "type": "integer" }, "date": { "type": "string" }, "limit": { "type": "integer" } }`
* **Output Schema:** `{ "employee_id", "employee_name", "total_visits", "visits": [] }`
* **Role & Isolation:** Employee (self only) or Admin (any).
* **Data Sensitivity:** `sensitive`.

---

### 6. `search_shops`
* **Purpose:** Searches active shops by name, owner, or category.
* **Input Schema:** `{ "query": { "type": "string" }, "category": { "type": "string" }, "limit": { "type": "integer" } }`
* **Output Schema:** `{ "count": 5, "shops": [] }`
* **Role & Isolation:** All authenticated users (`employee`, `admin`).
* **Data Sensitivity:** `internal`.

---

### 7. `get_shop_details`
* **Purpose:** Retrieves shop address, geofence radius, owner contact, and coordinates.
* **Input Schema:** `{ "shop_id": { "type": "integer" } }` (Required)
* **Output Schema:** `{ "id", "name", "owner_name", "phone", "address", "category", "latitude", "longitude", "geofence_radius_meters", "status" }`
* **Role & Isolation:** All authenticated users.
* **Data Sensitivity:** `internal`.

---

### 8. `get_shop_visits`
* **Purpose:** Fetches visit history for a specific shop.
* **Input Schema:** `{ "shop_id": { "type": "integer" }, "limit": { "type": "integer" } }`
* **Output Schema:** `{ "shop_id", "shop_name", "total_visits", "visits": [] }`
* **Role & Isolation:** Employees only see their own visits to the shop; Admins see all field agent visits.
* **Data Sensitivity:** `sensitive`.

---

### 9. `get_nearby_shops`
* **Purpose:** Real-time spatial proximity search using the Haversine spherical equation.
* **Input Schema:** `{ "latitude": { "type": "number" }, "longitude": { "type": "number" }, "radius_km": { "type": "number" }, "limit": { "type": "integer" } }`
* **Output Schema:** `{ "origin": { "latitude", "longitude" }, "radius_km", "count", "shops": [] }`
* **Role & Isolation:** All authenticated users.
* **Data Sensitivity:** `internal`.

---

### 10. `get_today_route`
* **Purpose:** Retrieves daily assigned shops from `employee_shops` joined with today's `visits` to report completed vs pending tasks.
* **Input Schema:** `{ "employee_id": { "type": "integer" }, "date": { "type": "string" } }`
* **Output Schema:** `{ "employee_id", "employee_name", "date", "total_assigned_shops", "completed_visits_count", "pending_visits_count", "route": [] }`
* **Role & Isolation:** Employee (self only) or Admin (any).
* **Data Sensitivity:** `sensitive`.

---

### 11. `assign_employee_shop` (Write Action)
* **Purpose:** Assigns a store/shop to an employee route.
* **Input Schema:** `{ "employee_id": { "type": "integer" }, "shop_id": { "type": "integer" } }`
* **Output Schema:** `{ "success": true, "message": "...", "assignment_id": 12, "employee_name": "...", "shop_name": "..." }`
* **Role & Isolation:** Admin only. Requires 2-Step Cryptographic User Confirmation.
* **Data Sensitivity:** `internal`.

---

### 12. `add_shop_urgent_note` (Write Action)
* **Purpose:** Records an urgent operational note or reminder on a shop record.
* **Input Schema:** `{ "shop_id": { "type": "integer" }, "note": { "type": "string" } }`
* **Output Schema:** `{ "success": true, "message": "...", "shop_id": 13, "shop_name": "...", "note": "..." }`
* **Role & Isolation:** Admin / Employee. Requires 2-Step Cryptographic User Confirmation.
* **Data Sensitivity:** `internal`.

---

### 13. `record_visit_remark` (Write Action)
* **Purpose:** Records or updates remark/notes on a shop visit.
* **Input Schema:** `{ "shop_id": { "type": "integer" }, "remark": { "type": "string" } }`
* **Output Schema:** `{ "success": true, "message": "...", "visit_id": 5, "shop_name": "...", "remark": "..." }`
* **Role & Isolation:** Admin / Employee (for own visit). Requires 2-Step Cryptographic User Confirmation.
* **Data Sensitivity:** `internal`.

---

### 14. `get_overdue_shops`
* **Purpose:** Identifies registered shops unvisited for `days_threshold` (default 7 days) with structured map entities.
* **Input Schema:** `{ "days_threshold": { "type": "integer" }, "limit": { "type": "integer" } }`
* **Output Schema:** `{ "days_threshold": 7, "total_overdue": 3, "overdue_shops": [], "entities": [], "map_action": { "type": "show_entities", "filter": "overdue_shops" } }`
* **Role & Isolation:** Employee / Admin.
* **Data Sensitivity:** `internal`.

---

### 15. `get_next_shop_recommendation`
* **Purpose:** Deterministic scoring algorithm `(Days * 2.0) - (Distance * 1.2)` ranking pending assigned shops.
* **Input Schema:** `{ "employee_id": { "type": "integer" }, "current_lat": { "type": "number" }, "current_lng": { "type": "number" } }`
* **Output Schema:** `{ "employee_id": 1, "has_recommendation": true, "recommended_shop": { "id", "name", "distance_km", "days_since_last_visit", "score", "reason" }, "entities": [], "map_action": { "type": "show_entity" } }`
* **Role & Isolation:** Employee (self only) or Admin (any).
* **Data Sensitivity:** `internal`.

---

### 16. `get_employee_route_summary`
* **Purpose:** Computes daily route telemetry including total distance, checkpoints, idle time, completed visits, and deviations.
* **Input Schema:** `{ "employee_id": { "type": "integer" }, "date": { "type": "string" } }`
* **Output Schema:** `{ "employee_id", "date", "total_distance_km", "checkpoints_count", "idle_minutes", "visited_shops_count", "visited_shops": [], "deviations_detected": 0 }`
* **Role & Isolation:** Employee (self only) or Admin (any).
* **Data Sensitivity:** `sensitive`.

---

### 17. `get_area_coverage_summary`
* **Purpose:** Summarizes total assigned shops, visited count, pending count, and percentage coverage.
* **Input Schema:** `{ "area_name": { "type": "string" }, "date": { "type": "string" } }`
* **Output Schema:** `{ "area_name", "date", "total_assigned_shops", "visited_shops", "pending_shops", "coverage_percentage" }`
* **Role & Isolation:** Employee / Admin.
* **Data Sensitivity:** `internal`.


