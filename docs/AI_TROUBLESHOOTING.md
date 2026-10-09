# EmpTracker AI Troubleshooting & Runbook

**Version:** 1.0.0 (Phase 2 Baseline)  
**Target:** System Operations, DevOps, and Support Engineers  

---

## 1. Quick Diagnostics Cheat Sheet

| Symptom | Probable Cause | Action |
| :--- | :--- | :--- |
| **HTTP 503 "AI features are disabled"** | `AI_ENABLED=false` in `.env` | Set `AI_ENABLED=true` in `backend/.env` and clear config cache (`php artisan config:clear`). |
| **HTTP 403 "You do not have permission"** | Actor role is `employee` attempting admin tool or querying other employee's ID | Verify `auth()->user()` role and ensure `$parameters['employee_id']` matches authenticated actor. |
| **HTTP 422 "Validation error"** | Missing required parameters (e.g. `message` field empty) | Verify payload JSON structure: `{"message": "Your question here"}`. |
| **Fallback to Deterministic Output** | Cloud AI blocked due to sensitivity | Expected behavior. `SENSITIVE` and `HIGHLY_SENSITIVE` data cannot be transmitted to external cloud APIs. |
| **Slow Inference Latency (>2s)** | Model running on un-accelerated CPU | Check engine memory metrics via `GET /api/ai/health`. Verify device RAM availability. |

---

## 2. Telemetry & Log Inspection

### Database Audit Logs
All queries, tool calls, and execution times are persisted in the `ai_audit_logs` table:
```sql
-- View recent 20 AI interactions
SELECT id, user_id, user_role, source, response_type, tools_used, latency_ms, created_at 
FROM emptracker_db.ai_audit_logs 
ORDER BY created_at DESC 
LIMIT 20;

-- Check execution errors or security blocks
SELECT * FROM emptracker_db.ai_audit_logs 
WHERE response_type = 'error' 
ORDER BY created_at DESC;
```

### Health Check Endpoint
```bash
curl -s http://localhost/emptracker/backend/public/index.php/api/ai/health | jq .
```
Expected Output:
```json
{
  "status": "success",
  "data": {
    "ai_enabled": true,
    "local_ai": {
      "enabled": true,
      "model": "qwen2.5-1.5b-instruct-q4"
    },
    "cloud_fallback": {
      "enabled": false,
      "provider": "gemini"
    }
  }
}
```

---

## 3. Emergency Kill-Switch & Rollback

If unexpected behavior or performance degradation occurs in production, disable AI immediately with zero impact on core attendance, GPS tracking, and shop management:

```bash
# In backend/.env
AI_ENABLED=false

# Apply configuration
php artisan config:clear
```
All existing endpoints (`/api/auth/*`, `/api/shops/*`, `/api/visits/*`, `/api/location/*`) will continue operating normally.
