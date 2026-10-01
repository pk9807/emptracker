# SHOP & OFFICE VISIT MANAGEMENT SYSTEM

## 1. End-to-End Visit Lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor Employee as Field Officer
    participant App as Employee App
    participant Engine as VisitEngine
    participant Storage as Local Drift / SQLite
    participant Firebase as Cloud Firestore & Storage
    actor Admin as Admin Dashboard

    Employee->>App: Tap "Visit Shop" / Select Shop
    App->>Engine: Evaluate Geofence (Haversine Formula)
    alt Outside Geofence (> 100m)
        Engine-->>App: Block Check-In ("You are 240m away")
    else Inside Geofence (<= 100m)
        Engine-->>App: Enable Check-In
        Employee->>App: Tap "Check-In"
        App->>Engine: Capture GPS + Timestamp
        Employee->>App: Capture Camera Photo Proof
        App->>Engine: Render Real-time Canvas Watermark (Name, Shop, Lat/Lng, Time)
        Employee->>App: Enter Notes & Order Details
        Employee->>App: Tap "Complete Visit / Check-Out"
        Engine->>Storage: Save Visit Record & Queue Sync Task
        Storage->>Firebase: Upload Watermarked Image & Firestore Document
        Firebase-->>Admin: Realtime Visit Alert & Timeline Update
    end
```

## 2. Geofence Calculation (Haversine Formula)
Client-side and Cloud-side verification uses the standard spherical distance formula:
$$d = 2r \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta \phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta \lambda}{2}\right)}\right)$$
where $r = 6371000$ meters.

## 3. Watermarking Specification
When photo proof is captured:
- **Canvas Overlay:** Bottom 20% darkened banner with high contrast typography.
- **Embedded Details:**
  - Organization Name / App Header
  - Shop Name & Code
  - Employee Full Name & Employee Code
  - Human Readable Date & Local Time (IST/UTC)
  - Exact GPS Latitude & Longitude with Accuracy Radius
- Both high-res watermarked original and 200x200 compressed thumbnail are generated.
