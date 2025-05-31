// lib/core/services/sentence/unified_sentence_mapping_service.dart
import 'dart:math';
import '../../../domain/models/chunk.dart';
import '../../../domain/models/sentence_pair.dart';
import '../../../domain/models/word.dart';

/// 최적화된 통합 문장 매핑 서비스
/// 
/// 개선사항:
/// 1. 정적 RegExp 패턴으로 성능 최적화
/// 2. LRU 캐시로 메모리 관리 개선
/// 3. 일관된 구분자 처리
/// 4. 개선된 에러 처리 및 로깅
class UnifiedSentenceMappingService {
  // 정적 RegExp 패턴들 (성능 최적화)
  static final RegExp _letterPattern = RegExp(r'[a-zA-Z가-힣]');
  static final RegExp _uppercasePattern = RegExp(r'[A-Z]');
  static final RegExp _koreanPattern = RegExp(r'[가-힣]');
  static final RegExp _alphanumericKoreanPattern = RegExp(r'[a-zA-Z0-9가-힣]');
  static final RegExp _validContentPattern = RegExp(r'[a-zA-Z가-힣]');
  
  // LRU 캐시 구현
  final Map<String, _CacheEntry> _cache = {};
  final int _maxCacheSize;
  int _cacheAccessCounter = 0;

  // 에러 로깅을 위한 콜백
  final void Function(String)? onError;
  final void Function(String)? onWarning;

  UnifiedSentenceMappingService({
    int maxCacheSize = 100,
    this.onError,
    this.onWarning,
  }) : _maxCacheSize = maxCacheSize;

  /// Extract sentence pairs from a chunk with improved dialogue handling
  List<SentencePair> extractSentencePairs(Chunk chunk, {bool enableDebug = false}) {
    // LRU 캐시 확인
    final cacheEntry = _getCacheEntry(chunk.id);
    if (cacheEntry != null) {
      cacheEntry.lastAccessed = ++_cacheAccessCounter;
      if (enableDebug) _log('Cache hit for chunk ${chunk.id}');
      return cacheEntry.pairs;
    }

    try {
      final pairs = _extractSentencePairsInternal(chunk, enableDebug);
      _setCacheEntry(chunk.id, pairs);
      return pairs;
    } catch (e, stackTrace) {
      _logError('Failed to extract sentence pairs for chunk ${chunk.id}: $e', stackTrace);
      return [];
    }
  }

  /// 내부 문장 쌍 추출 로직
  List<SentencePair> _extractSentencePairsInternal(Chunk chunk, bool enableDebug) {
    // 입력 검증
    if (chunk.englishContent.trim().isEmpty || chunk.koreanTranslation.trim().isEmpty) {
      _logWarning('Empty content in chunk ${chunk.id}');
      return [];
    }

    // First, try to split using ||| delimiter
    List<String> englishSentences;
    List<String> koreanSentences;
    
    if (chunk.englishContent.contains('|||') && chunk.koreanTranslation.contains('|||')) {
      // Use delimiter-based splitting
      englishSentences = _splitByDelimiter(chunk.englishContent);
      koreanSentences = _splitByDelimiter(chunk.koreanTranslation);
      
      if (enableDebug) {
        print('Using delimiter-based splitting');
        print('English sentences: ${englishSentences.length}');
        print('Korean sentences: ${koreanSentences.length}');
      }
    } else {
      // Fall back to smart splitting for older content
      englishSentences = _smartSplitIntoSentences(chunk.englishContent);
      koreanSentences = _smartSplitIntoSentences(chunk.koreanTranslation);
      
      if (enableDebug) {
        print('Using smart splitting (no delimiters found)');
        print('English sentences: ${englishSentences.length}');
        print('Korean sentences: ${koreanSentences.length}');
      }
    }
    
    final pairs = <SentencePair>[];
    
    // If sentence counts don't match, try alternative splitting
    if (englishSentences.length != koreanSentences.length) {
      if (enableDebug) print('Sentence count mismatch. Attempting alignment...');
      final alignedPairs = _alignSentences(
        englishSentences, 
        koreanSentences,
        chunk.includedWords,
      );
      pairs.addAll(alignedPairs);
    } else {
      // Direct 1:1 mapping when counts match
      for (int i = 0; i < englishSentences.length; i++) {
        final includedWords = chunk.includedWords
            .where((word) => _containsWord(englishSentences[i], word.english))
            .map((word) => word.english)
            .toList();
        
        pairs.add(SentencePair(
          english: englishSentences[i],
          korean: koreanSentences[i],
          index: i,
          includedWords: includedWords,
        ));
      }
    }
    
    _setCacheEntry(chunk.id, pairs);
    return pairs;
  }

  /// Find a sentence pair that contains a specific word
  SentencePair? findSentencePairWithWord(Chunk chunk, String word, {bool enableDebug = false}) {
    final pairs = extractSentencePairs(chunk, enableDebug: enableDebug);
    
    try {
      return pairs.firstWhere(
        (pair) => pair.includedWords.any(
          (w) => w.toLowerCase() == word.toLowerCase()
        ),
      );
    } catch (_) {
      // If not found in included words, search in the English text
      try {
        return pairs.firstWhere(
          (pair) => _containsWord(pair.english, word),
        );
      } catch (_) {
        // Return the first pair as fallback
        return pairs.isNotEmpty ? pairs.first : null;
      }
    }
  }

  /// Get all sentence pairs for a chunk
  List<SentencePair> getSentencePairsForChunk(Chunk chunk, {bool enableDebug = false}) {
    return extractSentencePairs(chunk, enableDebug: enableDebug);
  }
  
  /// Extract all sentence pairs from a chunk (alias for UnifiedExamGenerator compatibility)
  List<SentencePair> extractAllSentencePairs(Chunk chunk) {
    return extractSentencePairs(chunk, enableDebug: false);
  }

  /// Clear cache for a specific chunk
  void clearCacheForChunk(String chunkId) {
    _cache.remove(chunkId);
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
  }

  /// 캐시 상태 확인
  bool isCached(String chunkId) {
    return _cache.containsKey(chunkId);
  }

  /// 캐시 크기 확인
  int getCacheSize() {
    return _cache.length;
  }

  /// Check if character is an opening quote
  bool _isOpeningQuote(String char) {
    return char == '"' || char == '"' || char == "'" || char == '\u2018' || char == '「' || char == '『';
  }
  
  /// Check if character is a closing quote
  bool _isClosingQuoteChar(String char) {
    return char == '"' || char == '"' || char == "'" || char == '\u2019' || char == '」' || char == '』';
  }
  
  /// Check if character is a letter
  bool _isLetter(String char) {
    return RegExp(r'[a-zA-Z가-힣]').hasMatch(char);
  }
  
  /// Check if character is uppercase
  bool _isUpperCase(String char) {
    if (char.isEmpty) return false;
    // Check for English uppercase
    if (RegExp(r'[A-Z]').hasMatch(char)) return true;
    // Korean doesn't have case, so check if it's a Korean character (treat as "uppercase" for sentence start)
    if (RegExp(r'[가-힣]').hasMatch(char)) return true;
    return false;
  }
  
  /// Check if character is sentence ending punctuation
  bool _isSentenceEndingPunctuation(String char) {
    return char == '.' || char == '!' || char == '?';
  }
  
  /// Split text by ||| delimiter
  List<String> _splitByDelimiter(String text) {
    // Split by ||| and filter out empty strings
    final sentences = text
        .split('|||')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    
    // Validate sentences
    final validSentences = <String>[];
    for (final sentence in sentences) {
      // Skip if sentence is too short or contains only punctuation
      if (sentence.length < 2) continue;
      
      // Check if sentence contains at least one letter or number
      if (!RegExp(r'[a-zA-Z0-9가-힣]').hasMatch(sentence)) continue;
      
      validSentences.add(sentence);
    }
    
    return validSentences;
  }
  
  /// Get corresponding closing quote for opening quote
  String _getClosingQuote(String openingQuote) {
    switch (openingQuote) {
      case '"':
      case '"':
        return '"';
      case "'":
      case '\u2018':
        return '\u2019';
      case '「':
        return '」';
      case '『':
        return '』';
      default:
        return openingQuote;
    }
  }

  /// Check if sentence has unmatched opening quote
  bool _hasUnmatchedQuote(String sentence) {
    int openCount = 0;
    int closeCount = 0;
    
    for (final char in sentence.split('')) {
      if (_isOpeningQuote(char)) openCount++;
      else if (_isClosingQuoteChar(char)) closeCount++;
    }
    
    return openCount > closeCount;
  }

  /// Smart sentence splitting that handles dialogue and complex punctuation
  List<String> _smartSplitIntoSentences(String text) {
    final sentences = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    String currentQuoteChar = '';
    bool expectingClosingQuote = false;
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final prevChar = i > 0 ? text[i - 1] : '';
      final nextChar = i < text.length - 1 ? text[i + 1] : '';
      
      buffer.write(char);
      
      // Track quote state with proper pairing
      if (!inQuotes && _isOpeningQuote(char)) {
        inQuotes = true;
        currentQuoteChar = char;
        expectingClosingQuote = true;
      } else if (inQuotes && char == _getClosingQuote(currentQuoteChar)) {
        expectingClosingQuote = false;
        
        // Check if sentence ends after closing quote
        if (i < text.length - 1) {
          // Case 1: "sentence." pattern
          if (nextChar == '.' || nextChar == '!' || nextChar == '?') {
            buffer.write(nextChar);
            i++; // Skip the punctuation
            
            // Check if this is truly end of sentence
            if (i >= text.length - 1 || (i < text.length - 1 && text[i + 1] == ' ')) {
              final sentence = buffer.toString().trim();
              if (_isValidSentence(sentence)) {
                sentences.add(sentence);
                buffer.clear();
                inQuotes = false;
                continue;
              }
            }
          }
          // Case 2: "sentence" (followed by space and capital letter)
          else if (nextChar == ' ' && i < text.length - 2) {
            final charAfterSpace = text[i + 2];
            if (_isUpperCase(charAfterSpace) || _isOpeningQuote(charAfterSpace)) {
              final sentence = buffer.toString().trim();
              if (_isValidSentence(sentence)) {
                sentences.add(sentence);
                buffer.clear();
                inQuotes = false;
                continue;
              }
            }
          }
        }
        // End of text
        else {
          final sentence = buffer.toString().trim();
          if (_isValidSentence(sentence)) {
            sentences.add(sentence);
            buffer.clear();
          }
        }
        inQuotes = false;
      }
      // Handle sentence endings outside quotes
      else if (!inQuotes && _isSentenceEndingPunctuation(char)) {
        // Special handling for dialogue like "Incredible! can we stop?"
        if ((char == '!' || char == '?') && i < text.length - 2) {
          // Don't split if next word starts with lowercase (likely continuation)
          if (nextChar == ' ' && text[i + 2].toLowerCase() == text[i + 2] && 
              _isLetter(text[i + 2]) && !_isOpeningQuote(text[i + 2])) {
            continue;
          }
        }
        
        // Look for proper sentence ending
        if (i < text.length - 1 && nextChar == ' ') {
          if (i < text.length - 2) {
            final charAfterSpace = text[i + 2];
            if (_isUpperCase(charAfterSpace) || _isOpeningQuote(charAfterSpace)) {
              final sentence = buffer.toString().trim();
              if (_isValidSentence(sentence)) {
                sentences.add(sentence);
                buffer.clear();
              }
            }
          }
        }
        // End of text
        else if (i == text.length - 1) {
          final sentence = buffer.toString().trim();
          if (_isValidSentence(sentence)) {
            sentences.add(sentence);
            buffer.clear();
          }
        }
      }
    }
    
    // Add remaining text
    if (buffer.isNotEmpty) {
      final sentence = buffer.toString().trim();
      if (_isValidSentence(sentence)) {
        sentences.add(sentence);
      }
    }
    
    // Handle Korean quotes separately
    return _postProcessKoreanQuotes(sentences);
  }
  
  /// Post-process to ensure Korean closing quotes are included
  List<String> _postProcessKoreanQuotes(List<String> sentences) {
    final processed = <String>[];
    
    for (int i = 0; i < sentences.length; i++) {
      var sentence = sentences[i];
      
      // Check if this sentence has opening quote but no closing quote
      if (_hasUnmatchedQuote(sentence) && i < sentences.length - 1) {
        // Check if next sentence starts with closing quote
        final nextSentence = sentences[i + 1];
        if (nextSentence.isNotEmpty && _isClosingQuoteChar(nextSentence[0])) {
          // Merge the closing quote
          sentence = sentence + nextSentence[0];
          if (nextSentence.length > 1) {
            sentences[i + 1] = nextSentence.substring(1).trim();
          } else {
            sentences[i + 1] = '';
          }
        }
      }
      
      if (sentence.isNotEmpty) {
        processed.add(sentence);
      }
    }
    
    return processed;
  }
  
  /// 문장 유효성 검사
  bool _isValidSentence(String sentence) {
    // 너무 짧은 문장 제외 (단일 단어나 부호만 있는 경우)
    if (sentence.length < 3) return false;
    
    // 최소한 하나의 알파벳이나 한글이 있어야 함
    if (!RegExp(r'[a-zA-Z가-힣]').hasMatch(sentence)) return false;
    
    return true;
  }

  /// Alternative splitting for dialogue-heavy text
  List<String> _splitByDialogue(String text) {
    final sentences = <String>[];
    
    // First, split by quotation marks to separate dialogue from narration
    final parts = text.split(RegExp(r'("[^"]*")|("[^"]*")|("[^"]*")|(\u2018[^\u2019]*\u2019)'));
    
    for (final part in parts) {
      if (part.isEmpty) continue;
      
      if (part.startsWith('"') || part.startsWith('"') || part.startsWith("'")) {
        // This is dialogue
        final cleanedPart = part.trim();
        if (cleanedPart.isNotEmpty && _isValidSentence(cleanedPart)) {
          sentences.add(cleanedPart);
        }
      } else {
        // This is narration, split by punctuation
        final subSentences = part.split(RegExp(r'(?<=[.!?])\s+'));
        sentences.addAll(
          subSentences
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty && _isValidSentence(s))
        );
      }
    }
    
    return sentences;
  }

  /// Align sentences when counts don't match
  List<SentencePair> _alignSentences(
    List<String> englishSentences,
    List<String> koreanSentences,
    List<Word> includedWords,
  ) {
    final pairs = <SentencePair>[];
    
    // Try dialogue-based splitting first
    final engDialogue = _splitByDialogue(englishSentences.join(' '));
    final korDialogue = _splitByDialogue(koreanSentences.join(' '));
    
    if (engDialogue.length == korDialogue.length && engDialogue.isNotEmpty) {
      // Success with dialogue splitting
      for (int i = 0; i < engDialogue.length; i++) {
        final includedWordsInSentence = includedWords
            .where((word) => _containsWord(engDialogue[i], word.english))
            .map((word) => word.english)
            .toList();
        
        pairs.add(SentencePair(
          english: engDialogue[i],
          korean: korDialogue[i],
          index: i,
          includedWords: includedWordsInSentence,
        ));
      }
    } else {
      // Fall back to best-effort alignment
      pairs.addAll(_performBestEffortAlignment(englishSentences, koreanSentences, includedWords));
    }
    
    return pairs;
  }

  /// 최선의 정렬 알고리즘
  List<SentencePair> _performBestEffortAlignment(
    List<String> englishSentences,
    List<String> koreanSentences,
    List<Word> includedWords,
  ) {
    final pairs = <SentencePair>[];
    final minLength = min(englishSentences.length, koreanSentences.length);
    
    // 1:1 매핑
    for (int i = 0; i < minLength; i++) {
      final includedWordsInSentence = includedWords
          .where((word) => _containsWord(englishSentences[i], word.english))
          .map((word) => word.english)
          .toList();
      
      pairs.add(SentencePair(
        english: englishSentences[i],
        korean: koreanSentences[i],
        index: i,
        includedWords: includedWordsInSentence,
      ));
    }
    
    // 남은 문장 처리
    if (englishSentences.length > koreanSentences.length) {
      // 남은 영어 문장들을 마지막 한국어 문장과 매핑
      final remainingEng = englishSentences.sublist(minLength).join(' ');
      final lastKorean = koreanSentences.isNotEmpty ? koreanSentences.last : '';
      
      final includedWordsInRemaining = includedWords
          .where((word) => _containsWord(remainingEng, word.english))
          .map((word) => word.english)
          .toList();
      
      pairs.add(SentencePair(
        english: remainingEng,
        korean: lastKorean,
        index: minLength,
        includedWords: includedWordsInRemaining,
      ));
    } else if (koreanSentences.length > englishSentences.length) {
      // 남은 한국어 문장들을 마지막 영어 문장과 매핑
      final remainingKor = koreanSentences.sublist(minLength).join(' ');
      final lastEnglish = englishSentences.isNotEmpty ? englishSentences.last : '';
      
      final includedWordsInRemaining = includedWords
          .where((word) => _containsWord(lastEnglish, word.english))
          .map((word) => word.english)
          .toList();
      
      pairs.add(SentencePair(
        english: lastEnglish,
        korean: remainingKor,
        index: minLength,
        includedWords: includedWordsInRemaining,
      ));
    }
    
    return pairs;
  }


  /// Check if a sentence contains a word (optimized with static patterns)
  bool _containsWord(String sentence, String word) {
    final lowerSentence = sentence.toLowerCase();
    final lowerWord = word.toLowerCase();
    
    // 정확한 단어 경계 검사 (최적화된 버전)
    final pattern = RegExp(r'\b' + RegExp.escape(lowerWord) + r'\b');
    return pattern.hasMatch(lowerSentence);
  }

  /// LRU 캐시 관리 메서드들
  void _setCacheEntry(String chunkId, List<SentencePair> pairs) {
    if (_cache.length >= _maxCacheSize) {
      _evictLeastRecentlyUsed();
    }
    
    _cache[chunkId] = _CacheEntry(
      pairs: pairs,
      lastAccessed: ++_cacheAccessCounter,
    );
  }

  _CacheEntry? _getCacheEntry(String chunkId) {
    return _cache[chunkId];
  }

  void _evictLeastRecentlyUsed() {
    if (_cache.isEmpty) return;
    
    String lruKey = _cache.keys.first;
    int minAccess = _cache[lruKey]!.lastAccessed;
    
    for (final entry in _cache.entries) {
      if (entry.value.lastAccessed < minAccess) {
        minAccess = entry.value.lastAccessed;
        lruKey = entry.key;
      }
    }
    
    _cache.remove(lruKey);
  }

  /// 로깅 메서드들
  void _log(String message) {
    onWarning?.call('[SentenceMapping] $message');
  }

  void _logWarning(String message) {
    onWarning?.call('[SentenceMapping WARNING] $message');
  }

  void _logError(String message, StackTrace? stackTrace) {
    onError?.call('[SentenceMapping ERROR] $message\n$stackTrace');
  }

  /// 문장 매핑 품질 점수 계산
  double calculateMappingQuality(List<SentencePair> pairs) {
    if (pairs.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    
    for (final pair in pairs) {
      double pairScore = 0.0;
      
      // 길이 비율 점수 (영어와 한국어 문장 길이 비교)
      final engLength = pair.english.length;
      final korLength = pair.korean.length;
      final lengthRatio = min(engLength, korLength) / max(engLength, korLength);
      pairScore += lengthRatio * 0.3;
      
      // 포함된 단어 점수
      if (pair.includedWords.isNotEmpty) {
        pairScore += 0.4;
      }
      
      // 문장 유효성 점수
      if (_isValidSentence(pair.english) && _isValidSentence(pair.korean)) {
        pairScore += 0.3;
      }
      
      totalScore += pairScore;
    }
    
    return totalScore / pairs.length;
  }

  /// 매핑 통계 정보 생성
  Map<String, dynamic> getMappingStatistics(Chunk chunk) {
    final pairs = extractSentencePairs(chunk);
    
    if (pairs.isEmpty) {
      return {
        'totalPairs': 0,
        'averageEnglishLength': 0,
        'averageKoreanLength': 0,
        'wordsPerPair': 0,
        'mappingQuality': 0.0,
      };
    }
    
    final totalEnglishLength = pairs.fold<int>(0, (sum, pair) => sum + pair.english.length);
    final totalKoreanLength = pairs.fold<int>(0, (sum, pair) => sum + pair.korean.length);
    final totalWords = pairs.fold<int>(0, (sum, pair) => sum + pair.includedWords.length);
    
    return {
      'totalPairs': pairs.length,
      'averageEnglishLength': totalEnglishLength / pairs.length,
      'averageKoreanLength': totalKoreanLength / pairs.length,
      'wordsPerPair': totalWords / pairs.length,
      'mappingQuality': calculateMappingQuality(pairs),
    };
  }

  /// 매핑 성능 디버깅 정보
  Map<String, dynamic> getDebugInfo(Chunk chunk) {
    final englishSentences = _smartSplitIntoSentences(chunk.englishContent);
    final koreanSentences = _smartSplitIntoSentences(chunk.koreanTranslation);
    final pairs = extractSentencePairs(chunk);
    
    return {
      'chunkId': chunk.id,
      'originalEnglishSentences': englishSentences.length,
      'originalKoreanSentences': koreanSentences.length,
      'finalPairs': pairs.length,
      'isCached': isCached(chunk.id),
      'statistics': getMappingStatistics(chunk),
      'englishSentences': englishSentences,
      'koreanSentences': koreanSentences,
    };
  }

  /// 매핑 품질 분석
  MappingQualityReport analyzeMappingQuality(Chunk chunk) {
    final pairs = extractSentencePairs(chunk);
    
    if (pairs.isEmpty) {
      return MappingQualityReport(
        score: 0.0,
        totalPairs: 0,
        issues: ['No sentence pairs found'],
      );
    }

    double totalScore = 0.0;
    final issues = <String>[];
    
    for (final pair in pairs) {
      double pairScore = 0.0;
      
      // 길이 비율 점수
      final lengthRatio = _calculateLengthRatio(pair.english, pair.korean);
      pairScore += lengthRatio * 0.4;
      
      // 포함된 단어 점수
      if (pair.includedWords.isNotEmpty) {
        pairScore += 0.3;
      } else {
        issues.add('Pair ${pair.index}: No included words');
      }
      
      // 문장 유효성 점수
      if (_isValidSentence(pair.english) && _isValidSentence(pair.korean)) {
        pairScore += 0.3;
      } else {
        issues.add('Pair ${pair.index}: Invalid sentence structure');
      }
      
      totalScore += pairScore;
    }
    
    return MappingQualityReport(
      score: totalScore / pairs.length,
      totalPairs: pairs.length,
      issues: issues,
    );
  }

  double _calculateLengthRatio(String english, String korean) {
    final engLength = english.length;
    final korLength = korean.length;
    return min(engLength, korLength) / max(engLength, korLength);
  }
}

/// 캐시 엔트리 클래스
class _CacheEntry {
  final List<SentencePair> pairs;
  int lastAccessed;

  _CacheEntry({
    required this.pairs,
    required this.lastAccessed,
  });
}

/// 매핑 품질 보고서 클래스
class MappingQualityReport {
  final double score;
  final int totalPairs;
  final List<String> issues;

  const MappingQualityReport({
    required this.score,
    required this.totalPairs,
    required this.issues,
  });

  bool get isGood => score >= 0.8;
  bool get isAcceptable => score >= 0.6;
}