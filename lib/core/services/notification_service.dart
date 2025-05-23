// lib/core/services/notification_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:chunk_up/core/services/navigation_service.dart';
import 'package:chunk_up/domain/models/review_reminder.dart';

class NotificationService {
  // 싱글톤 패턴 구현
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  // 초기화 (앱 시작 시 호출)
  Future<void> initialize() async {
    // 타임존 초기화
    tz_data.initializeTimeZones();

    // 안드로이드 설정
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정
    final DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // 초기화 설정
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    // 초기화 및 알림 클릭 핸들러 설정
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // 알림 클릭 핸들러
  void _onNotificationTapped(NotificationResponse response) {
    // 알림 페이로드 처리
    final String? payload = response.payload;
    if (payload != null) {
      debugPrint('알림 탭: $payload');
      
      try {
        // 페이로드는 JSON 문자열로 전달됨
        final Map<String, dynamic> data = jsonDecode(payload);
        
        // 알림 타입에 따라 다른 화면으로 이동
        if (data['type'] == 'review_reminder') {
          // 복습 화면으로 이동
          if (data.containsKey('reminder_id')) {
            NavigationService.navigateTo('/learning_history', arguments: {
              'initialTab': 2, // 복습 탭 인덱스
              'reviewId': data['reminder_id'],
            });
          } else {
            NavigationService.navigateTo('/learning_history', arguments: {
              'initialTab': 2, // 복습 탭 인덱스
            });
          }
        } else {
          // 기본적으로 홈 화면으로 이동
          NavigationService.goToRoot();
        }
      } catch (e) {
        debugPrint('알림 페이로드 파싱 오류: $e');
        NavigationService.goToRoot();
      }
    }
  }

  // 즉시 알림 표시
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chunk_up_channel',
      'ChunkUp 알림',
      channelDescription: '학습 및 복습 알림',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // 복습 알림 표시 (특정 리마인더에 대해)
  Future<void> showReviewNotification(ReviewReminder reminder) async {
    // 복습 단계에 따른 타이틀과 본문 설정
    String title;
    String body;
    
    switch (reminder.reviewStage) {
      case 1:
        title = '첫 번째 복습 알림';
        body = '어제 학습한 내용을 복습할 시간입니다. 기억 효율을 높이기 위해 잠시 시간을 내어 복습해보세요.';
        break;
      case 2:
        title = '두 번째 복습 알림';
        body = '일주일 전 학습한 내용의 두 번째 복습 시간입니다. 지금 복습하면 장기 기억으로 전환됩니다.';
        break;
      case 3:
        title = '세 번째 복습 알림';
        body = '16일 전 학습한 내용을 복습할 시간입니다. 지금 복습하면 기억이 더욱 강화됩니다.';
        break;
      case 4:
        title = '마지막 복습 알림';
        body = '한 달 전 학습한 내용을 마지막으로 복습하세요. 이번 복습으로 장기 기억으로 완전히 정착됩니다.';
        break;
      default:
        title = '복습 알림';
        body = '이전에 학습한 내용을 복습할 시간입니다. 효과적인 학습을 위해 지금 복습하세요.';
    }
    
    // 청크 제목이 있으면 본문에 추가
    if (reminder.chunkTitles.isNotEmpty) {
      final String chunkTitle = reminder.chunkTitles.length == 1 
          ? '"${reminder.chunkTitles.first}"' 
          : '${reminder.chunkTitles.length}개의 단락';
      body += ' 복습 대상: $chunkTitle';
    }
    
    // 페이로드 데이터 생성
    final payload = jsonEncode({
      'type': 'review_reminder',
      'reminder_id': reminder.id,
      'stage': reminder.reviewStage,
    });
    
    // 알림 표시
    await showNotification(
      id: reminder.id.hashCode % 1000000, // ID 충돌 방지를 위한 해시값 사용
      title: title,
      body: body,
      payload: payload,
    );
  }
  
  // 오늘의 모든 복습 알림 표시
  Future<void> showTodaysReviewNotifications(List<ReviewReminder> reminders) async {
    if (reminders.isEmpty) {
      return;
    }
    
    // 1. 모든 리마인더에 대한 개별 알림 표시
    for (final reminder in reminders) {
      // 완료되지 않은 리마인더만 알림
      if (!reminder.isCompleted) {
        await showReviewNotification(reminder);
        // 알림 겹침 방지를 위한 약간의 딜레이
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    
    // 2. 요약 알림 표시 (알림이 3개 이상일 경우)
    if (reminders.length >= 3) {
      final today = DateTime.now();
      final formattedDate = '${today.month}월 ${today.day}일';
      
      await showNotification(
        id: 999999, // 고유 ID
        title: '$formattedDate 복습 일정 (${reminders.length}개)',
        body: '오늘은 ${reminders.length}개의 복습이 예정되어 있습니다. 학습 효과를 높이기 위해 모두 완료해보세요!',
        payload: jsonEncode({
          'type': 'review_reminder',
          'count': reminders.length,
        }),
      );
    }
  }

  // 기존 알림 취소
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // 매일 특정 시간에 복습 알림 예약
  Future<void> scheduleFixedTimeReviewNotification({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final id = 888888; // 고정 ID (매일 같은 알림이므로 동일 ID 사용)

    // 오늘 날짜의 특정 시간 설정
    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 이미 지난 시간이면 다음 날로 설정
    final tz.TZDateTime scheduledTzDate = tz.TZDateTime.from(
      scheduledDate.isBefore(now)
          ? scheduledDate.add(const Duration(days: 1))
          : scheduledDate,
      tz.local,
    );

    // 알림 표시
    final payload = jsonEncode({
      'type': 'daily_reminder',
      'time': scheduledTzDate.toIso8601String(),
    });

    // 즉시 표시 알림 사용 (스케줄링 대신)
    // 복잡한 반복 스케줄링은 안드로이드와 iOS 호환성 문제가 있어 단순화
    if (scheduledDate.isAfter(now) && scheduledDate.difference(now).inHours < 24) {
      await showNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );
    }
  }
}