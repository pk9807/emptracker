# FIREBASE SECURITY RULES & AUTHORIZATION MATRIX

## 1. Role-Based Access Matrix

| Collection / Path | Super Admin | Company Admin | Manager | Employee | Unauthenticated |
|---|---|---|---|---|---|
| `organizations/{orgId}` | Full Read/Write | Read / Write Own Org | Read Own Org | Read Own Org | Deny |
| `users/{uid}` | Full Read/Write | Read/Write Org Users | Read Assigned | Read/Write Self | Deny |
| `employees/{empId}` | Full Read/Write | Read/Write Org Emps | Read Org Emps | Read Self | Deny |
| `live_locations/{empId}` | Full Read/Write | Read Org Emps | Read Org Emps | Write Self (Duty on) | Deny |
| `location_history/{empId}/...` | Full Read/Write | Read Org Emps | Read Org Emps | Write Self | Deny |
| `shops/{shopId}` | Full Read/Write | Read/Write Org Shops | Read Org Shops | Read Org Shops | Deny |
| `assignments/{asgnId}` | Full Read/Write | Read/Write Org | Read/Write Org | Read Assigned | Deny |
| `attendance/{attId}` | Full Read/Write | Read/Write Org | Read Org | Read/Write Self | Deny |
| `visits/{visitId}` | Full Read/Write | Read/Write Org | Read Org | Read/Write Self | Deny |
| `devices/{devId}` | Full Read/Write | Read/Write Org | Read Org | Read/Write Self | Deny |

## 2. Firestore Security Rules Specification (`firestore.rules`)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    function isSuperAdmin() {
      return isAuthenticated() && getUserData().role == 'super_admin';
    }
    
    function isOrgAdmin(orgId) {
      return isAuthenticated() && (
        isSuperAdmin() || 
        (getUserData().role == 'admin' && getUserData().organizationId == orgId)
      );
    }
    
    function isOrgMember(orgId) {
      return isAuthenticated() && (
        isSuperAdmin() || 
        getUserData().organizationId == orgId
      );
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Organizations
    match /organizations/{orgId} {
      allow read: if isOrgMember(orgId);
      allow write: if isOrgAdmin(orgId);
    }

    // Users
    match /users/{userId} {
      allow read: if isAuthenticated() && (isOwner(userId) || isOrgMember(resource.data.organizationId));
      allow write: if isAuthenticated() && (isOwner(userId) || isOrgAdmin(request.resource.data.organizationId));
    }

    // Live Locations
    match /live_locations/{employeeId} {
      allow read: if isAuthenticated() && isOrgMember(resource.data.organizationId);
      allow write: if isAuthenticated() && (
        (getUserData().employeeId == employeeId && request.resource.data.organizationId == getUserData().organizationId) ||
        isOrgAdmin(request.resource.data.organizationId)
      );
    }

    // Location History
    match /location_history/{employeeId}/points/{pointId} {
      allow read: if isAuthenticated() && isOrgMember(resource.data.organizationId);
      allow write: if isAuthenticated() && (
        (getUserData().employeeId == employeeId && request.resource.data.organizationId == getUserData().organizationId) ||
        isOrgAdmin(request.resource.data.organizationId)
      );
    }

    // Shops
    match /shops/{shopId} {
      allow read: if isAuthenticated() && isOrgMember(resource.data.organizationId);
      allow write: if isAuthenticated() && isOrgAdmin(request.resource.data.organizationId);
    }

    // Attendance
    match /attendance/{attId} {
      allow read: if isAuthenticated() && isOrgMember(resource.data.organizationId);
      allow create, update: if isAuthenticated() && (
        (getUserData().employeeId == request.resource.data.employeeId && request.resource.data.organizationId == getUserData().organizationId) ||
        isOrgAdmin(request.resource.data.organizationId)
      );
    }

    // Visits
    match /visits/{visitId} {
      allow read: if isAuthenticated() && isOrgMember(resource.data.organizationId);
      allow create, update: if isAuthenticated() && (
        (getUserData().employeeId == request.resource.data.employeeId && request.resource.data.organizationId == getUserData().organizationId) ||
        isOrgAdmin(request.resource.data.organizationId)
      );
    }
  }
}
```

## 3. Storage Security Rules Specification (`storage.rules`)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /organizations/{orgId}/employees/{empId}/visits/{visitId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && (
        // Only allow image files under 10MB
        request.resource.size < 10 * 1024 * 1024 &&
        request.resource.contentType.matches('image/.*')
      );
    }
  }
}
```
