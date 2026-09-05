#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
TARGET="${1:-android-debug}"
case "$TARGET" in check|android-debug|android-release|appbundle|ios-simulator|ios-unsigned|ios-archive) ;; *) echo 'Unknown target.' >&2; exit 2 ;; esac
command -v flutter >/dev/null || { echo 'Install Flutter 3.44.9 and add it to PATH.' >&2; exit 1; }
flutter --version
flutter pub get
flutter analyze
flutter test
case "$TARGET" in
  check) ;;
  android-debug) flutter build apk --debug ;;
  android-release|appbundle)
    test -f android/key.properties || { echo 'Configure android/key.properties with your private release key first.' >&2; exit 1; }
    if [ "$TARGET" = appbundle ]; then flutter build appbundle --release; else flutter build apk --release; fi ;;
  ios-simulator) flutter build ios --simulator --debug --no-codesign ;;
  ios-unsigned) flutter build ios --release --no-codesign ;;
  ios-archive) flutter build ipa --release ;;
esac
