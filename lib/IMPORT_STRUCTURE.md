# 프로젝트 임포트 구조 가이드

이 가이드는 `chunk_up` 프로젝트의 임포트 패턴을 설명합니다.

## 패키지 임포트 패턴

모든 임포트는 상대 경로 대신 패키지 임포트를 사용해야 합니다:

```dart
// 사용하지 말 것 - 상대 경로 임포트
import '../models/word.dart';

// 사용할 것 - 패키지 임포트
import 'package:chunk_up/domain/models/word.dart';
```

## 임포트 계층 구조

클린 아키텍처 원칙에 따라 다음과 같은 임포트 규칙을 따릅니다:

1. **Core 레이어** - 다른 레이어에 의존하지 않아야 함
   ```dart
   import 'package:flutter/material.dart';
   import 'dart:async';
   import 'package:chunk_up/core/constants/app_constants.dart';
   ```

2. **Domain 레이어** - Core에만 의존 가능
   ```dart
   import 'package:chunk_up/core/utils/helpers.dart';
   import 'package:chunk_up/domain/models/word.dart';
   ```

3. **Data 레이어** - Core와 Domain 레이어에 의존 가능
   ```dart
   import 'package:chunk_up/core/services/logging_service.dart';
   import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
   ```

4. **Presentation 레이어** - 모든 레이어에 의존 가능
   ```dart
   import 'package:chunk_up/core/constants/app_constants.dart';
   import 'package:chunk_up/domain/models/word_list_info.dart';
   import 'package:chunk_up/data/repositories/word_list_repository.dart';
   ```

## 인터페이스 위치

- 모든 인터페이스는 `domain/repositories/` 디렉토리에 위치해야 함
- 예: `word_list_repository_interface.dart`
- 구현체는 `data/repositories/` 디렉토리에 위치해야 함
- 예: `word_list_repository.dart`

## 의존성 주입

항상 인터페이스에 의존하고, 의존성 주입 컨테이너(GetIt)를 통해 인스턴스를 가져옵니다:

```dart
// 직접 인스턴스화하지 말 것
final repository = WordListRepository();

// 대신 의존성 주입 사용
final repository = getIt<WordListRepositoryInterface>();
```

## 임포트 정렬 규칙

임포트를 다음 순서로 정렬하는 것을 권장합니다:

1. Dart 패키지 (dart:)
2. Flutter 패키지 (package:flutter/)
3. 외부 패키지 (package:http/ 등)
4. 프로젝트 패키지 (package:chunk_up/)
   - Core
   - Domain
   - Data
   - Presentation

## 임포트 오류 해결

임포트 오류가 발생할 경우:

1. 해당 파일의 모든 상대 경로 임포트를 패키지 임포트로 변환
2. 클래스가 올바른 디렉토리에 위치하는지 확인
3. 인터페이스 구현 클래스가 올바른 인터페이스를 구현하는지 확인
4. 의존성 주입 설정이 올바르게 되어 있는지 확인

이 가이드를 따라 일관성 있고 유지보수하기 쉬운 코드베이스를 유지하세요.