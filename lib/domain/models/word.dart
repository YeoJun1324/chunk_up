// lib/models/word.dart
/// 단어 모델 클래스
/// 
/// 영어 단어와 한국어 뜻, 관련 상태를 관리합니다.
class Word {
  final String english;
  final String korean;
  final bool isInChunk; // 청크에 포함되었는지 여부
  final double? testAccuracy; // 테스트 정확도 (선택)
  final DateTime addedDate; // 추가된 날짜

  Word({
    required this.english,
    required this.korean,
    this.isInChunk = false,
    this.testAccuracy,
    DateTime? addedDate,
  }) : addedDate = addedDate ?? DateTime.now();

  /// 불변성 패턴을 위한 복사 생성 메서드
  /// 
  /// 특정 속성만 변경한 새 Word 객체를 생성합니다.
  Word copyWith({
    String? english,
    String? korean,
    bool? isInChunk,
    double? testAccuracy,
    DateTime? addedDate,
  }) {
    return Word(
      english: english ?? this.english,
      korean: korean ?? this.korean,
      isInChunk: isInChunk ?? this.isInChunk,
      testAccuracy: testAccuracy ?? this.testAccuracy,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  // Word 객체 비교를 위한 operator== 오버라이드
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Word &&
        other.english == english &&
        other.korean == korean;
  }

  // operator== 를 오버라이드하면 hashCode도 오버라이드해야 함
  @override
  int get hashCode => english.hashCode ^ korean.hashCode;

  // Optional: Add toJson/fromJson for persistence
  Map<String, dynamic> toJson() {
    return {
      'english': english,
      'korean': korean,
      'isInChunk': isInChunk,
      'testAccuracy': testAccuracy,
      'addedDate': addedDate.toIso8601String(),
    };
  }

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      english: json['english'],
      korean: json['korean'],
      isInChunk: json['isInChunk'] ?? false,
      testAccuracy: json['testAccuracy'],
      addedDate: json['addedDate'] != null
          ? DateTime.parse(json['addedDate'])
          : null,
    );
  }
}