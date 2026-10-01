# CHANGELOG

## [1.0.0-rc.1] - 2026-10-01
### Production Architecture & Multi-App Monorepo Implementation
- **Core Package (`packages/core`):** Added `HaversineCalculator`, `AnomalyDetector`, `DateTimeUtils`, `AppConstants`, and comprehensive unit test coverage.
- **Models Package (`packages/models`):** Full domain entities for `UserModel`, `EmployeeModel`, `LiveLocationModel`, `ShopModel`, `VisitModel`, `AttendanceModel`, `AssignmentModel`, `DeviceModel`, and `OrganizationModel`.
- **Design System (`packages/design_system`):** Figma-grade SaaS theme, Electric Indigo & Emerald palette, `GlassCard`, `DepthCard`, `StatusBadge`, `PulseRadarDot`, `SkeletonLoader`, `PrimaryButton`, `CustomTextField`, and responsive tokens.
- **Services Package (`packages/services`):** `SyncManager` offline queue with backoff, `WatermarkEngine` canvas renderer with GPS & timestamp overlay, and `LocalCacheService`.
- **Firebase Repositories (`packages/firebase_repository`):** Multi-tenant repository layer for Auth, Employee, Shop, Visit, Attendance, and Location streaming.
- **Location Engine (`packages/location_engine`):** Adaptive battery-conscious sampling, `TrackingForegroundService`, and `TrackingDiagnosticsService`.
- **Map Engine (`packages/map_engine`):** 3D Interactive Map, `EmployeeQuickCard`, and `RoutePlaybackView`.
- **Employee App (`apps/employee_app`):** Complete mobile workflow with Duty toggle, Geofenced shop check-in, watermarked camera photo proofs, attendance timesheets, and profile management.
- **Admin Command App (`apps/admin_app`):** Complete responsive SaaS dashboard with full-screen Live Tracking Map, Employee directory, Shop geofence editor, Visit audits, Attendance analytics, Route scrubber, and CSV/PDF export.
