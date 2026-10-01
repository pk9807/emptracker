# LOCATION TRACKING & BACKGROUND SERVICE ARCHITECTURE

## 1. Adaptive Location Engine Principles
To prevent rapid battery drain and excessive Firestore write costs, the `LocationEngine` utilizes an adaptive Kalman-filtered state machine:

| State | Speed Threshold | Sample Interval | Distance Filter | Min Accuracy Required |
|---|---|---|---|---|
| **Stationary / Rest** | < 1.0 km/h | 60 - 120 seconds | 25 meters | 30 meters |
| **Walking / In-Store**| 1.0 - 6.0 km/h | 30 seconds | 15 meters | 20 meters |
| **In-Transit / Vehicle**| > 6.0 km/h | 15 - 20 seconds | 30 meters | 25 meters |

## 2. Background Android Service Architecture
- **Foreground Service:** Runs with a persistent, non-dismissible notification (`FieldForce Pro is tracking your active duty route`).
- **Permissions:** 
  - `ACCESS_FINE_LOCATION`
  - `ACCESS_COARSE_LOCATION`
  - `ACCESS_BACKGROUND_LOCATION`
  - `FOREGROUND_SERVICE_LOCATION`
  - `POST_NOTIFICATIONS`
  - `WAKE_LOCK`
- **Battery Optimization:** In-app wizard guides user to whitelist app from aggressive OEM battery savers (Xiaomi MIUI/HyperOS, Samsung OneUI, OnePlus OxygenOS).

## 3. Anomaly & Fraud Detection Engine
1. **Mock Location Detection:** Inspects `isMocked` flag on raw Android Location objects and rejects fake GPS providers.
2. **Teleportation / Speed Filter:** Rejects coordinate deltas indicating impossible transit speeds (> 180 km/h).
3. **Repeated Coordinate Stagnation:** Detects emulator loops that feed static artificial coordinates with 0.0m accuracy variation.
4. **Suspicious Flags:** Points violating threshold checks are recorded with `"isSuspicious": true` for Admin audit reviews rather than silently crashing.

## 4. Live vs Historical Split
- Writes to `live_locations/{employeeId}` (single document update with current coordinates, battery %, and status).
- Writes to local SQLite/Drift database first, then batches points into `location_history/{employeeId}/points` every 5 minutes or 15 points to slash Firestore write costs by 85%.
