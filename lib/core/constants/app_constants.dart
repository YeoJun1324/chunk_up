// lib/core/constants/app_constants.dart
class AppConstants {
  // 단어장 관련 상수
  static const int minWordsForChunk = 5;
  static const int maxWordsForChunk = 25;
  static const int maxWordsPerTest = 10;

  // UI 관련 상수
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;

  // 애니메이션 상수
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  // 페이지 전환 상수
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);

  // 학습 관련 상수
  static const List<int> reviewDays = [1, 7, 16, 35]; // 망각 곡선 복습 일정

  // TTS 관련 상수
  static const double ttsSpeechRate = 0.5;
  static const double ttsVolume = 1.0;
  static const double ttsPitch = 1.0;

  // 기본 단어장 이름
  static const String defaultWordListName = '토익 필수';

  // 지원 언어
  static const List<String> supportedLanguages = ['ko', 'ja'];

  // 저장소 키값
  static const String wordListsStorageKey = 'word_lists';
  static const String testHistoryStorageKey = 'test_history';
  static const String learningHistoryStorageKey = 'learning_history';
  static const String reviewRemindersStorageKey = 'review_reminders';
  static const String foldersStorageKey = 'folders';
  static const String customCharactersStorageKey = 'custom_characters';
}