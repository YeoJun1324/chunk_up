// lib/core/services/navigation_service.dart
import 'package:flutter/material.dart';

/// 전역 컨텍스트에 접근할 수 있는 네비게이션 서비스
class NavigationService {
  /// 전역 네비게이터 키
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// 현재 컨텍스트 가져오기
  static BuildContext? get currentContext => navigatorKey.currentContext;
  
  /// 새 화면으로 이동 (push)
  static Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }
  
  /// 현재 화면 대체 (replace)
  static Future<T?> replaceTo<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed(routeName, arguments: arguments);
  }
  
  /// 이전 화면으로 돌아가기 (pop)
  static void goBack<T>([T? result]) {
    return navigatorKey.currentState!.pop(result);
  }
  
  /// 홈 화면으로 이동 (popUntil)
  static void goToRoot() {
    navigatorKey.currentState!.popUntil((route) => route.isFirst);
  }
}