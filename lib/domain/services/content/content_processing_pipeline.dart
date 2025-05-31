// lib/core/services/content_processing_pipeline.dart
import 'dart:async';
import '../../models/chunk.dart';
import '../../models/word.dart';
import 'package:chunk_up/domain/services/sentence/unified_sentence_mapping_service.dart';

/// 콘텐츠 처리 파이프라인
/// 
/// 청크 생성부터 최종 사용까지의 데이터 흐름을 통합 관리
/// - ||| 구분자 일관성 보장
/// - 문장 매핑 최적화
/// - 에러 처리 및 복구
class ContentProcessingPipeline {
  final UnifiedSentenceMappingService _mappingService;
  final StreamController<ProcessingEvent> _eventController = StreamController.broadcast();

  ContentProcessingPipeline({
    UnifiedSentenceMappingService? mappingService,
  }) : _mappingService = mappingService ?? UnifiedSentenceMappingService(
    onError: (msg) => print('[Pipeline ERROR] $msg'),
    onWarning: (msg) => print('[Pipeline WARNING] $msg'),
  );

  /// 이벤트 스트림
  Stream<ProcessingEvent> get events => _eventController.stream;

  /// API 응답에서 청크 생성 (구분자 정규화 포함)
  Future<ProcessedChunk> processApiResponse(
    String apiResponse, 
    List<Word> requestedWords,
  ) async {
    try {
      _emitEvent(ProcessingEvent.started('Processing API response'));

      // 1. JSON 파싱
      final parsedData = await _parseJsonResponse(apiResponse);
      
      // 2. 구분자 정규화
      final normalizedContent = _normalizeDelimiters(parsedData);
      
      // 3. 청크 생성
      final chunk = _createChunkFromData(normalizedContent, requestedWords);
      
      // 4. 문장 매핑 검증
      final mappingQuality = await _validateSentenceMapping(chunk);
      
      // 5. 최종 검증
      final validationResult = _validateChunk(chunk, requestedWords);
      
      final processedChunk = ProcessedChunk(
        chunk: chunk,
        mappingQuality: mappingQuality,
        validationResult: validationResult,
        processingTime: DateTime.now(),
      );

      _emitEvent(ProcessingEvent.completed('Chunk processing completed', processedChunk));
      
      return processedChunk;
    } catch (e, stackTrace) {
      _emitEvent(ProcessingEvent.error('Processing failed: $e', e, stackTrace));
      rethrow;
    }
  }

  /// 청크 콘텐츠를 시험지용으로 처리
  Future<ExamProcessedContent> processForExam(Chunk chunk) async {
    try {
      _emitEvent(ProcessingEvent.started('Processing chunk for exam'));

      // 1. 문장 쌍 추출
      final sentencePairs = _mappingService.extractSentencePairs(chunk);
      
      // 2. 구분자 제거된 콘텐츠 생성 (시험지용)
      final cleanContent = _removeDelimitersForDisplay(chunk.englishContent);
      final cleanTranslation = _removeDelimitersForDisplay(chunk.koreanTranslation);
      
      // 3. 단어 위치 매핑
      final wordPositions = _mapWordPositions(cleanContent, chunk.includedWords);
      
      final examContent = ExamProcessedContent(
        cleanEnglishContent: cleanContent,
        cleanKoreanTranslation: cleanTranslation,
        sentencePairs: sentencePairs,
        wordPositions: wordPositions,
        processingTime: DateTime.now(),
      );

      _emitEvent(ProcessingEvent.completed('Exam processing completed', examContent));
      
      return examContent;
    } catch (e, stackTrace) {
      _emitEvent(ProcessingEvent.error('Exam processing failed: $e', e, stackTrace));
      rethrow;
    }
  }

  /// 청크 콘텐츠를 표시용으로 처리
  Future<DisplayProcessedContent> processForDisplay(Chunk chunk) async {
    try {
      _emitEvent(ProcessingEvent.started('Processing chunk for display'));

      // 1. 구분자 제거 및 공백 정규화
      final displayContent = _processForDisplay(chunk.englishContent);
      final displayTranslation = _processForDisplay(chunk.koreanTranslation);
      
      // 2. 문장 쌍 추출
      final sentencePairs = _mappingService.extractSentencePairs(chunk);
      
      // 3. 단어 하이라이팅 정보 생성
      final highlightInfo = _generateHighlightInfo(displayContent, chunk.includedWords);
      
      final displayContent_obj = DisplayProcessedContent(
        displayEnglishContent: displayContent,
        displayKoreanTranslation: displayTranslation,
        sentencePairs: sentencePairs,
        highlightInfo: highlightInfo,
        processingTime: DateTime.now(),
      );

      _emitEvent(ProcessingEvent.completed('Display processing completed', displayContent_obj));
      
      return displayContent_obj;
    } catch (e, stackTrace) {
      _emitEvent(ProcessingEvent.error('Display processing failed: $e', e, stackTrace));
      rethrow;
    }
  }

  /// API 응답 JSON 파싱
  Future<Map<String, dynamic>> _parseJsonResponse(String response) async {
    try {
      // 코드 블록 제거
      var cleanResponse = response.trim();
      
      // ```json{ 형태 처리 - 줄바꿈 없이 바로 JSON이 시작되는 경우 포함
      if (cleanResponse.startsWith('```json') && cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse
            .replaceFirst(RegExp(r'^```json\s*'), '')
            .replaceFirst(RegExp(r'\s*```$'), '');
      } else if (cleanResponse.startsWith('```') && cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse
            .replaceFirst(RegExp(r'^```\s*'), '')
            .replaceFirst(RegExp(r'\s*```$'), '');
      }
      
      // ** 포맷팅 제거
      cleanResponse = cleanResponse.replaceAll('**', '');
      
      // JSON 파싱
      final parsed = _parseJson(cleanResponse);
      
      if (parsed is! Map<String, dynamic>) {
        throw ProcessingException('Invalid JSON structure');
      }
      
      return parsed;
    } catch (e) {
      throw ProcessingException('JSON parsing failed: $e');
    }
  }

  /// 구분자 정규화
  Map<String, dynamic> _normalizeDelimiters(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    
    // 영어 콘텐츠 정규화
    if (normalized['englishContent'] is String) {
      normalized['englishContent'] = _normalizeDelimiterString(normalized['englishContent']);
    }
    
    // 한국어 콘텐츠 정규화
    if (normalized['koreanTranslation'] is String) {
      normalized['koreanTranslation'] = _normalizeDelimiterString(normalized['koreanTranslation']);
    }
    
    return normalized;
  }

  /// 문자열의 구분자 정규화
  String _normalizeDelimiterString(String content) {
    return content
        // ||| 뒤에 공백이 없으면 추가
        .replaceAll(RegExp(r'\|\|\|(?!\s)'), '||| ')
        // 중복 공백 정리
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 청크 데이터 생성
  Chunk _createChunkFromData(Map<String, dynamic> data, List<Word> requestedWords) {
    // 필수 필드 검증
    final requiredFields = ['title', 'englishContent', 'koreanTranslation'];
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null || data[field].toString().trim().isEmpty) {
        throw ProcessingException('Missing or empty required field: $field');
      }
    }

    // 단어 매핑 처리
    final wordMappings = data['wordMappings'] as Map<String, dynamic>? ?? {};
    final wordExplanations = data['wordExplanations'] as Map<String, dynamic>? ?? {};
    
    // 포함된 단어 리스트 생성
    final includedWords = <Word>[];
    for (final requestedWord in requestedWords) {
      final mapping = wordMappings[requestedWord.english] ?? requestedWord.korean;
      includedWords.add(Word(
        english: requestedWord.english,
        korean: mapping.toString(),
      ));
    }

    return Chunk(
      id: _generateChunkId(),
      title: data['title'].toString(),
      englishContent: data['englishContent'].toString(),
      koreanTranslation: data['koreanTranslation'].toString(),
      includedWords: includedWords,
      wordExplanations: Map<String, String>.from(
        wordExplanations.map((k, v) => MapEntry(k.toString().toLowerCase(), v.toString()))
      ),
      createdAt: DateTime.now(),
    );
  }

  /// 문장 매핑 검증
  Future<MappingQualityReport> _validateSentenceMapping(Chunk chunk) async {
    return _mappingService.analyzeMappingQuality(chunk);
  }

  /// 청크 검증
  ChunkValidationResult _validateChunk(Chunk chunk, List<Word> requestedWords) {
    final issues = <String>[];
    final warnings = <String>[];

    // 1. 요청된 단어가 모두 포함되었는지 확인
    for (final word in requestedWords) {
      if (!chunk.englishContent.toLowerCase().contains(word.english.toLowerCase())) {
        issues.add('Requested word "${word.english}" not found in content');
      }
    }

    // 2. 문장 수 일치 검증
    final englishSentenceCount = chunk.englishContent.split('|||').length;
    final koreanSentenceCount = chunk.koreanTranslation.split('|||').length;
    
    if (englishSentenceCount != koreanSentenceCount) {
      warnings.add('Sentence count mismatch: EN=$englishSentenceCount, KO=$koreanSentenceCount');
    }

    // 3. 단어 설명 검증
    if (chunk.wordExplanations.isEmpty) {
      issues.add('No word explanations provided');
    } else {
      for (final word in requestedWords) {
        if (!chunk.wordExplanations.containsKey(word.english.toLowerCase())) {
          warnings.add('Missing explanation for word "${word.english}"');
        }
      }
    }

    return ChunkValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      warnings: warnings,
    );
  }

  /// 표시용 콘텐츠 처리
  String _processForDisplay(String content) {
    return content
        .replaceAll('|||', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 시험지용 구분자 제거
  String _removeDelimitersForDisplay(String content) {
    return content
        .replaceAll('|||', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 단어 위치 매핑
  Map<String, List<WordPosition>> _mapWordPositions(String content, List<Word> words) {
    final positions = <String, List<WordPosition>>{};
    
    for (final word in words) {
      positions[word.english] = _findWordPositions(content, word.english);
    }
    
    return positions;
  }

  /// 단어 위치 찾기
  List<WordPosition> _findWordPositions(String content, String word) {
    final positions = <WordPosition>[];
    final pattern = RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
    
    for (final match in pattern.allMatches(content)) {
      positions.add(WordPosition(
        start: match.start,
        end: match.end,
        word: content.substring(match.start, match.end),
      ));
    }
    
    return positions;
  }

  /// 하이라이팅 정보 생성
  Map<String, HighlightInfo> _generateHighlightInfo(String content, List<Word> words) {
    final highlights = <String, HighlightInfo>{};
    
    for (final word in words) {
      final positions = _findWordPositions(content, word.english);
      if (positions.isNotEmpty) {
        highlights[word.english] = HighlightInfo(
          word: word,
          positions: positions,
        );
      }
    }
    
    return highlights;
  }

  /// 유틸리티 메서드들
  String _generateChunkId() {
    return 'chunk_${DateTime.now().millisecondsSinceEpoch}';
  }

  dynamic _parseJson(String jsonString) {
    // JSON 파싱 로직 (dart:convert 사용)
    return {};  // 실제 구현에서는 jsonDecode 사용
  }

  void _emitEvent(ProcessingEvent event) {
    _eventController.add(event);
  }

  /// 리소스 정리
  void dispose() {
    _eventController.close();
    _mappingService.clearCache();
  }
}

/// 처리된 청크 클래스
class ProcessedChunk {
  final Chunk chunk;
  final MappingQualityReport mappingQuality;
  final ChunkValidationResult validationResult;
  final DateTime processingTime;

  const ProcessedChunk({
    required this.chunk,
    required this.mappingQuality,
    required this.validationResult,
    required this.processingTime,
  });

  bool get isValid => validationResult.isValid && mappingQuality.isAcceptable;
}

/// 시험지용 처리된 콘텐츠
class ExamProcessedContent {
  final String cleanEnglishContent;
  final String cleanKoreanTranslation;
  final List<dynamic> sentencePairs;  // SentencePair 타입
  final Map<String, List<WordPosition>> wordPositions;
  final DateTime processingTime;

  const ExamProcessedContent({
    required this.cleanEnglishContent,
    required this.cleanKoreanTranslation,
    required this.sentencePairs,
    required this.wordPositions,
    required this.processingTime,
  });
}

/// 표시용 처리된 콘텐츠
class DisplayProcessedContent {
  final String displayEnglishContent;
  final String displayKoreanTranslation;
  final List<dynamic> sentencePairs;  // SentencePair 타입
  final Map<String, HighlightInfo> highlightInfo;
  final DateTime processingTime;

  const DisplayProcessedContent({
    required this.displayEnglishContent,
    required this.displayKoreanTranslation,
    required this.sentencePairs,
    required this.highlightInfo,
    required this.processingTime,
  });
}

/// 청크 검증 결과
class ChunkValidationResult {
  final bool isValid;
  final List<String> issues;
  final List<String> warnings;

  const ChunkValidationResult({
    required this.isValid,
    required this.issues,
    required this.warnings,
  });
}

/// 단어 위치 정보
class WordPosition {
  final int start;
  final int end;
  final String word;

  const WordPosition({
    required this.start,
    required this.end,
    required this.word,
  });
}

/// 하이라이팅 정보
class HighlightInfo {
  final Word word;
  final List<WordPosition> positions;

  const HighlightInfo({
    required this.word,
    required this.positions,
  });
}

/// 처리 이벤트
class ProcessingEvent {
  final ProcessingEventType type;
  final String message;
  final dynamic data;
  final dynamic error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  const ProcessingEvent({
    required this.type,
    required this.message,
    this.data,
    this.error,
    this.stackTrace,
    required this.timestamp,
  });

  factory ProcessingEvent.started(String message) {
    return ProcessingEvent(
      type: ProcessingEventType.started,
      message: message,
      timestamp: DateTime.now(),
    );
  }

  factory ProcessingEvent.completed(String message, dynamic data) {
    return ProcessingEvent(
      type: ProcessingEventType.completed,
      message: message,
      data: data,
      timestamp: DateTime.now(),
    );
  }

  factory ProcessingEvent.error(String message, dynamic error, StackTrace? stackTrace) {
    return ProcessingEvent(
      type: ProcessingEventType.error,
      message: message,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );
  }
}

/// 처리 이벤트 타입
enum ProcessingEventType {
  started,
  completed,
  error,
}

/// 처리 예외
class ProcessingException implements Exception {
  final String message;
  
  const ProcessingException(this.message);
  
  @override
  String toString() => 'ProcessingException: $message';
}