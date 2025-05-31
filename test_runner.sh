#!/bin/bash

echo "🧪 ChunkUp 테스트 실행기"
echo "================================"

# Mock 파일 생성
echo "📝 Mock 파일 생성 중..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# 전체 테스트 실행
echo "🚀 전체 테스트 실행 중..."
flutter test

# 커버리지 리포트 생성 (선택사항)
echo "📊 커버리지 리포트 생성 중..."
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

echo "✅ 테스트 완료!"
echo "📈 커버리지 리포트: coverage/html/index.html"