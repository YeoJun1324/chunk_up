// lib/domain/models/folder.dart

/// Represents a folder that contains word lists
/// 불변성(Immutability) 패턴을 적용한 클래스로,
/// 모든 속성은 final로 선언되어 있으며 수정 시 새 인스턴스를 생성합니다.
class Folder {
  final String name;
  final List<String> wordListNames;

  Folder({
    required this.name,
    List<String>? wordListNames,
  }) : wordListNames = List.unmodifiable(wordListNames ?? []);

  /// Create a Folder from json
  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      name: json['name'] ?? '',
      wordListNames: List<String>.from(json['wordListNames'] ?? []),
    );
  }

  /// Convert folder to json
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'wordListNames': wordListNames,
    };
  }

  /// 불변성 패턴을 위한 복사 생성 메서드
  /// 기존 객체를 변경하지 않고 새 객체를 반환합니다.
  Folder copyWith({
    String? name,
    List<String>? wordListNames,
  }) {
    return Folder(
      name: name ?? this.name,
      wordListNames: wordListNames ?? List<String>.from(this.wordListNames),
    );
  }

  /// 단어장 추가 메서드 - 불변성 유지
  Folder addWordList(String wordListName) {
    if (wordListNames.contains(wordListName)) {
      return this;
    }

    final newWordListNames = List<String>.from(wordListNames)..add(wordListName);
    return copyWith(wordListNames: newWordListNames);
  }

  /// 단어장 제거 메서드 - 불변성 유지
  Folder removeWordList(String wordListName) {
    final newWordListNames = List<String>.from(wordListNames)..remove(wordListName);
    return copyWith(wordListNames: newWordListNames);
  }
}