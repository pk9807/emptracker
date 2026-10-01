# UI DESIGN SYSTEM & DESIGN LANGUAGE SPECIFICATION

## 1. Design Principles (Modern 3D SaaS Glassmorphism)
- **Visual Depth:** Multi-layered elevation, soft shadows (`box-shadow: 0 10px 30px rgba(0,0,0,0.08)`), glassmorphic translucent panels with `BackdropFilter` gaussian blur.
- **Color Tokens:**
  - **Primary Brand:** Electric Indigo / Sapphire Blue (`0xFF2563EB`, `0xFF1D4ED8`)
  - **Accent Vibrant:** Emerald Green (`0xFF10B981` - Live/Active Status)
  - **Warning / Stale:** Amber Orange (`0xFFF59E0B` - Recent / 5m+ Delay)
  - **Danger / Alert:** Coral Rose (`0xFFEF4444` - Offline / Anomaly / Geofence Breach)
  - **Dark Theme Backgrounds:** `0xFF0F172A` (Slate 900), `0xFF1E293B` (Slate 800)
  - **Light Theme Backgrounds:** `0xFFF8FAFC` (Slate 50), `0xFFFFFFFF` (White)
  - **Text High-Contrast:** `0xFF0F172A` (Light) / `0xFFF8FAFC` (Dark)

## 2. Typography Hierarchy (Google Fonts: Outfit & Inter)
- **Display 1 (Dashboard Metrics):** 32px Bold, letterSpacing: -0.5
- **Heading 1 (Screen Titles):** 24px SemiBold
- **Heading 2 (Card Headers):** 18px SemiBold
- **Body Large:** 15px Regular / Medium
- **Body Small (Metadata / GPS):** 12px Regular (Monospace for Lat/Lng)
- **Badge / Tag:** 11px Bold Uppercase

## 3. Custom Map Controls & 3D Cards
- Floating frosted search & filter pill with live count indicator badge.
- Floating bottom sheet featuring horizontal employee quick-cards with pulsating live radar dot.
- Tap marker -> Camera animates with 45-degree tilt & 30-degree bearing, revealing 3D floating profile card with distance, battery icon, and direct action buttons ("Call", "Route History", "View Visits").
