# RepayIQ

> AI-powered personal loan management — built with Flutter.

---

## Features

| | |
|---|---|
| Loan Tracker | Add, edit and track loans across 6 categories |
| EMI Calculator | Flat rate & reducing balance with PDF export |
| AI Co-Pilot | Gemini-powered loan coach & repayment strategist |
| Debt Dashboard | Portfolio overview with charts & breakdowns |
| RepayIQ Score | On-device financial health score |
| Budget Analyser | EMI stress detection & new loan simulator |
| EMI Calendar | Monthly due dates with payment tracking |
| Family Manager | Multi-member profiles & consolidated debt view |
| Document Vault | Loan document storage |
| Notifications | EMI reminders & payment confirmations |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter / Dart |
| State | Riverpod |
| Navigation | GoRouter |
| Backend | Firebase Auth + Firestore |
| Local Cache | SQLite |
| AI | Google Gemini 2.5 Flash |
| Charts | fl_chart |

---

## Getting Started

```bash
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

Get a Gemini API key at [aistudio.google.com](https://aistudio.google.com).

---

## Environment

API keys are injected via `--dart-define` at build time and stored in `.vscode/launch.json` which is gitignored. See `.env.example` for required variables.

---

## Architecture

Clean architecture with `data / domain / presentation` layers per feature.

```
lib/
├── core/          # Theme, routing, services, utilities
├── features/      # auth, loans, dashboard, ai, payments ...
└── shared/        # Reusable widgets
```
