# FIELD FORCE PRO — LARAVEL 11 & MYSQL DATABASE SCHEMA

## 1. Database Architecture Overview

- **Engine:** MySQL 8.0 (InnoDB, `utf8mb4_unicode_ci`)
- **Backend Framework:** Laravel 11
- **Authentication:** Laravel Sanctum (Bearer Token Authorization)
- **Base API Endpoint:** `http://192.168.0.106/emptracker/backend/public/index.php/api`

---

## 2. Relational Database Tables

### Table: `users`
| Column | Type | Attributes | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, Auto Increment | Unique User ID |
| `name` | VARCHAR(255) | NOT NULL | User Full Name |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL | Login Email |
| `password` | VARCHAR(255) | NOT NULL | Hashed Password (Bcrypt) |
| `role` | VARCHAR(50) | NOT NULL DEFAULT 'employee' | Role: `admin`, `employee`, `manager` |
| `phone` | VARCHAR(20) | NULLABLE | Phone Number |
| `employee_code`| VARCHAR(50) | UNIQUE, NULLABLE | e.g. `EMP-101` |
| `designation` | VARCHAR(100) | NULLABLE | e.g. `Senior Field Executive` |
| `department` | VARCHAR(100) | NULLABLE | e.g. `FMCG Sales` |
| `avatar` | VARCHAR(500) | NULLABLE | Profile Image URL |
| `is_active` | BOOLEAN | DEFAULT TRUE | Account Status |
| `created_at` | TIMESTAMP | NULLABLE | Creation timestamp |
| `updated_at` | TIMESTAMP | NULLABLE | Last update timestamp |

---

### Table: `live_locations` (Ola / Uber Real-Time Radar)
| Column | Type | Attributes | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, Auto Increment | Unique Radar Record ID |
| `user_id` | BIGINT UNSIGNED | UNIQUE, FK -> users.id | Associated Employee User |
| `latitude` | DOUBLE(11, 8) | NOT NULL | Current GPS Latitude |
| `longitude` | DOUBLE(11, 8) | NOT NULL | Current GPS Longitude |
| `accuracy` | DOUBLE(8, 2) | DEFAULT 5.0 | GPS Accuracy (meters) |
| `speed` | DOUBLE(8, 2) | DEFAULT 0.0 | Speed in m/s |
| `heading` | DOUBLE(8, 2) | DEFAULT 0.0 | Heading / Bearing (0-360°) |
| `altitude` | DOUBLE(8, 2) | DEFAULT 0.0 | Altitude in meters |
| `battery_level`| INT | DEFAULT 100 | Phone battery % |
| `is_mocked` | BOOLEAN | DEFAULT FALSE | Mock GPS detector flag |
| `activity_type`| VARCHAR(50) | DEFAULT 'STILL' | `STILL`, `WALKING`, `IN_VEHICLE` |
| `is_online` | BOOLEAN | DEFAULT TRUE | Online status |
| `last_ping_at` | DATETIME | NOT NULL | Last received GPS ping |

---

### Table: `location_histories` (Breadcrumb Path Tracking)
| Column | Type | Attributes | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, Auto Increment | Point ID |
| `user_id` | BIGINT UNSIGNED | FK -> users.id | Employee User |
| `latitude` | DOUBLE(11, 8) | NOT NULL | GPS Latitude |
| `longitude` | DOUBLE(11, 8) | NOT NULL | GPS Longitude |
| `speed` | DOUBLE(8, 2) | DEFAULT 0.0 | Speed |
| `heading` | DOUBLE(8, 2) | DEFAULT 0.0 | Bearing |
| `accuracy` | DOUBLE(8, 2) | DEFAULT 5.0 | Accuracy |
| `battery_level`| INT | DEFAULT 100 | Battery level |
| `recorded_at` | DATETIME | NOT NULL | Recorded timestamp |

---

### Table: `shops` (Shops & Geofences)
| Column | Type | Attributes | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, Auto Increment | Shop ID |
| `name` | VARCHAR(255) | NOT NULL | Shop / Store Name |
| `owner_name` | VARCHAR(255) | NULLABLE | Contact Person |
| `phone` | VARCHAR(20) | NULLABLE | Contact Phone |
| `address` | VARCHAR(500) | NULLABLE | Physical Address |
| `latitude` | DOUBLE(11, 8) | NOT NULL | Geofence Center Latitude |
| `longitude` | DOUBLE(11, 8) | NOT NULL | Geofence Center Longitude |
| `geofence_radius_meters` | INT | DEFAULT 100 | Geofence Radius (meters) |
| `qr_code` | VARCHAR(100) | UNIQUE | QR Code Identifier |
| `category` | VARCHAR(50) | DEFAULT 'RETAIL' | `RETAIL`, `SUPERMARKET`, `PHARMACY` |
| `status` | VARCHAR(50) | DEFAULT 'ACTIVE' | `ACTIVE`, `INACTIVE` |
| `created_by` | BIGINT UNSIGNED | FK -> users.id | Admin who registered shop |

---

### Table: `employee_shops` (Shop Assignments)
| Column | Type | Attributes | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, Auto Increment | Pivot ID |
| `user_id` | BIGINT UNSIGNED | FK -> users.id | Assigned Employee |
| `shop_id` | BIGINT UNSIGNED | FK -> shops.id | Assigned Shop |
| `assigned_date`| DATE | NULLABLE | Assignment Date |
| `notes` | VARCHAR(255) | NULLABLE | Assignment Notes |

---

### Table: `attendances` (Duty Timesheets)
| Column | Type | Attributes | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, Auto Increment | Attendance ID |
| `user_id` | BIGINT UNSIGNED | FK -> users.id | Employee User |
| `date` | DATE | NOT NULL | Attendance Date |
| `check_in_time`| DATETIME | NOT NULL | Duty Punch-In Time |
| `check_out_time`| DATETIME | NULLABLE | Duty Punch-Out Time |
| `check_in_lat` | DOUBLE(11, 8) | NULLABLE | Punch-in GPS Lat |
| `check_in_lng` | DOUBLE(11, 8) | NULLABLE | Punch-in GPS Lng |
| `check_in_address` | VARCHAR(255) | NULLABLE | Geocoded Address |
| `check_out_lat`| DOUBLE(11, 8) | NULLABLE | Punch-out GPS Lat |
| `check_out_lng`| DOUBLE(11, 8) | NULLABLE | Punch-out GPS Lng |
| `total_distance_km` | DOUBLE(8, 2) | DEFAULT 0.0 | Total Distance Travelled |
| `status` | VARCHAR(50) | DEFAULT 'PRESENT'| `PRESENT`, `ON_DUTY`, `COMPLETED` |

---

### Table: `visits` (Shop Visits & Proofs)
| Column | Type | Attributes | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, Auto Increment | Visit ID |
| `user_id` | BIGINT UNSIGNED | FK -> users.id | Field Rep |
| `shop_id` | BIGINT UNSIGNED | FK -> shops.id | Target Shop |
| `check_in_time`| DATETIME | NOT NULL | Visit Check-In Timestamp |
| `check_out_time`| DATETIME | NULLABLE | Visit Check-Out Timestamp |
| `check_in_lat` | DOUBLE(11, 8) | NOT NULL | Check-In Latitude |
| `check_in_lng` | DOUBLE(11, 8) | NOT NULL | Check-In Longitude |
| `photo_url` | VARCHAR(500) | NULLABLE | Geo-tagged Watermarked Photo |
| `purpose` | VARCHAR(100) | NOT NULL | `ROUTINE_VISIT`, `ORDER_COLLECTION` |
| `outcome` | VARCHAR(100) | NULLABLE | `ORDER_PLACED`, `PAYMENT_RECEIVED` |
| `order_amount` | DECIMAL(12, 2)| DEFAULT 0.00 | Total Order Value |
| `is_verified_geofence` | BOOLEAN | DEFAULT FALSE | Verified within shop radius |
| `distance_from_shop_meters` | DOUBLE(8, 2)| DEFAULT 0.0 | Haversine distance calculated |
| `status` | VARCHAR(50) | DEFAULT 'STARTED'| `STARTED`, `COMPLETED` |

---

## 3. REST API Endpoint Mapping

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| `POST` | `/api/auth/login` | Public | Login for Admin & Employee (Returns Bearer Token) |
| `GET` | `/api/auth/me` | Sanctum | Authenticated Profile |
| `POST` | `/api/auth/logout` | Sanctum | Revoke Token |
| `GET` | `/api/location/live-radar` | Sanctum | Ola/Uber live telemetry feed of all field reps |
| `POST` | `/api/location/ping` | Sanctum | GPS update stream from mobile background service |
| `POST` | `/api/location/batch` | Sanctum | Buffered offline GPS upload |
| `GET` | `/api/location/history/{id}` | Sanctum | Breadcrumb path replay |
| `GET` | `/api/employees` | Sanctum | List field staff with duty status |
| `POST` | `/api/employees` | Sanctum | Admin registers new employee |
| `GET` | `/api/shops` | Sanctum | List shops & geofences |
| `POST` | `/api/shops` | Sanctum | Add new shop with geofence |
| `POST` | `/api/attendance/check-in` | Sanctum | Punch-in duty start |
| `POST` | `/api/attendance/check-out` | Sanctum | Punch-out duty end |
| `GET` | `/api/attendance/summary` | Sanctum | Admin attendance timesheet metrics |
| `POST` | `/api/visits/check-in` | Sanctum | Visit check-in with geofence calculation |
| `POST` | `/api/visits/{id}/check-out`| Sanctum | Complete visit with order value |
