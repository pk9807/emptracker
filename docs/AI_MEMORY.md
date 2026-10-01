# AI PERSISTENT PROJECT MEMORY

## 1. Project Context
- **Name:** Employee Live Tracking, Attendance and Shop/Office Visit Management System (FieldForce Pro).
- **Core Technology:** Flutter (SDK 3.49.0-0.1.pre / Dart 3.12.0), Firebase (Firestore, Auth, Storage, FCM), Google Maps.
- **Root Workspace:** `/var/www/html/emptracker`.

## 2. Key Architecture Directives
- **Zero Custom PHP/Laravel:** Exclusively Flutter + Firebase Serverless Architecture.
- **Monorepo:** `apps/employee_app`, `apps/admin_app`, `packages/core`, `packages/models`, `packages/design_system`, `packages/firebase_repository`, `packages/location_engine`, `packages/map_engine`, `packages/services`.
- **UI Quality:** Premium Figma-grade SaaS aesthetic, glassmorphism, 3D map controls, animated status markers.
- **Location Engine:** Foreground background service, adaptive rate limiting, battery saver diagnostics, anomaly detection.
- **Offline First:** SQLite / Drift local cache with transactional sync priority queue.
