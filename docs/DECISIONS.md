# ARCHITECTURAL DECISIONS RECORD (ADR)

## ADR-001: Monorepo Architecture with Modular Packages
- **Context:** Need maximum code reuse between Employee App and Admin App (models, design tokens, repositories, map logic) without duplication.
- **Decision:** Split into `apps/employee_app`, `apps/admin_app`, and shared `packages/*`.
- **Status:** Accepted.

## ADR-002: Flutter + Firebase Serverless Architecture (No PHP / Laravel)
- **Context:** Real-time location tracking requires low-latency websocket-like streaming and scalable serverless data sync.
- **Decision:** Use Cloud Firestore with `live_locations` collection for real-time tracking, Firebase Storage for watermarked photo proofs, and Firebase Auth for multi-tenant RBAC.
- **Status:** Accepted.

## ADR-003: Adaptive Location Tracking & Batch History
- **Context:** Continuous 1-second GPS updates rapidly drain device battery and generate excessive Firestore write costs.
- **Decision:** Implement speed-based sampling (15s moving, 60s stationary) and batch historical route points every 5 minutes/15 points.
- **Status:** Accepted.

## ADR-004: Client & Server Side Geofence Verification
- **Context:** Geofence verification must give instant UX feedback while ensuring tamper-proof submission.
- **Decision:** Use the Haversine formula on the client for immediate UI validation and store exact accuracy + coordinates in the visit document.
- **Status:** Accepted.
