#!/bin/bash
set -e

PUBSPEC="../band_of_mercenaries/pubspec.yaml"
PROJECT_DIR="../band_of_mercenaries"

# pubspec.yaml에서 현재 버전 파싱
CURRENT_VERSION=$(grep "^version:" "$PUBSPEC" | sed 's/version: //')
VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
VERSION_CODE=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

# 빌드 번호 +1
NEXT_CODE=$((VERSION_CODE + 1))
NEXT_VERSION="${VERSION_NAME}+${NEXT_CODE}"

echo "현재 버전: $CURRENT_VERSION"
echo "빌드 버전: $NEXT_VERSION"
echo ""

# pubspec.yaml 버전 업데이트
sed -i '' "s/^version: .*/version: $NEXT_VERSION/" "$PUBSPEC"
echo "pubspec.yaml 업데이트 완료"

# 플랫폼 선택
TARGET=${1:-"all"}  # 인자 없으면 둘 다 빌드

cd "$PROJECT_DIR"

# Android AAB
if [[ "$TARGET" == "android" || "$TARGET" == "all" ]]; then
    echo ""
    echo "=== Android AAB 빌드 중... ==="
    flutter build appbundle --release --build-number="$NEXT_CODE"
    AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
    echo "Android 완료: $AAB_PATH"
fi

# iOS IPA
if [[ "$TARGET" == "ios" || "$TARGET" == "all" ]]; then
    echo ""
    echo "=== iOS 빌드 중... ==="
    flutter build ipa --release --build-number="$NEXT_CODE"
    IPA_PATH=$(find build/ios/ipa -name "*.ipa" 2>/dev/null | head -1)
    echo "iOS 완료: $IPA_PATH"
fi

echo ""
echo "빌드 완료: v$NEXT_VERSION"
