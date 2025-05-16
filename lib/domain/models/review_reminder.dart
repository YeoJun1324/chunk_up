// lib/domain/models/review_reminder.dart
import 'dart:convert';

/// 망각 곡선에 따른 복습 알림을 관리하는 불변 클래스
class ReviewReminder {
  /// 복습 알림 고유 ID
  final String id;

  /// 원래 학습 일시
  final DateTime originalLearningDate;

  /// 예정된 복습 일시
  final DateTime scheduledReviewDate;

  /// 복습할 청크 ID 목록 (불변)
  final List<String> chunkIds;

  /// 청크 제목 목록 (사용자에게 표시용)
  final List<String> chunkTitles;

  /// 복습 단계 (1: 1일 후, 2: 7일 후, 3: 16일 후, 4: 35일 후)
  final int reviewStage;

  /// 복습 완료 여부
  final bool isCompleted;

  /// 생성자
  ReviewReminder({
    required this.id,
    required this.originalLearningDate,
    required this.scheduledReviewDate,
    required this.chunkIds,
    required this.chunkTitles,
    required this.reviewStage,
    this.isCompleted = false,
  });

  /// 불변성 패턴을 위한 복사 생성 메서드
  ReviewReminder copyWith({
    String? id,
    DateTime? originalLearningDate,
    DateTime? scheduledReviewDate,
    List<String>? chunkIds,
    List<String>? chunkTitles,
    int? reviewStage,
    bool? isCompleted,
  }) {
    return ReviewReminder(
      id: id ?? this.id,
      originalLearningDate: originalLearningDate ?? this.originalLearningDate,
      scheduledReviewDate: scheduledReviewDate ?? this.scheduledReviewDate,
      chunkIds: chunkIds ?? List<String>.from(this.chunkIds),
      chunkTitles: chunkTitles ?? List<String>.from(this.chunkTitles),
      reviewStage: reviewStage ?? this.reviewStage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// 복습 완료로 표시
  ReviewReminder markAsCompleted() {
    return copyWith(isCompleted: true);
  }

  /// 다음 복습 단계로 이동하는 새 리마인더 생성
  ReviewReminder createNextStageReminder() {
    if (reviewStage >= 4) {
      // 마지막 단계면 더 이상 생성하지 않음
      return this;
    }

    // 망각 곡선에 따른 복습 일정: 1일, 7일, 16일, 35일 후
    final int daysToAdd;
    switch (reviewStage) {
      case 1:
        daysToAdd = 7; // 첫 복습 후 7일 후
        break;
      case 2:
        daysToAdd = 16; // 두 번째 복습 후 16일 후
        break;
      case 3:
        daysToAdd = 35; // 세 번째 복습 후 35일 후
        break;
      default:
        daysToAdd = 1; // 기본값
    }

    // UUID 생성을 위해 임의 문자열 생성 (실제로는 UUID 패키지 사용 권장)
    final nextId = '${id}_stage_${reviewStage + 1}';

    return ReviewReminder(
      id: nextId,
      originalLearningDate: originalLearningDate,
      scheduledReviewDate: DateTime.now().add(Duration(days: daysToAdd)),
      chunkIds: List<String>.from(chunkIds),
      chunkTitles: List<String>.from(chunkTitles),
      reviewStage: reviewStage + 1,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalLearningDate': originalLearningDate.toIso8601String(),
      'scheduledReviewDate': scheduledReviewDate.toIso8601String(),
      'chunkIds': chunkIds,
      'chunkTitles': chunkTitles,
      'reviewStage': reviewStage,
      'isCompleted': isCompleted,
    };
  }

  /// JSON에서 객체 생성
  factory ReviewReminder.fromJson(Map<String, dynamic> json) {
    return ReviewReminder(
      id: json['id'] as String,
      originalLearningDate: DateTime.parse(json['originalLearningDate'] as String),
      scheduledReviewDate: DateTime.parse(json['scheduledReviewDate'] as String),
      chunkIds: List<String>.from(json['chunkIds'] as List),
      chunkTitles: List<String>.from(json['chunkTitles'] as List),
      reviewStage: json['reviewStage'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  /// SharedPreferences용 String으로 변환
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// SharedPreferences용 String에서 객체 생성
  factory ReviewReminder.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString) as Map<String, dynamic>;
    return ReviewReminder.fromJson(json);
  }

  /// 오늘 복습 예정인지 확인
  bool get isScheduledForToday {
    final now = DateTime.now();
    return scheduledReviewDate.year == now.year && 
           scheduledReviewDate.month == now.month && 
           scheduledReviewDate.day == now.day;
  }

  /// 복습이 늦었는지 확인 (오늘 이전에 예정되었지만 완료하지 않은 경우)
  bool get isOverdue {
    final now = DateTime.now();
    return !isCompleted && scheduledReviewDate.isBefore(
      DateTime(now.year, now.month, now.day)
    );
  }
}