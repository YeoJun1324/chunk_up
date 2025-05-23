# 다크 모드 구현 가이드

## 개요

이 문서는 Chunk Up 앱에 구현된 다크 모드 기능의 사용법과 구현 세부 사항을 설명합니다.

## 기능 구성

1. **테마 설정**
   - AppTheme 클래스를 통한 전역 테마 설정 (`lib/core/theme/app_theme.dart`)
   - 다크 모드 기본 배경색: `#2a2a2a` (Color(0xFF2A2A2A))
   - 라이트 모드와 다크 모드 각각에 대한 별도 테마 설정

2. **테마 전환**
   - 앱 상단 우측 모드 전환 아이콘을 통한 다크/라이트 모드 토글
   - 설정 화면의 스위치를 통한 모드 전환
   - 시스템 설정에 따른 자동 모드 지원

3. **상태 관리**
   - `ThemeNotifier` Provider를 통한 테마 상태 관리 (`lib/presentation/providers/theme_notifier.dart`)
   - 앱 재시작 시에도 유지되는 테마 설정 (SharedPreferences 사용)

## 사용 방법

앱에서 다크 모드를 사용하기 위한 방법은 다음과 같습니다:

1. **홈 화면에서 전환**
   - 앱 상단 바에 있는 태양/달 아이콘 버튼을 통해 전환

2. **설정 화면에서 전환**
   - 설정 > 일반 설정 > 다크 모드 스위치를 통해 전환

## 개발자 정보

다크 모드를 앱의 새로운 화면에 적용하고자 할 경우 다음 사항을 참고하세요:

### 다크 모드 감지

현재 테마가 다크 모드인지 확인하려면:

```dart
// 빌드 메서드 내에서:
final isDarkMode = Theme.of(context).brightness == Brightness.dark;

// 또는 ThemeNotifier 활용:
final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
final isDarkMode = themeNotifier.isDarkMode(context);
```

### AppBar 배경색 적용 예시

```dart
appBar: AppBar(
  title: Text('화면 제목'),
  backgroundColor: Theme.of(context).brightness == Brightness.dark 
      ? AppTheme.darkBackground 
      : null,
),
```

### 다크 모드에서 색상 조정 예시

```dart
// 다크 모드에서 색상 투명도 조정 예시
final backgroundColor = isDarkMode 
    ? Colors.blue.shade100.withOpacity(0.2) 
    : Colors.blue.shade100;
```

## 다크 모드에서 주의 사항

1. **대비(Contrast)**: 다크 모드에서 텍스트와 배경의 대비가 충분한지 확인하세요.
2. **색상 조정**: 라이트 모드용 색상은 다크 모드에서 잘 보이지 않을 수 있으니 적절히 조정이 필요합니다.
3. **투명도**: 다크 모드에서는 원색보다 투명도를 조정한 색상을 사용하면 더 자연스러운 UI를 제공할 수 있습니다.
4. **아이콘 색상**: 아이콘 색상이 다크 모드에서 명확히 보이도록 조정하세요.

## 향후 개선 사항

1. **시스템 테마 연동 강화**: 시스템 테마가 변경될 때 실시간으로 앱 테마도 변경되도록 개선
2. **화면별 테마 최적화**: 각 화면에 맞게 다크 모드 스타일을 더 세밀하게 최적화
3. **애니메이션 추가**: 테마 전환 시 부드러운 애니메이션 추가
4. **커스텀 테마**: 사용자가 원하는 테마 색상을 직접 선택할 수 있는 기능 추가