# 🚀 FieldForce EmpTracker AI
### Enterprise Field Employee Tracking, Shop Audit & Multilingual Voice AI Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x%20%7C%20Dart%203-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Laravel](https://img.shields.io/badge/Laravel-11.x%20%7C%20PHP%208.2+-FF2D20?logo=laravel&logoColor=white)](https://laravel.com)
[![Android](https://img.shields.io/badge/Android-Native%20Speech%20%26%20TTS-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![OpenStreetMap](https://img.shields.io/badge/Maps-OpenStreetMap%20%2B%20Google%20Maps-7EBC6F?logo=openstreetmap&logoColor=white)](https://www.openstreetmap.org)
[![License](https://img.shields.io/badge/License-Proprietary%20%2F%20Enterprise-blue.svg)](#)

---

## 📖 परियोजना का परिचय (Project Overview)

**EmpTracker (FieldForce AI)** एक संपूर्ण एंटरप्राइज-ग्रेड **फ़ील्ड कर्मचारी ट्रैकिंग, शॉप ऑडिट, लाइव जीपीएस टेलीमेट्री और वॉयस एआई असिस्टेंट** प्लेटफ़ॉर्म है।

यह सिस्टम संगठनों, सेल्स मैनेजरों और फ़ील्ड सुपरवाइज़रों को अपनी फ़ील्ड टीमों की लोकेशन ट्रैक करने, दुकानों के दौरे (Visits) सत्यापित करने, जियोफेंसिंग द्वारा उपस्थिति (Attendance) दर्ज करने और **हिंदी, हिंग्लिश व अंग्रेज़ी** में बोलकर बातचीत करने वाला स्मार्ट **वॉयस एआई असिस्टेंट (Voice AI Assistant)** प्रदान करता है।

---

## 🌟 मुख्य विशेषताएँ (Key Features)

### 🎙️ 1. Multilingual Voice AI Assistant (आवाज़ से चलने वाला एआई सहायक)
- **Google Speech-to-Text Integration**: माइक आइकन (`🎙️`) दबाते ही Google Voice सक्रिय होता है और हिंदी, हिंग्लिश या इंग्लिश में बोली गई आवाज़ को तुरंत पहचानता है।
- **Real-Time Live Chatbox Writing**: बोले गए शब्द सीधे चैट बॉक्स (`Poochiye...`) में टाइप होकर लाइव दिखाई देते हैं।
- **Smart 3-Second Auto-Send & Edit**: आवाज़ पहचानने के बाद 3-सेकंड का विजुअल काउंटडाउन आता है जिससे यूज़र टेक्स्ट देख सकता है, तुरंत भेज सकता है या एडिट कर सकता है।
- **Native Android Text-to-Speech (TTS)**: एआई असिस्टेंट का रिप्लाई न केवल टेक्स्ट में आता है बल्कि स्क्रीन पर बोलकर (Voice Audio) भी सुनाया जाता है।
- **Domain Guardrails & Hardening**: असिस्टेंट केवल EmpTracker / FieldForce के कार्यों (दुकानों की सूची, उपस्थिति, रूट, लीव, लाइव टेलीमेट्री) से संबंधित प्रश्नों का उत्तर देता है और आउट-ऑफ-स्कोप सवालों को विनम्रतापूर्वक अस्वीकार करता है।

---

### 🗺️ 2. Live 3D Tracking & Map Intelligence Engine
- **Dual Map Engine Support**: OpenStreetMap (Free / OSRM) और Google Maps 3D दोनों के बीच सिंगल-टैप स्विचिंग।
- **Live GPS Telemetry**: कर्मचारियों की रीयल-टाइम लोकेशन, बैटरी प्रतिशत, जीपीएस एक्यूरेसी और स्पीड की लाइव मॉनिटरिंग।
- **OSRM Intelligent Route Optimization**: कर्मचारियों के लिए दिनभर की दुकानों का सबसे छोटा और बेहतरीन रूट (Smart Route Ordering)।
- **Nominatim Geocoding & Store Locator**: कानपुर और अन्य शहरों के स्टोर्स, होटल्स और लैंडमार्क्स की इंस्टेंट सर्च।

---

### 🏬 3. Shop Management & Geofenced Visit Auditing
- **Geofenced Check-In / Check-Out**: कर्मचारी केवल दुकान की निर्धारित परिधि (50m - 200m) के अंदर होने पर ही विज़िट मार्क कर सकते हैं।
- **Proof of Visit with Watermark Engine**: विज़िट के समय कैमरे से ली गई फ़ोटो पर ऑटोमैटिक टाइमस्टैम्प, कर्मचारी का नाम, जीपीएस कोऑर्डिनेट्स और दुकान का नाम वॉटरमार्क होता है।
- **Overdue & Pending Shop Alerts**: जिन दुकानों पर लंबे समय से कोई नहीं गया, उनकी प्राथमिकता सूची।

---

### 👥 4. Dual Native Mobile Apps (Admin & Employee)
- **Admin Command Center App (`apps/admin_app`)**:
  - लाइव 3D रडार मैप, टीम उपस्थिति, रूट इतिहास और विज़िट ऑडिटिंग।
  - वॉयस कमांड्स: *"Active employees list dikhao"*, *"Live radar shops check karo"*.
- **Employee Field App (`apps/employee_app`)**:
  - दैनिक उपस्थिति (Punch In / Punch Out), असाइन की गई दुकानों की सूची, रूट नेविगेशन और विज़िट सबमिशन।
  - वॉयस कमांड्स: *"Aaj ke pending shops dikhao"*, *"Mera next shop kaunsa hai"*.

---

### 🔒 5. Enterprise Backend & Security
- **Laravel 11 RESTful API (`backend/`)**:
  - JWT / Sanctum टोकन-आधारित सुरक्षित प्रमाणीकरण।
  - Multi-Org Tenant Isolation (अलग-अलग कंपनियों का डेटा सुरक्षित और पृथक)।
  - 2-Step Authorization Guardrails (महत्वपूर्ण डेटाबेस क्रियाओं के लिए एआई कन्फर्मेशन टोकन सत्यापन)।
- **Offline-First Synchronization**: नेटवर्क न होने पर भी लोकल डेटाबेस में काम होता है और इंटरनेट आते ही ऑटो-सिंक हो जाता है।

---

## 🏗️ सिस्टम आर्किटेक्चर (Project Architecture)

```
emptracker/
├── apps/
│   ├── admin_app/          # Flutter Admin Command Center Mobile App
│   └── employee_app/       # Flutter Employee Field Operations Mobile App
├── packages/
│   ├── core/               # Shared constants, network & utilities
│   ├── design_system/      # Premium UI components, AI Assistant modal, User Guide
│   ├── firebase_repository/# Laravel REST API repository implementations
│   ├── location_engine/    # Background GPS tracking & geofencing engine
│   ├── map_engine/         # OSM + Google Maps, OSRM routing & store locator
│   ├── models/             # Shared strongly-typed Dart data models
│   └── services/           # Speech-to-Text, Native TTS, Offline AI Engine
├── backend/                # Laravel 11 PHP Backend API & Local AI Engine
│   ├── app/AI/             # Domain Hardening & Local Model Controllers
│   ├── app/Http/           # REST Controllers (Location, Visit, Attendance, Shop)
│   └── database/           # Migrations & Seeders
└── docs/                   # Full Technical Architecture & Governance Documentation
```

---

## 📱 रिलीज़ एपीके डाउनलोड (Download Release APKs)

| Application | Target Platform | Release Binary |
|---|---|---|
| **Admin Command Center** | Android (API 26+) | [`downloads/emptracker-admin-release.apk`](file:///var/www/html/emptracker/downloads/emptracker-admin-release.apk) |
| **Employee Field App** | Android (API 26+) | [`downloads/emptracker-employee-release.apk`](file:///var/www/html/emptracker/downloads/emptracker-employee-release.apk) |

---

## 🚀 इंस्टॉलेशन और रन करने का तरीका (Setup & Running)

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
# Admin App Build
cd apps/admin_app
flutter pub get
flutter build apk --release

# Employee App Build
cd apps/employee_app
flutter pub get
flutter build apk --release
```

### 3. Run on Connected Android Device
```bash
flutter run -d <device-id>
```

---

## 🧪 टेस्टिंग (Automated Unit & E2E Testing)

```bash
# Run shared AI and Services Test Suite
cd packages/services
flutter test test/ai_services_test.dart
```
✅ **11/11 Passing Tests**: Multilingual Detection, Offline AI Intent Engine, Native Speech & TTS Handlers, Strict Domain Guardrails.

---

## 📄 लाइसेंस (License)
Copyright © 2026 EmpTracker / FieldForce Platform. All rights reserved.
Developed by Pradeep Kashyap (`pk9807`).
