# API & FIREBASE STRUCTURE

## 1. Firebase Service Architecture
- **Auth Provider:** Firebase Authentication (Email/Password + Session Tokens).
- **Database:** Cloud Firestore with real-time snapshot listeners for `live_locations` and paginated queries for `location_history` / `visits`.
- **Blob Storage:** Firebase Cloud Storage structured hierarchically:
  `organizations/{organizationId}/employees/{employeeId}/visits/{visitId}/[original|thumbnail].jpg`
- **Push Messaging:** Firebase Cloud Messaging (FCM) topic subscription per organization and per employee for mission-critical broadcasts.

## 2. Realtime Stream Topologies
- **Admin App Live Dashboard:** Single query listener on `collection('live_locations').where('organizationId', '==', currentOrgId)` with client-side geohashing and marker diffing to minimize DOM rebuilds.
- **Employee App:** Listens to `assignments` collection for real-time task assignments and updates duty state.
