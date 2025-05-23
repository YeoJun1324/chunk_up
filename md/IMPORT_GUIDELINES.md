# Import 가이드라인

## Import 규칙

프로젝트 코드의 일관성과 계층 분리를 유지하기 위해 다음과 같은 import 규칙을 따라주세요.

### 1. 계층별 Import 규칙

#### 도메인 계층 (Domain Layer)
- 도메인 계층은 다른 도메인 계층 코드만 import할 수 있습니다.
- 데이터 계층이나 프레젠테이션 계층의 코드를 import해서는 안 됩니다.
- 코어 유틸리티나 상수는 import 가능합니다.

```dart
// 올바른 예시
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/core/constants/app_constants.dart';

// 잘못된 예시
import 'package:chunk_up/data/repositories/word_repository_impl.dart'; // 도메인에서 데이터 계층 import 금지
import 'package:chunk_up/presentation/providers/word_provider.dart'; // 도메인에서 프레젠테이션 계층 import 금지
```

#### 데이터 계층 (Data Layer)
- 데이터 계층은 도메인 계층과 다른 데이터 계층 코드를 import할 수 있습니다.
- 프레젠테이션 계층 코드를 import해서는 안 됩니다.
- 코어 유틸리티나 상수는 import 가능합니다.

```dart
// 올바른 예시
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/data/datasources/local/word_local_datasource.dart';
import 'package:chunk_up/core/utils/exceptions.dart';

// 잘못된 예시
import 'package:chunk_up/presentation/screens/word_list_screen.dart'; // 데이터 계층에서 프레젠테이션 계층 import 금지
```

#### 프레젠테이션 계층 (Presentation Layer)
- 프레젠테이션 계층은 도메인 계층, 데이터 계층, 그리고 다른 프레젠테이션 계층 코드를 import할 수 있습니다.
- 코어 유틸리티나 상수는 import 가능합니다.

```dart
// 올바른 예시
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/data/repositories/word_repository_impl.dart';
import 'package:chunk_up/presentation/widgets/word_item_widget.dart';
import 'package:chunk_up/core/theme/app_theme.dart';
```

#### 코어 계층 (Core Layer)
- 코어 계층은 도메인 계층의 코드를 import할 수 있지만, 의존성을 최소화하는 것이 좋습니다.
- 데이터 계층이나 프레젠테이션 계층의 코드를 import해서는 안 됩니다.
- 다른 코어 계층 코드는 import 가능합니다.

```dart
// 올바른 예시
import 'package:chunk_up/domain/models/word.dart'; // 필요한 경우만
import 'package:chunk_up/core/utils/logger.dart';

// 잘못된 예시
import 'package:chunk_up/data/repositories/word_repository_impl.dart'; // 코어에서 데이터 계층 import 금지
import 'package:chunk_up/presentation/providers/word_provider.dart'; // 코어에서 프레젠테이션 계층 import 금지
```

### 2. Import 순서 규칙

가독성을 위해 다음 순서로 import를 작성해주세요:

1. Dart 기본 라이브러리 (`dart:`)
2. Flutter 라이브러리 (`package:flutter/`)
3. 외부 패키지 라이브러리 (`package:...`)
4. 앱 내부 import (`package:chunk_up/...`)

```dart
// 올바른 import 순서 예시
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/core/constants/app_constants.dart';
```

### 3. 상대 경로 vs 절대 경로

앱 내부 코드를 import할 때는 항상 절대 경로(`package:chunk_up/...`)를 사용해주세요.
상대 경로(`../`, `./`)는 사용하지 않습니다.

```dart
// 올바른 예시
import 'package:chunk_up/domain/models/word.dart';

// 잘못된 예시
import '../../../domain/models/word.dart';
```

## 자주 발생하는 Import 문제와 해결 방법

### 1. 순환 의존성 문제

순환 의존성은 두 클래스가 서로를 직접 또는 간접적으로 참조할 때 발생합니다.

#### 문제 예시:
```dart
// word_repository.dart
import 'package:chunk_up/domain/usecases/get_word_usecase.dart';

// get_word_usecase.dart
import 'package:chunk_up/domain/repositories/word_repository.dart';
```

#### 해결 방법:
- 인터페이스(추상 클래스)를 사용하여 의존성 방향을 한 쪽으로만 유지
- 공통 모델이나 인터페이스를 추출하여 두 클래스 모두 그것에 의존하도록 변경

### 2. 계층 분리 위반 문제

계층 분리 원칙을 위반하는 import는 코드의 유지보수성과 테스트 용이성을 저하시킵니다.

#### 문제 예시:
```dart
// domain/models/word.dart
import 'package:chunk_up/data/datasources/local/word_local_datasource.dart';
```

#### 해결 방법:
- 위 계층별 Import 규칙을 엄격히 따르기
- 의존성 역전 원칙(Dependency Inversion Principle)을 적용하여 인터페이스를 통한 의존성 관리

### 3. 미사용 Import 문제

사용하지 않는 import는 컴파일 시간을 늘리고 코드를 복잡하게 만듭니다.

#### 해결 방법:
- 정기적으로 `flutter analyze` 명령을 실행하여 미사용 import 확인
- VSCode나 Android Studio의 "Organize Imports" 기능 사용

## 결론

적절한 import 관리는 클린 아키텍처의 핵심 원칙 중 하나입니다. 이 가이드라인을 따르면 코드의 계층 분리가 잘 유지되고, 의존성 문제를 최소화할 수 있습니다. 코드 리뷰 시에도 이러한 import 규칙을 확인하여 프로젝트의 구조적 일관성을 유지해주세요.