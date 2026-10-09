---
name: emptracker-engine
description: >-
  Comprehensive operational blueprint, debugging guide,
  map engine protocols, and automated testing workflows for
  the FieldForce Employee & Shop Tracker platform.
---

# FieldForce Tracker Master Skill Guide (EmpTracker)

This skill provides comprehensive architectural guidelines,
map search algorithms, automated testing procedures, and
deployment workflows for the FieldForce Tracker system.

---

## 1. Core System Architecture

The project is structured as a modular Flutter monorepo
paired with a Laravel RESTful backend and MySQL database:

```
emptracker/
├── apps/
│   ├── admin_app/          # Admin Console (Radar, Analytics)
│   └── employee_app/       # Mobile App (Duty, Visits, GPS)
├── packages/
│   ├── core/               # Constants, Network, Localization
│   ├── models/             # Data models (User, Shop, Visit)
│   ├── map_engine/         # OSM & Google Maps Live Radar
│   ├── firebase_repository/# Laravel REST API + Cache layer
│   └── design_system/      # UI components, badges, cards
├── backend/                # Laravel 11 REST API Backend
├── mobile_emulator/        # Web Mobile Device Simulator
└── downloads/              # Android APK distribution hub
```

---

## 2. Storelocator & Geo-Proximity Protocols

### A. Nearby Search & Haversine Sorting
All shop and location queries must be sorted by proximity
relative to the user's current GPS position:

$$\text{Distance}(P_1, P_2) = 2R \cdot \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta \text{lat}}{2}\right) + \cos(\text{lat}_1)\cos(\text{lat}_2)\sin^2\left(\frac{\Delta \text{lon}}{2}\right)}\right)$$

* **Default Center Coordinates:**
  * **Primary (Kanpur, UP):** `26.4499° N, 80.3319° E`
  * **Fallback (New Delhi, NCR):** `28.6139° N, 77.2090° E`
* **Search Execution Flow:**
  1. Exact keyword match on Shop Name, Owner, Category.
  2. Fuzzy/Sub-string match with accent insensitivity.
  3. Distance filtering (e.g., `< 5 km`, `< 15 km`, `< 50 km`).
  4. Auto-ranking: Nearest first, with walking/driving ETA.

### B. Map Marker Actions & Rich Bottom Sheets
When selecting any location marker, render the rich sheet:
* **Directions:** Turn-by-turn routing overlay.
* **Near By:** Radius-based discovery of nearby clients.
* **Save / Bookmark:** Local device bookmarking.
* **Share:** Geo-URI and direct web map link sharing.
* **Send to Phone:** SMS/WhatsApp location dispatch.

---

## 3. Authentication & API Data Parsing Rules

### Critical MySQL / Laravel Type Safety Rules:
1. **Boolean Type Casting (`is_active`, `is_verified`):**
   * MySQL stores booleans as `TINYINT(1)` (`0` or `1`).
   * Never do direct `as bool?` casts in Dart models.
   * **Always use safe parsing:**
     ```dart
     final ActiveVal = Json['is_active'];
     final bool IsActive = ActiveVal == null ||
         ActiveVal == true ||
         ActiveVal == 1 ||
         ActiveVal == '1';
     ```
2. **Numeric ID & String Conversion:**
   * Always parse IDs safely: `(Json['id'] ?? '').toString()`.
3. **Role Normalization:**
   * Normalize user roles: `'admin'`, `'superadmin'`, and
     `'manager'` map to `UserRole.admin`.

---

## 4. Multi-Language User Guide Module

EmpTracker includes built-in contextual manuals for Admin
and Employee roles with real-time multi-language switching:

* **Supported Languages:**
  * 🇮🇳 Hindi (हिन्दी)
  * 🌐 Hinglish (Hindi-English Blend)
  * 🇬🇧 English
  * 🇳🇵 Nepali (नेपाली)
  * 🇮🇳 Gujarati (ગુજરાતી)
  * 🇮🇳 Marathi (मराठी)
  * 🇮🇳 Bengali (বাংলা)
  * 🇮🇳 Tamil (தமிழ்)
  * 🇮🇳 Telugu (తెలుగు)

* **Guide Topics:**
  * **Admin:** Real-time Employee Radar, Geofence alerts,
    Shop approvals, Exporting attendance & CSV analytics.
  * **Employee:** Punching in/out, Background GPS tracking,
    Logging shop visits with geo-tagged photos, Offline sync.

---

## 5. Automated Screen Testing & Debugging

When debugging visual screens, maps, and login workflows:

1. **Access Web Emulator:** `http://localhost/emptracker/mobile_emulator/`
2. **Direct App URLs:**
   * Admin Portal: `http://localhost/emptracker/admin/`
   * Employee App: `http://localhost/emptracker/employee/`
   * Downloads Portal: `http://localhost/emptracker/downloads/`
3. **Default Testing Credentials:**
   * **Admin:** `admin@fieldforce.com` / `Admin@123456`
   * **Employee:** `rahul@fieldforce.com` / `Emp@123456`

---

## 6. Build & Deployment Commands

### Web Build
```bash
# Admin App Web Build
cd /var/www/html/emptracker/apps/admin_app
flutter build web --base-href "/emptracker/admin/" \
  --output /var/www/html/emptracker/admin/

# Employee App Web Build
cd /var/www/html/emptracker/apps/employee_app
flutter build web --base-href "/emptracker/employee/" \
  --output /var/www/html/emptracker/employee/
```

### Android Release APK Build
```bash
# Admin Release APK
cd /var/www/html/emptracker/apps/admin_app
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk \
  /var/www/html/emptracker/downloads/admin-app.apk
cp build/app/outputs/flutter-apk/app-release.apk \
  /var/www/html/emptracker/downloads/admin-app-release.apk

# Employee Release APK
cd /var/www/html/emptracker/apps/employee_app
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk \
  /var/www/html/emptracker/downloads/employee-app.apk
cp build/app/outputs/flutter-apk/app-release.apk \
  /var/www/html/emptracker/downloads/employee-app-release.apk
```
