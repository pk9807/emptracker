# EmpTracker AI Feature Matrix

This matrix categorizes all AI-powered capabilities, detailing role access, tool bindings, privacy tier, and operational priority.

---

## 1. Feature Matrix

| Feature | Role | Existing Baseline | AI Opportunity | Local AI Capable | Cloud Fallback | Deterministic Tool | Sensitive Data | Priority |
| :--- | :--- | :--- | :--- | :---: | :---: | :--- | :---: | :---: |
| **Daily Briefing & Tasks** | Employee | List of assigned shops | Conversational summary of today's schedule & route | ✅ Yes | Optional | `get_my_today_tasks` | Low | **P0** |
| **Attendance Inquiry** | Employee | Monthly log screen | Instant natural language punch status & hours query | ✅ Yes | No | `get_my_attendance` | Medium | **P0** |
| **Next Best Shop Advice** | Employee | Distance sort list | Recommendation based on proximity & pending status | ✅ Yes | Optional | `get_nearby_assigned_shops` | Low | **P1** |
| **Live Radar Search** | Admin | Visual map pins | "Find active employees near Kanpur Mall" | ✅ Yes | Optional | `search_employee_locations` | High | **P0** |
| **Inactive / Idle Alert** | Admin | Raw ping timestamps | Explanation of long inactivity or route deviation | ✅ Yes | Optional | `get_inactivity_anomalies` | High | **P0** |
| **Coverage & Missed Visits** | Admin | Static visit table | Weekly missed visit and low-frequency shop report | ✅ Yes | Yes | `get_shop_coverage_metrics` | Medium | **P0** |
| **Conversational Search** | Admin | Keyword filter | Flexible search across shops, employees, and visits | ✅ Yes | Optional | `search_entities_tool` | Medium | **P1** |
| **Multi-Language Assistant** | All | Manual guide modal | Direct contextual Q&A in Hindi, Hinglish, English | ✅ Yes | Yes | `get_knowledge_faq` | Low | **P0** |
| **Automated Task Creation** | Admin | Add task screen | AI prepares draft task with 2-step confirmation | ✅ Yes | Optional | `confirm_create_task` | High | **P1** |
| **Deep Performance Audit** | Admin | CSV export | Multi-week employee efficiency and route summary | Optional | ✅ Yes | `get_performance_deep_dive` | High | **P2** |

---

## 2. Priority Definitions
* **P0 (Must Have):** Core operational assistants (Daily Briefing, Live Radar Search, Attendance Summary, Multi-Language Q&A).
* **P1 (Important):** Proximity recommendations, missed visit analytics, 2-step confirmed write actions.
* **P2 (Advanced):** Multi-week deep predictive performance auditing and route anomaly modeling.
