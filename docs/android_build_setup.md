# Android 빌드 환경 설정 (macOS)

## 1. Java 설치

```bash
brew install openjdk@17
sudo ln -sfn $(brew --prefix openjdk@17)/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
```

## 2. Android SDK Command-Line Tools 설치

```bash
brew install --cask android-commandlinetools
```

## 3. Flutter에 Android SDK 경로 설정

```bash
flutter config --android-sdk /opt/homebrew/share/android-commandlinetools
```

## 4. SDK 라이선스 수락

```bash
flutter doctor --android-licenses
```

나오는 라이선스마다 `y` 입력.

만약 `Android sdkmanager not found` 오류가 나오면 `sdkmanager`를 직접 실행:

```bash
sdkmanager --licenses
```

## 5. APK 빌드

```bash
cd band_of_mercenaries && flutter build apk --release
```

> debug 빌드(`--debug`)는 140MB+ 로 용량이 매우 크므로, 배포/테스트 용도로는 `--release`를 사용할 것.

결과물 경로: `build/app/outputs/flutter-apk/app-release.apk`
