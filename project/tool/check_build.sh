#!/usr/bin/env bash
# 표준 빌드/린트 체크 절차 (CLAUDE.md "빌드/린트 체크" 섹션과 동일한 순서).
# project/ 디렉터리에서 실행: ./tool/check_build.sh
#
# 순서: pub get(의존성 정합성) -> analyze(린트) -> test(전체 테스트)
#       -> build apk --debug -> 산출물 실제 존재/크기 확인.
# 중간에 하나라도 실패하면 즉시 중단한다(set -e).
set -euo pipefail

cd "$(dirname "$0")/.."

echo "[1/5] flutter pub get"
flutter pub get

echo "[2/5] flutter analyze"
flutter analyze

echo "[3/5] flutter test"
flutter test

echo "[4/5] flutter build apk --debug"
flutter build apk --debug

echo "[5/5] 빌드 산출물 확인"
apk_path="build/app/outputs/flutter-apk/app-debug.apk"
if [ ! -f "$apk_path" ]; then
  echo "실패: $apk_path 가 생성되지 않았습니다." >&2
  exit 1
fi

apk_size=$(stat -f%z "$apk_path" 2>/dev/null || stat -c%s "$apk_path")
min_size=$((1024 * 1024))
if [ "$apk_size" -lt "$min_size" ]; then
  echo "실패: $apk_path 크기가 너무 작습니다 (${apk_size} bytes, 최소 ${min_size} bytes 필요)." >&2
  exit 1
fi

echo "모든 체크 통과 — $apk_path (${apk_size} bytes)"
