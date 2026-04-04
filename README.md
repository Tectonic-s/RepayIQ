# RepayIQ

An AI-powered personal loan management app built with Flutter.

## Features

- **Loan Tracker** — Add, edit, delete loans across 6 categories with animated progress bars
- **EMI Calculator** — Flat rate vs reducing balance, 6 loan types, moratorium support
- **Debt Dashboard** — Pie charts, category breakdown, total outstanding
- **Reports & PDF Export** — Monthly interest bar chart, exportable PDF statements
- **RepayIQ Score** — On-device financial health score across 4 weighted factors
- **Budget Analyser** — Income vs EMI stress detection, new loan impact simulator
- **EMI Calendar** — Monthly view of all due dates with paid/unpaid tick marks
- **Family Manager** — Multi-member profiles, consolidated family debt view
- **Document Vault** — Upload and store loan documents (base64 in Firestore)
- **Payment Tracking** — Mark dues paid/missed, past payment history onboarding
- **AI Co-Pilot** — Gemini-powered loan coach, comparison assistant, repayment strategist
- **Loan Statement Import** — PDF import with Gemini AI extraction
- **Notifications** — Monthly EMI reminders + payment confirmation deep links
- **Dark Mode** — Full theme support persisted to SharedPreferences

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.11+ / Dart |
| State Management | Riverpod |
| Navigation | GoRouter |
| Backend | Firebase Auth + Firestore |
| Local Cache | SQLite (sqflite) |
| AI | Google Gemini 1.5 Flash |
| Charts | fl_chart |
| Notifications | flutter_local_notifications |
| PDF | pdf + printing |

## Running the App

```bash
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

## Project Structure

```
lib/
├── core/
│   ├── constants/      # AppColors, AppConstants
│   ├── providers/      # ThemeNotifier, ProfilePhotoProvider
│   ├── router/         # GoRouter config
│   ├── services/       # Notifications, AI, Statement Import
│   ├── theme/          # AppTheme (light + dark)
│   └── utils/          # EmiCalculator, Formatters, ScoreCalculator
├── features/
│   ├── auth/           # Login, Register, Splash
│   ├── loans/          # Tracker, Amortisation, Prepayment
│   ├── dashboard/      # Debt Dashboard
│   ├── emi_calculator/ # EMI Calculator
│   ├── reports/        # Reports + PDF Export
│   ├── score/          # RepayIQ Score
│   ├── budget/         # Budget Analyser
│   ├── calendar/       # EMI Calendar
│   ├── family/         # Family Manager
│   ├── documents/      # Document Vault
│   ├── payments/       # Payment Tracking
│   ├── ai/             # AI Co-Pilot
│   ├── tools/          # Tools Hub screen
│   └── settings/       # Profile, Dark Mode
└── shared/
    └── widgets/        # AppTextField, PrimaryButton, MainShell
```

## Firestore Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /loans/{loanId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /payments/{paymentId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /documents/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /family_members/{memberId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Environment

The Gemini API key is passed via `--dart-define` and stored in `.vscode/launch.json` (gitignored). Never commit the key.
