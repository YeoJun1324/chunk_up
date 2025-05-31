import 'package:flutter/material.dart';

/// 앱 전체에서 사용되는 색상 정의
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();
  
  // Primary colors
  static const Color primaryLight = Color(0xFFFF6B35);  // 밝은 주황색
  static const Color primaryDark = Color(0xFFFF8C00);   // 어두운 주황색
  
  // Secondary colors
  static const Color secondaryLight = Color(0xFF4ECDC4); // 청록색
  static const Color secondaryDark = Color(0xFF2B9B94);  // 어두운 청록색
  
  // Static color constants
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textHintLight = Color(0xFF9E9E9E);
  static const Color textHintDark = Color(0xFF616161);
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF424242);
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x40000000);

  // Get primary color based on theme
  static Color primary(BuildContext context) {
    return primaryDark;  // 라이트/다크 모드 모두 동일한 오렌지색 사용
  }
  
  // Get secondary color based on theme
  static Color secondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? secondaryDark
        : secondaryLight;
  }
  
  // Semantic colors (고정)
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);
  
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);
  
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFD54F);
  static const Color warningDark = Color(0xFFF57C00);
  
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);
  
  // Background colors
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212)  // Material Dark 배경
        : const Color(0xFFFAFAFA); // 밝은 회색 배경
  }
  
  // Surface colors (카드, 다이얼로그 등)
  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
  }
  
  // Elevated surface (더 높은 elevation)
  static Color surfaceVariant(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFF5F5F5);
  }
  
  // Text colors
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF212121);
  }
  
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB3B3B3)
        : const Color(0xFF757575);
  }
  
  static Color textHint(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF808080)
        : const Color(0xFF9E9E9E);
  }
  
  // Border colors
  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF424242)
        : const Color(0xFFE0E0E0);
  }
  
  // Divider colors
  static Color divider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF424242)
        : const Color(0xFFE0E0E0);
  }
  
  // Question type colors (고정)
  static const Color fillInBlanks = Color(0xFF2196F3);    // 파란색
  static const Color contextMeaning = Color(0xFFFF9800);   // 주황색  
  static const Color translation = Color(0xFF9C27B0);      // 보라색
  
  // Learning status colors (고정)
  static const Color notStarted = Color(0xFF9E9E9E);      // 회색
  static const Color inProgress = Color(0xFFFFC107);       // 노란색
  static const Color completed = Color(0xFF4CAF50);        // 녹색
  
  // Chip colors
  static Color chipBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF383838)
        : const Color(0xFFE0E0E0);
  }
  
  // Shimmer effect colors
  static Color shimmer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF424242)
        : const Color(0xFFE0E0E0);
  }
  
  // FAB colors
  static Color fabBackground(BuildContext context) {
    return primary(context);
  }
  
  // Input field colors
  static Color inputFillColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF383838)
        : const Color(0xFFF5F5F5);
  }
}