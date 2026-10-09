# CHANGELOG

## [1.2.0] - 2026-10-01
### Enterprise Google Maps Live Tracking Parity & Rich Location Picker
- **Google Maps Live Telemetry Parity (`GoogleMapsLiveView`):**
  - High-DPI canvas-rendered custom dynamic bitmap markers with employee initials, pulsing radar halo rings, live green/amber online status dots, and name tag bubbles.
  - Universal Search Bar with instant geocoding autocomplete (Nominatim + local markers).
  - Floating control panel with Dark Cyberpunk JSON map style, Standard, Satellite/Hybrid, and Terrain modes.
  - Live traffic layer toggle, 3D tilt perspective (45° pitch), and auto-fit fleet bounds.
  - Interactive bottom `EmployeeQuickCard` and `ShopQuickCard` with one-tap route playback and actions.
- **Interactive Google Maps Location Picker Sheet (`GoogleMapsLocationPickerSheet`):**
  - Tappable/draggable map pin for shop geofencing on Google Maps.
  - Dynamic geofence radius slider (20m to 500m) with live visual circle feedback.
  - Instant address reverse-geocoding and quick city presets.
- **Shop Management Dual Picker:** Option to choose between Google Maps Pin and OpenStreetMap Pin.
- **Production APK Release:** Updated `downloads/employee-app-release.apk` (52MB) and `downloads/admin-app-release.apk` (55MB).

## [1.1.0] - 2026-10-01
### Dynamic Laravel 11 Backend & Real-Time Ola/Uber/Swiggy Live Radar Integration
- **Laravel 11 Backend (`backend/`):** Complete REST API with MySQL database (`emptracker_db`), migrations, Eloquent models, and Laravel Sanctum token authentication.
- **Dynamic Authentication:**
  - Admin login (`admin@fieldforce.com` / `Admin@123456`)
  - Admin employee registration modal with instant database record creation
  - Employee login (`rahul@fieldforce.com`, `priya@fieldforce.com`, `amit@fieldforce.com`, `vikram@fieldforce.com`, `ananya@fieldforce.com` / `Emp@123456`)
- **Ola / Uber / Swiggy Style Live Tracking:**
  - Real-time GPS pinging from Employee App (`/api/location/ping`)
  - Live Radar stream endpoint (`/api/location/live-radar`) polling every 3s for smooth animated moving markers on Google Map
  - Breadcrumb path replay (`/api/location/history/{id}`)
- **Dynamic Repositories (`packages/firebase_repository`):** Added `LaravelAuthRepository`, `LaravelEmployeeRepository`, `LaravelLocationRepository`, `LaravelShopRepository`, `LaravelVisitRepository`, and `LaravelAttendanceRepository`.
- **Release APKs:** Rebuilt both `apps/admin_app` and `apps/employee_app` with dynamic Laravel connectivity and updated download portal at `http://192.168.0.106/emptracker/downloads/`.

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
