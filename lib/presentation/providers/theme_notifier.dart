// lib/presentation/providers/theme_notifier.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱의 테마 모드를 관리하는 Provider
class ThemeNotifier with ChangeNotifier {
  // 테마 모드 저장용 키
  static const String _themePreferenceKey = 'theme_mode';
  
  // 기본 테마 모드
  ThemeMode _themeMode = ThemeMode.system;
  
  // 테마 모드 getter
  ThemeMode get themeMode => _themeMode;

  /// 생성자
  /// 
  /// 앱 시작 시 테마 설정을 로드합니다.
  ThemeNotifier() {
    _loadThemeMode();
  }

  /// 저장된 테마 모드 로드
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themePreferenceKey);
    
    if (savedMode != null) {
      _themeMode = _parseThemeMode(savedMode);
      notifyListeners();
    }
  }

  /// 문자열을 ThemeMode로 변환
  ThemeMode _parseThemeMode(String modeString) {
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// 문자열로 변환하기 위한 도우미 메서드
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// 테마 모드 설정
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    // 설정 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, _themeModeToString(mode));
  }

  /// 라이트 모드 설정
  Future<void> setLightMode() => setThemeMode(ThemeMode.light);

  /// 다크 모드 설정
  Future<void> setDarkMode() => setThemeMode(ThemeMode.dark);

  /// 시스템 모드 설정 (시스템 설정 따르기)
  Future<void> setSystemMode() => setThemeMode(ThemeMode.system);

  /// 다크 모드 토글
  Future<void> toggleThemeMode() async {
    switch (_themeMode) {
      case ThemeMode.light:
        await setDarkMode();
        break;
      case ThemeMode.dark:
        await setLightMode();
        break;
      case ThemeMode.system:
        // 시스템 모드인 경우, 현재 시스템 밝기를 확인하여 반대 모드로 설정
        final window = WidgetsBinding.instance.window;
        final brightness = window.platformBrightness;
        if (brightness == Brightness.dark) {
          await setLightMode();
        } else {
          await setDarkMode();
        }
        break;
    }
  }
  
  /// 현재 테마 모드가 다크 모드인지 확인
  /// 
  /// 시스템 설정인 경우 시스템의 밝기를 확인합니다.
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}