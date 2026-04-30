#!/bin/sh

set -e

echo "Setting up Flutter for Xcode Cloud..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$IOS_DIR/.." && pwd)"

FLUTTER_DIR="$HOME/flutter"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed. Downloading Flutter stable..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
  export PATH="$FLUTTER_DIR/bin:$PATH"
else
  echo "Flutter is already installed."
fi

flutter --version
flutter precache --ios

cd "$PROJECT_DIR"
flutter pub get

cd "$IOS_DIR"
pod install

echo "Xcode Cloud setup finished."
