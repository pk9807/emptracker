# 🚀 FieldForce EmpTracker AI
### Enterprise Field Workforce Tracking, Geofenced Shop Audit & Multilingual Voice AI Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x%20%7C%20Dart%203-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Laravel](https://img.shields.io/badge/Laravel-11.x%20%7C%20PHP%208.2+-FF2D20?logo=laravel&logoColor=white)](https://laravel.com)
[![Android](https://img.shields.io/badge/Android-Native%20Speech%20%26%20TTS-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![OpenStreetMap](https://img.shields.io/badge/Maps-OpenStreetMap%20%2B%20Google%20Maps-7EBC6F?logo=openstreetmap&logoColor=white)](https://www.openstreetmap.org)
[![License](https://img.shields.io/badge/License-Proprietary%20%2F%20Enterprise-blue.svg)](#)

---

## 🎬 Live Platform Demo Walkthrough

<div align="center">
  <img src="docs/assets/emptracker_demo.gif" alt="EmpTracker FieldForce AI Demo Walkthrough" width="380" style="border-radius: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); border: 2px solid #6366f1;" />
  <p><em>Live Telemetry, 3D GPS Map Tracking, Geofenced Shop Visits & Multilingual Voice AI Assistant</em></p>
  <p><a href="docs/assets/emptracker_demo.mp4">▶️ <b>Watch Full HD Demo MP4 Video (60 FPS)</b></a></p>
</div>

---

## 📖 Project Overview

**EmpTracker (FieldForce AI)** is an enterprise-grade field employee telemetry, geofenced store auditing, live GPS tracking, and multilingual Voice AI assistant platform. 

It provides organizations, sales directors, and field operations managers with a comprehensive suite to track mobile workforce locations in real time, verify store visits with tamper-proof watermarked photos, manage geofenced attendance (Punch In / Punch Out), optimize travel routes, and interact with a conversational **Multilingual Voice AI Assistant** (supporting Hindi, Hinglish, and English).

---

## 🌟 Key Architecture & Features

### 🎙️ 1. Multilingual Voice AI Assistant (Speech-to-Text & Text-to-Speech)
- **Google Speech-to-Text Integration**: Tap the microphone (`🎙️`) to trigger Google Voice Recognition with native support for Indian accents in **Hindi (India)** and **English (India)**.
- **Real-Time Live Chatbox Streaming**: Spoken words are transcribed and populated directly into the chat input box (`Poochiye (Hindi, Hinglish, English)...`) in real time.
- **Visual 3-Second Auto-Send & Edit**: Displays an interactive countdown timer allowing users to review, edit, or immediately dispatch their voice commands.
- **Native Android Text-to-Speech (TTS)**: The AI responds in text and speaks the response aloud in natural Hindi or English.
- **Domain Guardrails & Out-of-Scope Protection**: Strict enterprise guardrails ensure the AI only answers operations queries (attendance, assigned shops, routes, team telemetry, visits) and politely declines non-work topics.

---

### 🗺️ 2. Live 3D Tracking & Map Intelligence Engine
- **Dual Map Engine Architecture**: Seamless one-tap switching between OpenStreetMap (Free / OSRM) and Google Maps 3D Live view.
- **Real-Time GPS Telemetry**: Monitors field staff battery level, movement speed, heading angle, and GPS accuracy with automatic offline fallback.
- **OSRM Intelligent Route Optimization**: Computes shortest travel paths and optimal visit sequences for multi-stop daily itineraries.
- **Nominatim Geocoding & Store Locator**: Fast spatial search for shops, supermarkets, medical stores, hotels, and custom geofences.

---

### 🏬 3. Geofenced Shop Visits & Proof Audit
- **Geofenced Verification**: Enforces minimum radial distance checks (50m - 200m) before an employee can mark a store visit.
- **Tamper-Proof Watermark Engine**: Automatically burns timestamp, staff name, GPS coordinates, and store name onto captured proof-of-visit camera photos.
- **Overdue & Stale Shop Prioritization**: Highlights unvisited or overdue outlets on the radar for immediate supervisor intervention.

---

### 👥 4. Dual Flutter Mobile Applications

#### A. Admin Command Center App (`apps/admin_app`)
- **Live 3D Radar Map**: Real-time multi-agent telemetry and field asset visualization.
- **Team Management**: Real-time staff duty roster, attendance logs, and route replay history.
- **Voice Commands**:
  - *"Active employees list dikhao"* (Show active employees)
  - *"Live radar shops check karo"* (Audit live radar shops)

#### B. Employee Field Operations App (`apps/employee_app`)
- **Daily Attendance**: Geofenced Punch In / Punch Out with location lock.
- **Assigned Stores**: Step-by-step visit checklist, order booking, and watermarked photo submission.
- **Voice Commands**:
  - *"Aaj ke pending shops dikhao"* (Show my pending shops today)
  - *"Mera next shop kaunsa hai"* (What is my next recommended visit?)

---

### 🔒 5. Enterprise Backend & Security
- **Laravel 11 RESTful API (`backend/`)**:
  - JWT / Sanctum bearer token authentication.
  - Multi-Org Tenant Isolation for secure data segregation.
  - 2-Step Authorization Guardrails (cryptographic confirmation tokens for write actions proposed by AI).
- **Offline-First Synchronization**: Local SQLite caching ensures field operations continue without interruption in low-connectivity areas.

---

## 🏗️ Repository Architecture

```
emptracker/
├── apps/
│   ├── admin_app/          # Flutter Admin Command Center Mobile Application
│   └── employee_app/       # Flutter Employee Field Operations Mobile Application
├── packages/
│   ├── core/               # Shared constants, API client, & utilities
│   ├── design_system/      # Enterprise UI widgets, AI Assistant Modal, User Guide
│   ├── firebase_repository/# Laravel REST API repository implementations
│   ├── location_engine/    # Background GPS tracking & geofencing engine
│   ├── map_engine/         # OSM + Google Maps, OSRM routing, & store locator
│   ├── models/             # Strongly-typed Dart domain models
│   └── services/           # Speech-to-Text, Native TTS, & Offline AI Engine
├── backend/                # Laravel 11 PHP Backend API & Local AI Engine
│   ├── app/AI/             # Domain Guardrails & Local Model Providers
│   ├── app/Http/           # REST Controllers (Location, Visit, Attendance, Shop)
│   └── database/           # Migrations & Seeders
└── docs/                   # System Architecture, AI Governance, & API Documentation
```

---

## 📱 Mobile Release Binaries

| Application | Platform | Binary Location |
|---|---|---|
| **Admin Command Center** | Android (API 26+) | [`downloads/emptracker-admin-release.apk`](file:///var/www/html/emptracker/downloads/emptracker-admin-release.apk) |
| **Employee Field App** | Android (API 26+) | [`downloads/emptracker-employee-release.apk`](file:///var/www/html/emptracker/downloads/emptracker-employee-release.apk) |

---

## 🚀 Setup & Execution Guide

### 1. Backend Setup (Laravel PHP)
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

### 2. Flutter Mobile Apps Build
```bash
# Build Admin Application
cd apps/admin_app
flutter pub get
flutter build apk --release

# Build Employee Application
cd apps/employee_app
flutter pub get
flutter build apk --release
```

### 3. Run on Connected Android Device
```bash
# Run Admin App
cd apps/admin_app
flutter run -d <device-id>

# Run Employee App
cd apps/employee_app
flutter run -d <device-id>
```

---

## 🧪 Automated Testing

```bash
# Run AI and Services Test Suite
cd packages/services
flutter test test/ai_services_test.dart
```
✅ **11/11 Passing Tests**: Multilingual Detection, Offline AI Intent Engine, Native Speech & TTS Handlers, Strict Domain Guardrails.

---

## 📄 License
Copyright © 2026 EmpTracker / FieldForce Platform. All rights reserved.
Developed by Pradeep Kashyap ([@pk9807](https://github.com/pk9807)).
