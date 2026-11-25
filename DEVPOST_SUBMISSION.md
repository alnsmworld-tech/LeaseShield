# LeaseShield — Devpost Submission Kit (#BuildHybridAI 2026)

Copy and paste the sections below directly into your Devpost submission form.

---

## Tagline (Short Description)
**Privacy-first rental agreement analyzer powered by Firebase AI Logic Hybrid Inference — redact PII & flag predatory clauses 100% on-device, then escalate only redacted clauses to Cloud Gemini.**

---

## Project Story (Devpost Markdown)

### Inspiration
Every year, millions of students, renters, and small business owners sign rental agreements packed with predatory terms—non-refundable deposits, unannounced landlord entry, punitive lock-in penalties, and 90-day auto-renewal traps. Yet uploading a lease to a standard cloud AI tool means handing over highly sensitive personal data: full legal names, SSNs/Aadhaar/PAN numbers, bank account details, phone numbers, and residential addresses.

We built **LeaseShield** because lease analysis is a textbook case where **hybrid AI is not a gimmick—it is an architectural necessity**: sensitive PII redaction and initial clause triage *must* happen locally on-device, while heavy-reasoning regional negotiation drafting belongs in the cloud using *only* anonymized excerpts.

### What it does
1. **Offline-First Lease Capture:** Scans any physical lease page using on-device **Google ML Kit OCR** (camera or photo library), uploads **PDF / TXT** lease files parsed 100% locally (Apache PDFBox on Android, built-in `PDFKit` on iOS), accepts pasted text, or lets judges test immediately in Airplane Mode using **3 built-in sample leases** pre-loaded with realistic fake US and Indian PII.
2. **100% On-Device PII Redaction & Red-Flag Triage:** Uses **Firebase AI Logic Hybrid Inference** (`ONLY_ON_DEVICE` / `PREFER_ON_DEVICE`) targeting **Gemini Nano 4** on Android and **Apple Foundation Models** on iOS to redact all PII (`[REDACTED_NAME]`, `[REDACTED_ID]`, `[REDACTED_BANK]`, `[REDACTED_PHONE]`, `[REDACTED_EMAIL]`, `[REDACTED_ADDRESS]`) and return structured JSON red-flag cards with risk scores and suggested revisions.
3. **Glass Box Live Hybrid Telemetry:** Every AI screen displays a real-time pill showing exact execution provenance and latency—`ON-DEVICE • Gemini Nano 4 • 340ms` in emerald green or `IN-CLOUD • gemini-2.5-flash • 1,120ms` in indigo—plus an amber transparency banner whenever a privacy-preserving fallback runs on unsupported hardware.
4. **Glass Box Outbound Payload Inspector & Cloud Escalation:** When the user taps **Draft Counter-Offer**, they can tap **Inspect Payload** *before* calling the cloud to inspect the exact outbound JSON and verify **ZERO PII** is leaving the device. Only the redacted clause excerpts and city/region are sent to **Cloud Gemini** via Firebase AI Logic to generate a polite, firm counter-offer email grounded in local tenant-protection norms.
5. **Anonymized Cloud History:** Saves *only* redacted lease summaries and negotiation drafts to **Cloud Firestore** under `users/{uid}/leases/{leaseId}`, backed by **Firebase Anonymous Auth**, **Firebase App Check**, and **Firebase Remote Config**.

### How we built it
- **Flutter (Android + iOS):** Feature-First Clean Architecture (`lib/core/`, `lib/features/{onboarding,scanner,analysis,negotiation,history}`) using `flutter_bloc`, `equatable`, `get_it`, and Material 3.
- **Native Firebase AI Logic Bridges:** Typed Flutter `MethodChannel('com.leaseshield/hybrid_ai')` bridging Dart to:
  - **Android (Kotlin):** `HybridAiPlugin.kt` integrating `com.google.firebase:firebase-ai:17.11.0` and `com.google.firebase:firebase-ai-ondevice:16.0.0-beta01` with explicit `InferenceMode` routing and `response.inferenceSource` telemetry.
  - **iOS (Swift):** `HybridAiPlugin.swift` integrating Apple `FoundationModels` for on-device execution and `FirebaseAI` for Cloud Gemini escalation under the exact same channel contract.
- **Defense-in-Depth Privacy Fallback:** `LocalPiiScrubber` (deterministic Dart regex scrubber covering US SSN, Indian Aadhaar/PAN, bank/routing/IFSC, emails, phone numbers, street/flat addresses, and party names) runs locally *before* any `PREFER_ON_DEVICE` cloud fallback and *before* any Firestore write. On offline unsupported devices, `LocalClauseDetector` guarantees zero-crash local triage.
- **Firebase Production Stack:** Firebase App Check (debug provider in debug, Play Integrity / App Attest in release), Firebase Remote Config (`red_flag_prompt_template`, `negotiation_prompt_template`, `default_triage_mode`), Anonymous Auth, and owner-isolated Firestore Security Rules.

### Challenges we ran into
- Bridging the experimental `@PublicPreviewAPI` `firebase-ai-ondevice` Android SDK and iOS `FoundationModels` into a single unified Dart `MethodChannel` contract with accurate latency and `inferenceSource` reporting.
- Designing regex PII redaction that handles both US and international (Indian Aadhaar, PAN, IFSC, `+91`) formats without crossing line boundaries or corrupting legal clause wording.
- Ensuring zero-friction evaluation across every device—including older Android phones without AICore—while staying 100% transparent about where inference executed.

### Accomplishments that we're proud of
- True **Glass Box AI** UX: users don't have to *trust* our privacy claim—they can visually inspect the emerald-highlighted redacted lease, the live `ON-DEVICE` / `IN-CLOUD` telemetry pill, and the exact outbound JSON payload before a single byte touches the cloud.
- Full multi-platform Flutter architecture with real native Android + iOS Firebase AI Logic bridges, deployed Firestore security rules, live Remote Config templates, and 11/11 passing unit and widget tests.

### What's next for LeaseShield
- Multi-page PDF lease scanning and side-by-side clause diffing when a landlord sends back a revised draft.
- Optional Google Sign-In account upgrade to sync anonymized lease history across devices.
- Community-curated regional tenant-rights packs delivered dynamically via Firebase Remote Config.

### Device Requirements & Compatibility
- **Android:** Runs on **Android 8.0+ (API 26+)** with full OCR, on-device PDF/TXT parsing, local PII scrubbing, and Cloud Gemini escalation; native **Gemini Nano 4** on-device inference requires **Android 14+ (API 34+)** with **Android AICore** (e.g., Pixel 8/9/10, Galaxy S24/S25).
- **iOS:** Runs on **iOS 16.0+** with full OCR, `PDFKit` parsing, local PII scrubbing, and Cloud Gemini escalation; native **Apple Foundation Models** requires **iOS 26+** on Apple Intelligence–capable hardware.
- **Graceful Fallback:** On older devices without on-device LLMs, `On-Device Only` runs 100% locally offline, while `Hybrid Auto` scrubs all PII locally *before* escalating to Cloud Gemini with an amber transparency banner.

---

## Judge Testing Instructions (Copy into Devpost)
1. **Install or build:** Install the attached Android APK from GitHub Releases, or clone the repo and run `flutter pub get && flutter run`.
2. **No account required:** LeaseShield signs in automatically via Firebase Anonymous Auth.
3. **Test 1 — Offline / On-Device Privacy (Airplane Mode):**
   - Walk through (or skip) the 3-screen intro.
   - Turn on **Airplane Mode** and tap **Predatory Student Apartment Lease** under *Try an Instant Demo Lease*.
   - Verify the **ON-DEVICE** telemetry pill, the flagged predatory clauses, and tap **Redacted Lease** to see all fake PII (`SSN`, `Bank Account`, `Name`, `Phone`, `Address`) highlighted in green `[REDACTED_*]` pills.
4. **Test 2 — Glass Box Cloud Escalation:**
   - Turn network back on and tap **Draft Counter-Offer**.
   - Tap **Inspect Payload** to verify `ZERO PII VERIFIED` in the exact outbound JSON.
   - Tap **Generate Email** to invoke Cloud Gemini (`IN-CLOUD • gemini-2.5-flash`), then tap **Save Draft to History** to verify anonymized persistence in the **History** tab.

---

## 3-Minute Demo Video Script

| Time | Screen / Action | Voiceover Beat |
| :--- | :--- | :--- |
| **0:00 – 0:25** | Open app on phone → swipe through the **3-slide Intro Walkthrough** | "Renters sign predatory leases every day because uploading a lease with your SSN, bank account, and address to a cloud AI is a privacy nightmare. Meet **LeaseShield**—built with Firebase AI Logic Hybrid Inference." |
| **0:25 – 1:15** | Turn on **Airplane Mode** → tap **Predatory Student Apartment Lease** → show **Lease Report** + **ON-DEVICE pill** → switch to **Redacted Lease** tab | "I'm in Airplane Mode right now. Tap a sample lease loaded with realistic fake PII. In milliseconds, LeaseShield runs **100% on-device**—look at the green telemetry pill—flagging 5 predatory clauses and scrubbing every name, SSN, phone number, bank account, and address locally." |
| **1:15 – 2:10** | Turn off Airplane Mode → tap **Draft Counter-Offer** → tap **Inspect Payload** → scroll JSON showing `ZERO PII VERIFIED` → tap **Generate Email** | "Now I want to negotiate. Before anything leaves my phone, I tap **Inspect Payload**. Judges and users can see the exact JSON leaving the device—zero personal data, only redacted clauses and the city. Now I tap **Generate Email**—the telemetry pill switches to indigo **IN-CLOUD • gemini-2.5-flash**, drafting a firm, polite counter-offer grounded in local tenant norms." |
| **2:10 – 2:45** | Tap **Save Draft to History** → switch to **History** tab → show **App Check** badge & Firestore sync | "We save only the anonymized summary and draft to Cloud Firestore under Anonymous Auth, protected by **Firebase App Check** and **Remote Config** prompt templates." |
| **2:45 – 3:00** | Show architecture diagram / GitHub Apache 2.0 repo | "LeaseShield is open-source under Apache 2.0 with native Kotlin and Swift Firebase AI Logic bridges. Privacy on-device, heavy reasoning in the cloud—that's #BuildHybridAI." |
