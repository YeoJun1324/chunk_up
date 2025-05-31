// lib/core/constants/character_constants.dart

/// 캐릭터 관련 상수들
class CharacterConstants {
  CharacterConstants._(); // Private constructor to prevent instantiation

  /// 필터링할 기본 캐릭터 이름들
  static const List<String> excludedCharacterNames = [
    '(캐릭터 없음)',
    '캐릭터 없음',
    '기본',
    '캐릭터 새로 추가...',
    '', // 빈 문자열
  ];

  /// 기본 캐릭터 옵션
  static const String noCharacterOption = '캐릭터 없음';
  static const String addNewCharacterOption = '캐릭터 새로 추가...';
  static const String defaultCharacterOption = '기본';

  /// 캐릭터 이름 유효성 검사
  static bool isValidCharacterName(String name) {
    final trimmedName = name.trim();
    return trimmedName.isNotEmpty && !excludedCharacterNames.contains(trimmedName);
  }

  /// 캐릭터 목록 필터링
  static List<String> filterCharacterNames(List<String> names) {
    return names
        .where((name) => isValidCharacterName(name))
        .map((name) => name.trim())
        .toSet() // 중복 제거
        .toList();
  }
}