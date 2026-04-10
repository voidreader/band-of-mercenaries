# Flutter 빌드 & 실행 명령어

모든 명령어는 `band_of_mercenaries/` 디렉토리에서 실행.

```bash
cd band_of_mercenaries
```

---

## 개발 실행

### Chrome (Web)
```bash
flutter run -d chrome
```

### macOS
```bash
flutter run -d macos
```

### 연결된 Android 기기
```bash
flutter run -d android
```

### 연결된 iOS 기기
```bash
flutter run -d ios
```

---

## 디버그 빌드

### Android APK (Debug)
```bash
flutter build apk --debug
# 출력: build/app/outputs/flutter-apk/app-debug.apk
```

---

## 릴리즈 빌드

### Android APK
```bash
flutter build apk --release
# 출력: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Google Play 배포용)
```bash
flutter build appbundle --release
# 출력: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ios --release
# Xcode에서 Archive 후 App Store Connect 업로드
```

### macOS
```bash
flutter build macos --release
# 출력: build/macos/Build/Products/Release/
```

### Web
```bash
flutter build web --release
# 출력: build/web/
```

---

## 기기 목록 확인

```bash
flutter devices
```

## 에뮬레이터 목록 확인

```bash
flutter emulators
```

## 에뮬레이터 실행

```bash
flutter emulators --launch <emulator_id>
```
