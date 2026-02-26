# Kiro Agent Prompt — Glassmorphism UI Redesign for Nourisha POS

Paste this entire prompt into Kiro. It rewrites `razorpay_pos_screen.dart` with a world-class glassmorphism UI and cinematic loader — zero logic changes, pure visual upgrade.

---

## Goal

Redesign `lib/features/payment/screens/razorpay_pos_screen.dart` with a stunning **glassmorphism (frosted glass)** aesthetic. Keep all existing payment logic, controllers, and service calls exactly as-is. Only change the visual layer.

---

## Dependencies to add in `pubspec.yaml`

```yaml
dependencies:
  flutter_animate: ^4.5.0   # smooth entrance animations
```

Run `flutter pub get` after adding.

---

## Design Specification

### Color Palette & Background
- Full-screen **animated gradient background** using `AnimationController` + `AnimatedBuilder`
- Gradient cycles slowly between these three stops:
  - `Color(0xFF0F0C29)` — deep indigo
  - `Color(0xFF302B63)` — royal purple  
  - `Color(0xFF24243E)` — dark navy
- Add **3 large blurred decorative circles** (blobs) floating behind the UI:
  - Top-right: `Color(0xFF6C63FF)` opacity 0.35, radius 140, blur 80
  - Center-left: `Color(0xFF00D4FF)` opacity 0.25, radius 100, blur 60
  - Bottom-center: `Color(0xFFFF6B9D)` opacity 0.2, radius 120, blur 70
- Use `ImageFilter.blur` via `BackdropFilter` for all glass panels

### Glass Card Helper Widget
Create a private `_GlassCard` widget used for all panels:
```dart
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? borderColor;

  // Uses BackdropFilter + ImageFilter.blur(sigmaX: 20, sigmaY: 20)
  // Background: Colors.white.withOpacity(0.08)
  // Border: 1.5px solid Colors.white.withOpacity(0.18)
  // BoxShadow: offset (0,8), blur 32, Colors.black.withOpacity(0.3)
  // BorderRadius: 20 (default)
}
```

---

## Screen Layout (top to bottom)

### AppBar
- `backgroundColor: Colors.transparent`
- `elevation: 0`
- `flexibleSpace` with a `_GlassCard` style blur behind it
- Title: `'Nourisha POS'` in white, fontWeight w600, fontSize 20
- Subtitle row below title: small text `'Powered by Razorpay · AWS Lambda'` in `Colors.white54`, fontSize 11
- Right side: a pulsing green dot `●` with `Colors.greenAccent` when connected, red when not — animated with `flutter_animate` `.animate().fadeIn().then().shimmer()`

### Status Banner (top of body)
A slim `_GlassCard` (padding 12/16) showing connection status:
- Icon: `Icons.cloud_done_rounded` in cyan when connected
- Text: `'AWS Lambda · ap-south-1 · Connected'` in white70, fontSize 13
- Entrance: slide in from top with `flutter_animate` `.animate().slideY(begin: -0.3).fadeIn()`

### Amount Input Card
A `_GlassCard` wrapping a custom amount field:
- Label: `'AMOUNT'` — uppercase, white54, fontSize 11, letterSpacing 2
- Large `TextField` with:
  - `style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: Colors.white)`
  - `prefixText: '₹ '` in `Colors.white54`
  - `keyboardType: TextInputType.number`
  - `decoration: InputDecoration(border: InputBorder.none)` — no border, naked input
  - cursor color: `Colors.cyanAccent`
  - Hint text `'0.00'` in `Colors.white24`
- Below the field: a thin `Colors.white24` divider line
- Entrance animation: `.animate().slideX(begin: -0.2).fadeIn(duration: 400ms)`

### Reference Input Card
A `_GlassCard` (slightly smaller):
- Label: `'ORDER REFERENCE'` uppercase, white54, fontSize 11, letterSpacing 2
- `TextField` style: white, fontSize 16, `InputBorder.none`
- Hint: `'Optional — table no, order ID…'` in white24
- Entrance animation: `.animate().slideX(begin: 0.2).fadeIn(duration: 500ms, delay: 100ms)`

### Pay Now Button
A full-width gradient button (NOT inside a glass card — it should pop):
- Gradient: `LinearGradient([Color(0xFF6C63FF), Color(0xFF00D4FF)])` left to right
- `BorderRadius.circular(16)`
- Height: 60px
- Shadow: `BoxShadow(color: Color(0xFF6C63FF).withOpacity(0.5), blurRadius: 20, offset: Offset(0,8))`
- When idle: show `Icon(Icons.payment_rounded)` + `Text('Pay Now', fontSize: 18, fontWeight: w700)` in white
- When `_isProcessing` for pay: show the **Custom Loader** (see below) inline
- `InkWell` with `splashColor: Colors.white24`
- Entrance: `.animate().slideY(begin: 0.3).fadeIn(delay: 200ms)`

### Check Status Button
A `_GlassCard` full-width button:
- Border: 1.5px `Colors.cyanAccent.withOpacity(0.5)`
- Icon: `Icons.radar_rounded` in cyanAccent
- Text: `'Check Payment Status'` white, fontSize 16
- When processing: spinning `Icons.radar_rounded` using `RotationTransition`
- Entrance: `.animate().slideY(begin: 0.3).fadeIn(delay: 300ms)`

### Response Panel
A `_GlassCard` that expands to fill remaining space:
- Header row: icon + label showing current state:
  - Unknown/idle: `Icons.terminal_rounded` cyan — `'Response'`
  - Processing: `Icons.hourglass_top_rounded` amber — `'Processing…'`
  - Success: `Icons.check_circle_rounded` green — `'Payment Successful'`
  - Failed: `Icons.cancel_rounded` red — `'Payment Failed'`
- The status icon should pulse using `flutter_animate` `.animate(onPlay: (c) => c.repeat()).scale(begin: Offset(0.95,0.95), end: Offset(1.05,1.05), duration: 800ms)`
- Response text: `Colors.white70`, fontSize 13, `fontFamily: 'monospace'`
- Background tint shifts:
  - Success: add a very subtle `Colors.greenAccent.withOpacity(0.05)` overlay
  - Failed: `Colors.redAccent.withOpacity(0.05)` overlay
  - Default: transparent
- Scrollable content inside
- Entrance: `.animate().fadeIn(delay: 400ms)`

---

## Custom Loader (the star of the show)

Create a private `_NourishaLoader` widget used during processing states.

```dart
class _NourishaLoader extends StatefulWidget { ... }
```

### Loader design — "Orbital Rings"
Use a `Stack` of animated elements drawn with `CustomPainter`:

1. **Outer ring** — thin arc (strokeWidth 2), `Color(0xFF6C63FF)`, rotates clockwise, full 360° every 2.5s
2. **Middle ring** — slightly thicker arc (strokeWidth 3), `Color(0xFF00D4FF)`, rotates counter-clockwise every 1.8s, arc span = 240°
3. **Inner ring** — thicker (strokeWidth 4), `Color(0xFFFF6B9D)`, rotates clockwise every 1.2s, arc span = 120°
4. **Center dot** — solid circle, gradient fill `[Color(0xFF6C63FF), Color(0xFF00D4FF)]`, radius 8, pulses scale 0.8↔1.2 every 800ms

Sizes: outer 64px, middle 46px, inner 30px diameter.

Below the rings, show animated step text:
```
'Creating Order…'   →   'Opening Checkout…'   →   'Verifying…'
```
Cycle through these every 1.5s using a `Timer.periodic`. Text style: white70, fontSize 12, letterSpacing 1.

The whole loader should be centered and used:
- **Full screen overlay** during init (replace the old `CircularProgressIndicator` scaffold)
- **Inline inside the Pay Now button** when `_isProcessing`
- In the full-screen case, wrap in a semi-transparent `Colors.black54` overlay with the loader centered in a `_GlassCard`

---

## Init / Loading Screen

Replace the old bare `CircularProgressIndicator` scaffold with:
- Same animated gradient background
- Centered `_GlassCard` (width 240, padding 40) containing:
  - `_NourishaLoader` (full size, 80px)
  - `SizedBox(height: 24)`
  - Text `'Nourisha POS'` white, fontSize 22, fontWeight w700
  - Text `'Connecting to backend…'` white54, fontSize 13
  - Animated dots `...` appended using a `Timer` cycling every 500ms

---

## Snackbar / Error Toast

Replace plain `SnackBar` with a custom styled one:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    content: Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 16)],
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, color: Colors.white),
        SizedBox(width: 12),
        Expanded(child: Text(message, style: TextStyle(color: Colors.white))),
      ]),
    ),
  ),
);
```

---

## Success / Failure Overlay (bonus — wow factor for demo)

After a payment completes (success or failure), show a **full-screen animated overlay** for 2.5 seconds before dismissing:

**Success overlay:**
- Background: radial gradient from `Colors.greenAccent.withOpacity(0.15)` to transparent
- Large animated checkmark drawn with `CustomPainter` — stroke draws itself using `AnimationController` from 0→1 over 600ms
- Text: `'Payment Successful'` white, fontSize 28, fontWeight w800
- SubText: `'₹{amount} via Razorpay'` white70
- Auto-dismisses after 2.5s

**Failure overlay:**
- Same but radial red, animated ✕ icon, text `'Payment Failed'`

Trigger these from `_displayResult()` using `showGeneralDialog` with `barrierDismissible: true`.

---

## Files to modify

| File | Change |
|------|--------|
| `lib/features/payment/screens/razorpay_pos_screen.dart` | Full redesign as described above |
| `pubspec.yaml` | Add `flutter_animate: ^4.5.0` |

**Do NOT change** any logic in `payment_service.dart`, `backend_api_service.dart`, or `payment_models.dart`.

---

## Imports needed at top of screen file

```dart
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/payment_service.dart';
import '../services/backend_api_service.dart';
import '../models/payment_models.dart';
```

---

## Final checklist for Kiro

- [ ] Animated gradient background with blobs on every screen state (init, main, overlay)
- [ ] `_GlassCard` helper widget with BackdropFilter blur
- [ ] `_NourishaLoader` with 3 orbital rings + pulsing center dot + cycling text
- [ ] Amount field: huge white text, no border, glass card wrapper
- [ ] Pay Now: gradient button with glow shadow, inline loader when processing
- [ ] Check Status: glass outlined button with spinning radar icon
- [ ] Response panel: dynamic header icon + subtle color tint per status
- [ ] Success/Failure full-screen animated overlay after payment
- [ ] Custom styled SnackBar for errors
- [ ] All entrance animations via `flutter_animate`
- [ ] Init screen: glass card + `_NourishaLoader` instead of bare spinner
