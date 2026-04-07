# RepayIQ — AI-Powered Personal Loan Management System

> A cross-platform mobile application built with Flutter that consolidates all your loan repayments into one intelligent, privacy-first platform.

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [AI Financial Co-pilot](#ai-financial-co-pilot)
- [Privacy Architecture](#privacy-architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Environment Setup](#environment-setup)
- [Database Schema](#database-schema)
- [Screenshots](#screenshots)
- [Academic Context](#academic-context)
- [Roadmap](#roadmap)

---

## Overview

RepayIQ addresses a widely experienced but underserved problem — the absence of a single, dedicated tool for tracking multiple active EMIs, computing accurate loan costs, and receiving timely payment reminders.

Existing banking apps bury EMI data within transaction histories. Generic finance trackers lack loan-specific intelligence. Manual spreadsheets provide no alerts or analysis. RepayIQ solves this through a unified, intelligent platform that works fully offline and puts user privacy first.

---

## Key Features

### Core Modules

| Module | Description |
|--------|-------------|
| **EMI Calculator** | Flat Rate and Reducing Balance methods with side-by-side cost comparison |
| **Active Loan Tracker** | Track Home, Vehicle, Personal, Appliance, and Credit Card EMIs with progress bars and amortisation schedules |
| **Prepayment Simulator** | Calculate months saved and interest saved from any lump sum prepayment |
| **Due Date Reminders** | Configurable local push notifications at 1, 3, or 7 days before each EMI due date |
| **Debt Dashboard** | Bubble charts, pie charts, total monthly outflow, and total outstanding debt |
| **RepayIQ Score** | On-device credit health indicator with four weighted factors — no external API required |
| **Loan Document Vault** | Photograph and store loan agreements securely, linked per loan record |
| **Family Loan Manager** | Manage loan profiles for multiple family members under one account |
| **Budget Impact Analyser** | See your disposable income after all EMIs and get financial stress warnings |
| **EMI Calendar View** | Monthly calendar with all due dates colour-coded by loan category |

### RepayIQ Score

An on-device credit health indicator calculated entirely from the user's own repayment data:

| Factor | Weight |
|--------|--------|
| Payment History | 40% |
| Debt-to-Income Ratio | 30% |
| Loan Utilisation | 20% |
| Active Loan Count | 10% |

Score bands: **Excellent** (80–100) · **Good** (60–79) · **Fair** (40–59) · **Poor** (0–39)

---

## AI Financial Co-pilot

Powered by the **Gemini API** with three distinct advisory features:

### 1. Conversational Loan Coach
A persistent chat interface where users ask dynamic what-if questions. The user's full loan portfolio is injected as anonymised context on every request. Conversation history is maintained within a session. Four one-tap question chips allow instant advice without typing.

```
"Can I afford a new loan?"
"What is my debt-free date?"
"Which loan should I clear first?"
"How much interest will I pay in total?"
```

### 2. Loan Comparison Assistant
Enter two competing loan offers. The AI evaluates total cost of borrowing, EMI difference, interest burden, and risk — then returns a clear recommendation with reasoning.

### 3. Smart Repayment Strategist
Analyses all active loans and generates a personalised payoff plan using either:
- **Avalanche Method** — highest interest rate first (minimises total interest paid)
- **Snowball Method** — smallest balance first (maximises psychological momentum)

Returns a month-by-month payoff roadmap with a clear method recommendation.

---

## Privacy Architecture

RepayIQ is built with a privacy-first approach that was specifically designed to address data security concerns around AI-assisted financial advice.

```
Loan Document (photo)
        │
        ▼
Google ML Kit OCR          ← On-device, zero network call
        │
        ▼
Raw extracted text         ← Never stored, never transmitted
        │
        ▼
DocumentParser (regex)     ← Extracts 5 numerical fields only
        │
        ▼
{ principal, rate, tenure, emi, dueDay }
        │
        ▼
Add Loan Form              ← User reviews and confirms
        │
        ▼
sqflite + Firestore        ← Only these 5 numbers saved
```

```
AI Query
        │
        ▼
DataAnonymiser             ← Strips all PII before API call
        │
        ▼
{ numerical loan params }  ← No names, banks, or account numbers
        │
        ▼
Gemini API (HTTPS)         ← AI never sees raw personal data
```

**Key privacy guarantees:**
- All personal and financial data stored locally via `sqflite` within the app's sandboxed storage
- Firebase Firestore data is strictly UID-scoped — no cross-user data access possible
- Loan documents processed by Google ML Kit are never transmitted to any server
- Raw OCR text is discarded immediately after regex parsing
- A one-time consent screen clearly informs users exactly what anonymised data is sent to Gemini API
- The Gemini API key is never hardcoded — stored via Flutter `--dart-define`

---

## Tech Stack

```
Frontend        Flutter (Dart)
State           Riverpod
Local DB        sqflite
Cloud DB        Firebase Firestore
Auth            Firebase Authentication (Email + Google Sign-In)
Storage         Firebase Storage
AI              Gemini API
OCR             Google ML Kit Text Recognition (on-device)
Charts          fl_chart
Notifications   flutter_local_notifications
Documents       image_picker
PDF             pdf
```

### Platform Support

| Platform | Minimum Version |
|----------|----------------|
| Android  | 8.0 (API Level 26) |
| iOS      | 13.0 |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── router/
│   └── theme/
├── features/
│   ├── auth/
│   │   ├── presentation/
│   │   ├── providers/
│   │   └── services/
│   ├── calculator/
│   ├── loans/
│   ├── dashboard/
│   ├── document_scan/
│   │   ├── presentation/
│   │   ├── providers/
│   │   └── services/
│   │       └── ocr_service.dart
│   ├── document_vault/
│   ├── family/
│   ├── ai_copilot/
│   │   ├── presentation/
│   │   ├── providers/
│   │   └── services/
│   │       ├── gemini_prompt_builder.dart
│   │       └── data_anonymiser.dart
│   ├── repayiq_score/
│   ├── budget/
│   └── calendar/
└── shared/
    ├── widgets/
    └── utils/
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio or Xcode
- A Firebase project
- A Gemini API key from [Google AI Studio](https://aistudio.google.com)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/repayiq.git
cd repayiq

# Install dependencies
flutter pub get

# Run the app
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

---

## Environment Setup

### Firebase Configuration

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (Email/Password + Google Sign-In)
3. Enable **Firestore** in production mode
4. Enable **Storage**
5. Download and place configuration files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

### Firebase Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Firestore Data Structure

```
users/
└── {uid}/
    ├── loans/
    │   └── {loanId}       — loan details, category, tenure, EMI
    ├── payments/
    │   └── {paymentId}    — payment history per loan
    ├── family_members/
    │   └── {memberId}     — family member profiles
    ├── documents/
    │   └── {documentId}   — Firebase Storage URLs per loan
    └── ai_conversations/
        └── {convId}       — AI Co-pilot session history
```

---

## Database Schema

### Local (sqflite)

```sql
-- loans table
CREATE TABLE loans (
  loan_id       INTEGER PRIMARY KEY AUTOINCREMENT,
  loan_name     TEXT    NOT NULL,
  loan_type     TEXT    NOT NULL,  -- Home | Vehicle | Personal | Appliance | CreditCard
  principal     REAL    NOT NULL,
  interest_rate REAL    NOT NULL,
  tenure_months INTEGER NOT NULL,
  start_date    TEXT    NOT NULL,
  due_day       INTEGER NOT NULL,
  reminder_days INTEGER DEFAULT 3,
  monthly_emi   REAL    NOT NULL,
  calc_method   TEXT    NOT NULL,  -- Flat | Reducing
  member_id     INTEGER,
  status        TEXT    DEFAULT 'Active',  -- Active | Closed
  created_at    TEXT    NOT NULL
);

-- payments table
CREATE TABLE payments (
  payment_id   INTEGER PRIMARY KEY AUTOINCREMENT,
  loan_id      INTEGER NOT NULL REFERENCES loans(loan_id),
  payment_date TEXT    NOT NULL,
  amount_paid  REAL    NOT NULL,
  month_number INTEGER NOT NULL,
  status       TEXT    NOT NULL   -- Paid | Overdue | Upcoming
);

-- family_members table
CREATE TABLE family_members (
  member_id      INTEGER PRIMARY KEY AUTOINCREMENT,
  member_name    TEXT NOT NULL,
  relationship   TEXT NOT NULL,
  monthly_income REAL,
  created_at     TEXT NOT NULL
);
```

---

## Screenshots

> *(Add screenshots here once the app is built)*

| Home Dashboard | EMI Calculator | AI Loan Coach |
|:-:|:-:|:-:|
| ![Home](screenshots/home.png) | ![Calculator](screenshots/calculator.png) | ![AI](screenshots/ai_coach.png) |

| Debt Dashboard | RepayIQ Score | Document Vault |
|:-:|:-:|:-:|
| ![Dashboard](screenshots/dashboard.png) | ![Score](screenshots/score.png) | ![Vault](screenshots/vault.png) |

---

## Academic Context

| Field | Details |
|-------|---------|
| **Institution** | PSG College of Technology, Coimbatore — 641 004 |
| **Department** | Department of Computer Applications |
| **Course** | 23MX27 — Mobile Application Development |
| **Programme** | MCA First Year, Semester 2 — AY 2025–2026 |
| **Student** | Tharun.S · Roll No. 25MX363 |
| **Faculty Guide** | Ms. Aruna |

---

## Roadmap

- [x] Project design and approval
- [x] UI/UX design in Figma
- [x] Database schema design
- [ ] Authentication screens (Firebase Auth)
- [ ] EMI Calculator module
- [ ] Active Loan Tracker module
- [ ] Debt Dashboard and RepayIQ Score
- [ ] Due Date Reminders
- [ ] Loan Document Vault
- [ ] Family Loan Manager
- [ ] Google ML Kit OCR integration
- [ ] AI Co-pilot (Gemini API)
- [ ] Budget Impact Analyser
- [ ] EMI Calendar View
- [ ] PDF Export
- [ ] Testing and bug fixes
- [ ] Final documentation and submission

---

<div align="center">

Built with Flutter · Powered by Gemini API · Privacy-first by design

**PSG College of Technology · 23MX27 Mobile Application Development**

</div>