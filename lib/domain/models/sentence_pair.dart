// lib/domain/models/sentence_pair.dart

/// Represents a pair of English and Korean sentences that correspond to each other
class SentencePair {
  final String english;
  final String korean;
  final int index;
  final List<String> includedWords;

  const SentencePair({
    required this.english,
    required this.korean,
    required this.index,
    required this.includedWords,
  });

  SentencePair copyWith({
    String? english,
    String? korean,
    int? index,
    List<String>? includedWords,
  }) {
    return SentencePair(
      english: english ?? this.english,
      korean: korean ?? this.korean,
      index: index ?? this.index,
      includedWords: includedWords ?? this.includedWords,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is SentencePair &&
      other.english == english &&
      other.korean == korean &&
      other.index == index;
  }

  @override
  int get hashCode => english.hashCode ^ korean.hashCode ^ index.hashCode;
}