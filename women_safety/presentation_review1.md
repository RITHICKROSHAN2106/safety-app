# Project Review 1 — Presentation Draft

-- Slide 1: Title

- **Project Title:** Women Safety — Mobile Personal Safety App
- **Guide:** [Name] — [Designation], [Dept], [College Name]
- **Student:** [Name], Roll No: [____], [Dept], [College Name]
- **Date:** [Review 1 Date]

-- Slide 2: Agenda (Table of Contents)

- Title & Team
- Agenda
- Abstract
- Introduction
- Existing System
- Proposed System
- Timeline / Milestones
- References
- Future Work
- Queries


-- Slide 3: Abstract

- Brief overview (2–3 sentences): what the project does, who it helps, and the primary outcome.
- Example: "Women Safety is a mobile personal-safety app that lets users send instant SOS alerts with live location, automated calls/SMS/WhatsApp messages, and real-time cloud notifications to trusted contacts and responders. It is built for low-latency alerts and reliable delivery even with intermittent connectivity."


-- Slide 4: Introduction

- Problem statement: rising safety concerns for individuals in public and private spaces; delays in contacting help and sharing precise location.
- Motivation: provide a one-tap, reliable alerting system that reduces response time and improves chances of timely assistance.
- Objectives: enable instant SOS, accurate location sharing, multi-channel alert delivery (call, SMS, WhatsApp, push), and easy configuration of emergency contacts.

-- Slide 5: Existing System

- Describe current/common solutions (manual calls, SMS, basic alert apps).
- Key limitations: slow response, inaccurate location, poor UX, dependency on network, privacy issues.


-- Slide 6: Proposed System

- High-level description: what the `Women Safety` app provides differently — a resilient, multi-channel SOS system with real-time location and cloud-backed notifications so contacts receive alerts reliably.
- Core features:
  - One-tap SOS which triggers automated call and sends SMS/WhatsApp messages (where configured)
  - Real-time GPS location sharing and live tracking link
  - Push notifications via Firebase Cloud Messaging to contacts and admin dashboards
  - Optional audio recording and periodic location pings after SOS
  - Contact management, message templates, and retry/fallback when networks are poor
- Architecture (brief): Mobile app (Flutter) → Firebase services (Authentication, Firestore, Cloud Functions, Cloud Messaging) → External APIs (Google Maps, WhatsApp/SMS gateways) → Notification delivery.

Notes: the repository already includes Firebase setup, Google Maps integration, Lottie animations, and optional SMS/WhatsApp alternatives documented in `FIREBASE_SETUP.md`, `GOOGLE_MAPS_SETUP.md`, and `WHATSAPP_INTEGRATION.md`.


-- Slide 7: Timeline / Roadmap

- Phase 1 (Weeks 1–3): Requirements, design, Firebase setup, basic UI
- Phase 2 (Weeks 4–6): SOS flow, location sharing, contacts integration
- Phase 3 (Weeks 7–9): Notifications, WhatsApp/SMS fallback, device testing
- Phase 4 (Weeks 10–12): Privacy review, accessibility improvements, final testing and deployment
- (Adjust dates/weeks to match your schedule; see `QUICK_START_FIREBASE.md` for setup tasks)


-- Slide 8: References

- List resources used (papers, APIs, libraries, documentation):
  - Firebase documentation — Authentication, Firestore, Cloud Messaging
  - Google Maps / Geolocation API docs
  - `FIREBASE_SETUP.md`, `GOOGLE_MAPS_SETUP.md`, `WHATSAPP_INTEGRATION.md` in the repo
  - Third-party packages used in project (see `pubspec.yaml`), e.g., `lottie`, `audioplayers`, `location` packages


-- Slide 9: Future Work

- Planned enhancements tailored to `Women Safety`:
  - ML-based fall/abnormality detection and automatic SOS triggers
  - Direct integration with local emergency services and police APIs (where permitted)
  - Multi-language support, voice activation, and accessibility features
  - Stronger privacy controls: end-to-end encrypted location sharing, user consent flows

-- Slide 10: Queries

- Invite questions from reviewers.
- Suggested prompts for discussion:
  - Which feature should be prioritized for real-device testing?
  - Any security/privacy concerns to address before deployment?

---

Notes for presenter:

- Keep each slide concise — aim for 4–6 bullets per slide.
- Use screenshots or a quick demo for the Proposed System slide if available.
- Time allocation suggestion: 10–12 minutes total, ~1 minute per slide plus Q&A.

Replace all bracketed placeholders (e.g., [Name], [Review 1 Date]) with your project-specific details.
