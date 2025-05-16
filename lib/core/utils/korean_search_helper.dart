// lib/utils/korean_search_helper.dart
class KoreanSearchHelper {
  // 초성 변환 맵
  static const Map<String, String> _chosungMap = {
    'ㄱ': '[가-깋]', 'ㄲ': '[까-깧]', 'ㄴ': '[나-닣]', 'ㄷ': '[다-딯]', 'ㄸ': '[따-띻]',
    'ㄹ': '[라-맇]', 'ㅁ': '[마-밓]', 'ㅂ': '[바-빟]', 'ㅃ': '[빠-삫]', 'ㅅ': '[사-싷]',
    'ㅆ': '[싸-앃]', 'ㅇ': '[아-잏]', 'ㅈ': '[자-짛]', 'ㅉ': '[짜-찧]', 'ㅊ': '[차-칳]',
    'ㅋ': '[카-킿]', 'ㅌ': '[타-팋]', 'ㅍ': '[파-핗]', 'ㅎ': '[하-힣]'
  };

  static bool matches(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    // 일반 문자열 매칭
    if (lowerText.contains(lowerQuery)) {
      return true;
    }

    // 초성 검색
    if (_isChosung(query)) {
      final pattern = _convertChosungToRegex(query);
      final regex = RegExp(pattern, caseSensitive: false);
      return regex.hasMatch(text);
    }

    return false;
  }

  static bool _isChosung(String text) {
    return text.split('').every((char) => _chosungMap.containsKey(char));
  }

  static String _convertChosungToRegex(String chosung) {
    return chosung.split('').map((char) => _chosungMap[char] ?? char).join();
  }
}