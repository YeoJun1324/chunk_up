// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

/*
코드 생성이 완료되었습니다.
추가 수정이 필요한 경우 다음 명령어를 실행하세요:

flutter pub run build_runner build --delete-conflicting-outputs
*/
part 'word.freezed.dart';
part 'word.g.dart';

/// Freezed로 구현한 단어 모델 클래스
///
/// freezed 패키지를 사용하여 불변성(immutability)을 구현한 Word 클래스입니다.
/// 생성된 코드는 빌드 타임에 자동으로 생성됩니다.
@freezed
class Word with _$Word {
  const Word._(); // custom 메서드를 추가하기 위한 private 생성자

  /// 기본 생성자
  const factory Word({
    required String english,
    required String korean,

    /// 단어가 청크에 포함되었는지 여부
    @Default(false) bool isInChunk,

    /// 학습 진행도 (0.0 ~ 1.0)
    @Default(0.0) double learningProgress,

    /// 마지막 학습 일시
    DateTime? lastLearned,

    /// 단어 카테고리
    String? category,

    /// 예문 목록
    @Default([]) List<String> examples,

    /// 메모
    String? memo,
  }) = _Word;

  /// JSON에서 객체 생성을 위한 팩토리 메서드
  factory Word.fromJson(Map<String, dynamic> json) => _$WordFromJson(json);

  /// 학습 진행도를 백분율로 표시 (0 ~ 100)
  int get progressPercent => (learningProgress * 100).toInt();

  /// 학습 진행 상태 문자열 (초급, 중급, 고급)
  String get progressStatus {
    if (learningProgress < 0.3) return '초급';
    if (learningProgress < 0.7) return '중급';
    return '고급';
  }

  /// 단어 복습이 필요한지 여부 확인
  bool get needsReview {
    if (lastLearned == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastLearned!);

    // 학습 진행도에 따라 복습 주기 조정
    if (learningProgress < 0.3) {
      // 1일 후 복습
      return difference.inDays >= 1;
    } else if (learningProgress < 0.7) {
      // 3일 후 복습
      return difference.inDays >= 3;
    } else {
      // 7일 후 복습
      return difference.inDays >= 7;
    }
  }

  /// 단어 학습 진행
  Word updateLearningProgress(double progress) {
    // 학습 진행도 제한 (0.0 ~ 1.0)
    final limitedProgress = progress.clamp(0.0, 1.0);

    return copyWith(
      learningProgress: limitedProgress,
      lastLearned: DateTime.now(),
    );
  }

  /// 예문 추가
  Word addExample(String example) {
    if (examples.contains(example)) return this;

    final newExamples = List<String>.from(examples)..add(example);
    return copyWith(examples: newExamples);
  }

  /// 예문 제거
  Word removeExample(String example) {
    if (!examples.contains(example)) return this;

    final newExamples = examples.where((e) => e != example).toList();
    return copyWith(examples: newExamples);
  }

  // 수동 copyWith 메서드는 제거됨 - Freezed가 자동 생성한 메서드 사용
}