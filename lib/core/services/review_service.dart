// lib/core/services/review_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/domain/models/review_reminder.dart';
import 'package:chunk_up/core/services/notification_service.dart';

class ReviewService {
  // 싱글톤 패턴 구현
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  // SharedPreferences 키
  static const String _reviewRemindersKey = 'review_reminders';
  static const String _lastReviewCheckKey = 'last_review_check';

  // 복습 단계별 간격 (일)
  static const List<int> reviewIntervals = [1, 7, 16, 35];

  // 현재 등록된 모든 복습 알림 가져오기
  Future<List<ReviewReminder>> getAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList(_reviewRemindersKey) ?? [];
    
    final List<ReviewReminder> reminders = [];
    for (final reminderJson in remindersJson) {
      try {
        final reminder = ReviewReminder.fromJsonString(reminderJson);
        reminders.add(reminder);
      } catch (e) {
        debugPrint('리마인더 파싱 오류: $e');
      }
    }
    
    return reminders;
  }

  // 특정 날짜에 예정된 복습 알림 가져오기
  Future<List<ReviewReminder>> getRemindersForDate(DateTime date) async {
    final reminders = await getAllReminders();
    
    return reminders.where((reminder) {
      final scheduled = reminder.scheduledReviewDate;
      return scheduled.year == date.year && 
             scheduled.month == date.month && 
             scheduled.day == date.day &&
             !reminder.isCompleted;
    }).toList();
  }

  // 오늘 예정된 복습 알림 가져오기
  Future<List<ReviewReminder>> getTodaysReminders() async {
    final now = DateTime.now();
    return getRemindersForDate(now);
  }

  // 지난 복습 알림 가져오기 (완료되지 않은)
  Future<List<ReviewReminder>> getOverdueReminders() async {
    final reminders = await getAllReminders();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return reminders.where((reminder) => 
      !reminder.isCompleted && 
      reminder.scheduledReviewDate.isBefore(today)
    ).toList();
  }

  // 새 복습 알림 추가
  Future<ReviewReminder> addReminder(
    List<Chunk> chunks, 
    DateTime originalLearningDate,
    int reviewStage,
  ) async {
    final chunkIds = chunks.map((c) => c.id).toList();
    final chunkTitles = chunks.map((c) => c.title).toList();
    
    // 복습 일정 계산
    final daysToAdd = reviewIntervals[reviewStage - 1];
    final scheduledDate = originalLearningDate.add(Duration(days: daysToAdd));
    
    // UUID 생성
    final id = const Uuid().v4();
    
    // 리마인더 객체 생성
    final reminder = ReviewReminder(
      id: id,
      originalLearningDate: originalLearningDate,
      scheduledReviewDate: scheduledDate,
      chunkIds: chunkIds,
      chunkTitles: chunkTitles,
      reviewStage: reviewStage,
    );
    
    // 저장
    await _saveReminder(reminder);
    
    return reminder;
  }

  // 사용자 설정에서 최대 복습 단계 가져오기
  Future<int> getMaxReviewStage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('maxReviewStage') ?? 4; // 기본값은 4단계
  }

  // 학습 세션에 대한 모든 복습 단계 알림 한번에 생성
  Future<List<ReviewReminder>> scheduleAllReviewsForLearningSession(
    List<Chunk> chunks,
    DateTime learningDate,
  ) async {
    final List<ReviewReminder> createdReminders = [];

    // 사용자 설정에서 최대 복습 단계 가져오기
    final maxStage = await getMaxReviewStage();

    // 최대 단계가 0(꺼짐)이면 알림을 생성하지 않음
    if (maxStage == 0) {
      debugPrint('복습 알림이 꺼져 있어 알림을 생성하지 않습니다.');
      return createdReminders;
    }

    // 각 복습 단계별로 알림 생성 (사용자 설정 최대치까지만)
    for (int stage = 1; stage <= maxStage; stage++) {
      final reminder = await addReminder(chunks, learningDate, stage);
      createdReminders.add(reminder);
    }

    return createdReminders;
  }

  // 복습 알림 완료로 표시
  Future<void> markReminderAsCompleted(String reminderId) async {
    final reminders = await getAllReminders();
    bool found = false;
    
    final updatedReminders = <ReviewReminder>[];
    
    for (final reminder in reminders) {
      if (reminder.id == reminderId) {
        updatedReminders.add(reminder.markAsCompleted());
        found = true;
      } else {
        updatedReminders.add(reminder);
      }
    }
    
    if (found) {
      await _saveAllReminders(updatedReminders);
    }
  }

  // 복습 알림 삭제
  Future<void> deleteReminder(String reminderId) async {
    final reminders = await getAllReminders();
    final updatedReminders = reminders.where((r) => r.id != reminderId).toList();
    
    if (updatedReminders.length < reminders.length) {
      await _saveAllReminders(updatedReminders);
    }
  }

  // 오늘의 복습 알림 확인 (앱 시작시 호출)
  Future<bool> checkForTodaysReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString(_lastReviewCheckKey);

    // 오늘 날짜
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();

    // 이미 오늘 확인했으면 중복 알림 방지
    if (lastCheck == today) {
      return false;
    }

    // 오늘 예정된 알림과 지난 알림 확인
    final todaysReminders = await getTodaysReminders();
    final overdueReminders = await getOverdueReminders();

    // 마지막 확인 시간 업데이트
    await prefs.setString(_lastReviewCheckKey, today);

    // 다음날 아침 알림 예약
    await _scheduleNextDayMorningNotification();

    // 알림이 있는지 여부 반환
    return todaysReminders.isNotEmpty || overdueReminders.isNotEmpty;
  }

  // 내부 헬퍼: 리마인더 저장
  Future<void> _saveReminder(ReviewReminder reminder) async {
    final reminders = await getAllReminders();
    reminders.add(reminder);
    await _saveAllReminders(reminders);
  }

  // 내부 헬퍼: 모든 리마인더 저장
  Future<void> _saveAllReminders(List<ReviewReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final reminderJsons = reminders.map((r) => r.toJsonString()).toList();
    await prefs.setStringList(_reviewRemindersKey, reminderJsons);
  }

  // 다음 날 아침 8시에 복습 알림 예약 (재귀적으로 매일 실행)
  Future<void> _scheduleNextDayMorningNotification() async {
    final notificationService = NotificationService();

    // 매일 아침 8시에 복습 알림 예약
    await notificationService.scheduleFixedTimeReviewNotification(
      hour: 8,
      minute: 0,
      title: '오늘의 복습 확인하기',
      body: '오늘의 복습 일정을 확인하세요. 효과적인 학습을 위해 복습은 필수입니다!',
    );
  }

  // 일일 복습 알림 전송 (앱 시작 시 호출)
  Future<void> sendDailyReviewNotifications() async {
    // NotificationService 인스턴스 가져오기
    final notificationService = NotificationService();

    // 오늘의 복습 알림
    final todayReminders = await getTodaysReminders();
    // 지난 복습 알림
    final overdueReminders = await getOverdueReminders();

    if (todayReminders.isEmpty && overdueReminders.isEmpty) {
      return;
    }

    // 활성화된 알림만 필터링
    List<ReviewReminder> enabledReminders = [];

    // 모든 처리되지 않은 복습 알림 목록에서 활성화된 것만 필터링
    for (final reminder in [...todayReminders, ...overdueReminders]) {
      if (await isReminderNotificationEnabled(reminder.id)) {
        enabledReminders.add(reminder);
      }
    }

    // 활성화된 알림이 없으면 리턴
    if (enabledReminders.isEmpty) {
      debugPrint('활성화된 복습 알림이 없습니다.');
      return;
    }

    // 개별 알림 + 요약 알림 표시
    await notificationService.showTodaysReviewNotifications(enabledReminders);

    debugPrint('복습 알림 전송 완료: 활성화된 알림 ${enabledReminders.length}개');
  }
  
  // 특정 리마인더의 알림 활성화 상태 토글
  Future<bool> toggleReminderNotification(String reminderId) async {
    final prefs = await SharedPreferences.getInstance();
    final disabledRemindersKey = 'disabled_reminders';
    final disabledReminders = prefs.getStringList(disabledRemindersKey) ?? [];

    bool isEnabled;

    if (disabledReminders.contains(reminderId)) {
      // 현재 비활성화 상태면 활성화로 변경
      disabledReminders.remove(reminderId);
      isEnabled = true;
    } else {
      // 현재 활성화 상태면 비활성화로 변경
      disabledReminders.add(reminderId);
      isEnabled = false;
    }

    // 변경된 상태 저장
    await prefs.setStringList(disabledRemindersKey, disabledReminders);
    return isEnabled;
  }

  // 특정 리마인더의 알림 활성화 상태 확인
  Future<bool> isReminderNotificationEnabled(String reminderId) async {
    final prefs = await SharedPreferences.getInstance();
    final disabledRemindersKey = 'disabled_reminders';
    final disabledReminders = prefs.getStringList(disabledRemindersKey) ?? [];

    // ID가 비활성화 목록에 없으면 활성화 상태
    return !disabledReminders.contains(reminderId);
  }

  // 복습 알림 즉시 전송 (특정 리마인더)
  Future<void> sendReviewNotificationForReminder(ReviewReminder reminder) async {
    // 리마인더가 비활성화 상태면 알림 전송하지 않음
    if (!await isReminderNotificationEnabled(reminder.id)) {
      debugPrint('알림이 비활성화된 리마인더: ${reminder.id}');
      return;
    }

    final notificationService = NotificationService();
    await notificationService.showReviewNotification(reminder);
  }
}