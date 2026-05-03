#!/bin/bash
# Fix OCR Service - Clean rebuild

echo "🧹 Cleaning Flutter build..."
flutter clean

echo "📦 Getting Flutter packages..."
flutter pub get

echo "🍎 Cleaning iOS Pods..."
cd ios
rm -rf Pods Podfile.lock .symlinks
pod deintegrate
pod cache clean --all

echo "📥 Installing iOS Pods..."
pod install --repo-update

cd ..

echo "✅ OCR fix complete! Now run:"
echo "flutter run --dart-define=GEMINI_API_KEY=\$(grep GEMINI_API_KEY .env | cut -d '=' -f2)"
