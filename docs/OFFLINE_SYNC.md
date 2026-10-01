# OFFLINE-FIRST SYNCHRONIZATION ENGINE

## 1. Zero-Loss Architecture
In remote field territories or underground retail basements where 4G/5G signal drops, the application operates completely offline without blocking duty operations or visit submissions.

## 2. Local Persistence (Drift / SQLite Schema)
1. `local_location_points`: Queued GPS points awaiting batch synchronization.
2. `local_attendance`: Offline duty start/end events with cryptographic idempotency key `uuidv4`.
3. `local_visits`: Completed visits with local image paths and timestamps.
4. `sync_queue`: Priority queue for retry management:
   - Priority 1: Duty Start/End (Immediate)
   - Priority 2: Visit Record Metadata (High)
   - Priority 3: Photo Binary Uploads (Medium)
   - Priority 4: Batch Historical Location Points (Low)

## 3. Sync Pipeline & Exponential Backoff
- Connectivity Listener monitors `connectivity_plus` (WiFi / Mobile / None).
- When connectivity switches to active:
  1. Acquire wake lock.
  2. Pull pending tasks ordered by priority and `created_at`.
  3. Execute transactional write to Firebase.
  4. On successful confirmation, mark as synced and cleanup local storage.
  5. On failure, schedule retry at $2^n \times 5$ seconds (capped at 5 minutes).
