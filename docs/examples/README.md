# ChunkUp 예제 및 데모 파일들

이 폴더에는 개발 과정에서 만들어진 예제 파일들이 있습니다.

## 파일 설명

### `exam_export_screen_example.dart`
- PDF 내보내기 화면의 초기 구현 예제
- 실제 구현: `lib/presentation/screens/premium_exam_export_screen.dart`

### `exam_pdf_implementation_example.dart`
- PDF 생성 로직의 초기 구현 예제
- 실제 구현: `lib/core/services/pdf/` 디렉토리

### `performance_demo.dart`
- 문장 매핑 서비스의 성능 테스트 데모
- 성능 최적화 검증용

## 주의사항

이 파일들은 **참고용**으로만 사용하세요:
- 프로덕션 빌드에 포함되지 않음
- 실제 구현과 다를 수 있음
- 개발 과정의 기록 목적

## 실제 구현 위치

- **PDF 서비스**: `lib/core/services/pdf/`
- **화면**: `lib/presentation/screens/`
- **테스트**: `test/` 디렉토리