# FIRESTORE DATABASE SCHEMA & DATA DICTIONARY

## 1. Top-Level Collections Architecture

All tenant data is strictly partitioned by `organizationId`.

### `organizations/{organizationId}`
```json
{
  "id": "org_123",
  "name": "Acme FMCG Pvt Ltd",
  "code": "ACME",
  "logoUrl": "https://storage...",
  "settings": {
    "requirePhotoProof": true,
    "requireWatermark": true,
    "geofenceRadiusDefault": 100,
    "dutyTrackingIntervalMoving": 20,
    "dutyTrackingIntervalStationary": 60,
    "staleThresholdSeconds": 300,
    "offlineThresholdSeconds": 900
  },
  "createdAt": "2026-10-01T00:00:00.000Z",
  "updatedAt": "2026-10-01T00:00:00.000Z"
}
```

### `users/{uid}`
```json
{
  "uid": "usr_abc123",
  "email": "rahul.sharma@acme.com",
  "phone": "+919876543210",
  "name": "Rahul Sharma",
  "photoUrl": "https://storage...",
  "role": "employee", // "super_admin" | "admin" | "manager" | "employee"
  "organizationId": "org_123",
  "employeeId": "emp_001",
  "active": true,
  "createdAt": "2026-10-01T00:00:00.000Z",
  "updatedAt": "2026-10-01T00:00:00.000Z"
}
```

### `employees/{employeeId}`
```json
{
  "id": "emp_001",
  "userId": "usr_abc123",
  "organizationId": "org_123",
  "name": "Rahul Sharma",
  "employeeCode": "EMP-2026-091",
  "phone": "+919876543210",
  "email": "rahul.sharma@acme.com",
  "photoUrl": "https://...",
  "designation": "Senior Field Sales Officer",
  "department": "FMCG Distribution",
  "active": true,
  "trackingStatus": "DUTY_ACTIVE", // "DUTY_ACTIVE" | "DUTY_INACTIVE" | "PAUSED"
  "lastLocation": {
    "latitude": 28.6139,
    "longitude": 77.2090,
    "accuracy": 8.5,
    "speed": 3.2,
    "heading": 142.0,
    "battery": 82,
    "timestamp": "2026-10-01T10:45:00.000Z"
  },
  "lastLocationAt": "2026-10-01T10:45:00.000Z",
  "deviceId": "dev_samsung_s23_09"
}
```

### `live_locations/{employeeId}` (Optimized Real-time Tracking Document)
```json
{
  "employeeId": "emp_001",
  "organizationId": "org_123",
  "name": "Rahul Sharma",
  "photoUrl": "https://...",
  "latitude": 28.6139,
  "longitude": 77.2090,
  "accuracy": 6.2,
  "speed": 4.1,
  "heading": 180.0,
  "altitude": 215.0,
  "battery": 82,
  "network": "WIFI", // "WIFI" | "CELLULAR_4G" | "CELLULAR_5G" | "OFFLINE"
  "trackingStatus": "LIVE", // "LIVE" | "RECENT" | "STALE" | "OFFLINE"
  "isMockLocation": false,
  "updatedAt": "2026-10-01T10:45:00.000Z"
}
```

### `location_history/{employeeId}/points/{pointId}` (Historical Route Ledger)
```json
{
  "id": "pt_9876",
  "employeeId": "emp_001",
  "organizationId": "org_123",
  "latitude": 28.6139,
  "longitude": 77.2090,
  "accuracy": 6.2,
  "speed": 4.1,
  "heading": 180.0,
  "battery": 82,
  "dateKey": "2026-10-01",
  "timestamp": "2026-10-01T10:45:00.000Z",
  "createdAt": "2026-10-01T10:45:02.000Z"
}
```

### `shops/{shopId}`
```json
{
  "id": "shop_555",
  "organizationId": "org_123",
  "name": "Shree Ganesh Supermarket",
  "code": "SHP-DEL-041",
  "address": "Shop 4, Block C, Connaught Place, New Delhi",
  "latitude": 28.6328,
  "longitude": 77.2197,
  "radius": 100, // in meters
  "contactPerson": "Ramesh Kumar",
  "phone": "+919811122233",
  "status": "ACTIVE",
  "createdAt": "2026-09-15T00:00:00.000Z",
  "updatedAt": "2026-09-15T00:00:00.000Z"
}
```

### `assignments/{assignmentId}`
```json
{
  "id": "asgn_101",
  "organizationId": "org_123",
  "employeeId": "emp_001",
  "shopId": "shop_555",
  "priority": "HIGH", // "LOW" | "MEDIUM" | "HIGH" | "URGENT"
  "startDate": "2026-10-01T00:00:00.000Z",
  "endDate": "2026-10-01T23:59:59.000Z",
  "status": "PENDING", // "PENDING" | "VISITED" | "MISSED" | "CANCELLED"
  "assignedBy": "usr_mgr_44"
}
```

### `attendance/{attendanceId}`
```json
{
  "id": "att_20261001_emp001",
  "organizationId": "org_123",
  "employeeId": "emp_001",
  "dateKey": "2026-10-01",
  "startTime": "2026-10-01T09:00:15.000Z",
  "startLocation": {
    "latitude": 28.6139,
    "longitude": 77.2090,
    "address": "Home Base / Sector 12"
  },
  "endTime": "2026-10-01T18:05:00.000Z",
  "endLocation": {
    "latitude": 28.6140,
    "longitude": 77.2092,
    "address": "Connaught Place Office"
  },
  "workingDurationMinutes": 545,
  "totalVisitsCount": 8,
  "totalDistanceKm": 24.6,
  "status": "COMPLETED" // "WORKING" | "COMPLETED" | "LATE" | "HALF_DAY"
}
```

### `visits/{visitId}`
```json
{
  "id": "vst_20261001_889",
  "organizationId": "org_123",
  "employeeId": "emp_001",
  "employeeName": "Rahul Sharma",
  "shopId": "shop_555",
  "shopName": "Shree Ganesh Supermarket",
  "checkInTime": "2026-10-01T10:15:00.000Z",
  "checkInLocation": {
    "latitude": 28.6327,
    "longitude": 77.2196,
    "accuracy": 5.0,
    "distanceFromShop": 22.4
  },
  "checkOutTime": "2026-10-01T10:45:00.000Z",
  "checkOutLocation": {
    "latitude": 28.6328,
    "longitude": 77.2197,
    "accuracy": 4.5
  },
  "durationMinutes": 30,
  "photoUrl": "https://storage.googleapis.com/...",
  "thumbnailUrl": "https://storage.googleapis.com/...",
  "watermarkData": {
    "applied": true,
    "timestamp": "2026-10-01T10:20:00.000Z",
    "gpsText": "28.6327, 77.2196"
  },
  "notes": "Delivered 5 cartons of Premium Tea. Payment collected by UPI.",
  "orderValue": 14500.0,
  "status": "COMPLETED", // "CHECKED_IN" | "COMPLETED" | "FLAGGED"
  "isOfflineSynced": false,
  "syncTimestamp": "2026-10-01T10:45:05.000Z"
}
```

### `devices/{deviceId}`
```json
{
  "id": "dev_samsung_s23_09",
  "employeeId": "emp_001",
  "organizationId": "org_123",
  "deviceName": "Samsung Galaxy S23",
  "platform": "Android 15",
  "appVersion": "1.0.0+1",
  "battery": 82,
  "fcmToken": "fcm_token_xyz...",
  "lastSeen": "2026-10-01T10:45:00.000Z",
  "isActive": true
}
```
