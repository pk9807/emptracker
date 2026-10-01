# PROJECT CONTEXT & MASTER OVERVIEW

## 1. Project Identity
- **Project Name:** Employee Live Tracking, Attendance & Shop/Office Visit Management System (FieldForce Pro)
- **Target Platform:** 
  - Employee Mobile App (Android / iOS via Flutter)
  - Admin Web / Mobile / Tablet Dashboard (Flutter Web & Responsive App)
- **Core Technology Stack:** Flutter + Dart + Firebase Serverless Architecture + Google Maps
- **Monorepo Structure:** Multi-package modular architecture (`apps/`, `packages/`, `docs/`)

## 2. Business Objectives
1. **Real-time Live Employee Tracking:** Continuous background GPS monitoring during active duty hours with battery-conscious adaptive sampling (15s-30s moving, 60s-120s stationary).
2. **Shop & Office Visit Management:** Geofenced check-in/check-out with GPS + timestamp verification, camera photo proof, watermarking, and notes.
3. **Automated Duty & Attendance Tracking:** Start/End duty workflow tied to real-time status, geofenced clocking, and daily working hours calculation.
4. **Offline-First Resilience:** Zero data loss in weak/offline field environments via local SQLite/Drift caching, offline visit check-in, and transactional sync queues.
5. **Interactive 3D-Style Admin Live Map:** Real-time visibility of entire field force, animated status markers (Live, Recent, Stale, Offline), camera transitions, path history playback, and geofence visualizers.
6. **Role-Based Security & Multi-Tenancy:** Strict organization isolation (`organizationId`), multi-role access control (Super Admin, Company Admin, Manager, Employee), and hardened Firestore/Storage rules.

## 3. Environment & Tools State
- **Flutter SDK:** 3.49.0-0.1.pre / Dart 3.12.0
- **Platform Support:** Android (Foreground Service, Geofencing, WakeLocks, Camera2), iOS, Flutter Web / Responsive Desktop
- **Firebase Services:** Firebase Auth, Cloud Firestore, Cloud Storage, Firebase Cloud Messaging (FCM), App Check
- **Map Engine:** `google_maps_flutter` with 3D tilt, bearing, marker clustering, polyline compression, and custom canvas-drawn markers.
