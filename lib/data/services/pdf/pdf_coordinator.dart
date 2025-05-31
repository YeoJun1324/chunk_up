// lib/core/services/pdf/pdf_coordinator.dart
import 'dart:typed_data';

import '../../../domain/models/exam_models.dart';
import '../../../domain/models/word_list_info.dart';
import '../../../domain/models/chunk.dart';
import 'package:chunk_up/data/services/subscription/subscription_service.dart';
import 'exam_pdf_service.dart';
import 'material_pdf_service.dart';

/// PDF 생성을 조율하는 코디네이터 클래스
/// 시험지 생성과 교재 생성의 플로우를 명확히 분리하고 관리
class PdfCoordinator {
  final ExamPdfService _examPdfService = ExamPdfService();
  final MaterialPdfService _materialPdfService = MaterialPdfService();
  final SubscriptionService _subscriptionService;
  
  PdfCoordinator(this._subscriptionService);
  
  /// 시험지 생성 플로우
  Future<PdfGenerationResult> generateExamPdf({
    required List<WordListInfo> wordLists,
    required List<Chunk> chunks,
    required ExamConfig config,
  }) async {
    try {
      // 1. 구독 상태 검증
      final subscriptionResult = _validateExamGeneration(config);
      if (!subscriptionResult.isValid) {
        return PdfGenerationResult.error(subscriptionResult.errorMessage!);
      }
      
      // 2. 데이터 검증
      final validationResult = _validateExamData(wordLists, chunks, config);
      if (!validationResult.isValid) {
        return PdfGenerationResult.error(validationResult.errorMessage!);
      }
      
      // 3. PDF 생성 (Premium 전용)
      if (!_subscriptionService.isPremium) {
        return PdfGenerationResult.error('시험지 생성은 Premium 구독자 전용 기능입니다.');
      }
      
      final pdfBytes = await _examPdfService.createPremiumExamPdf(
        wordLists: wordLists,
        chunks: chunks,
        config: config,
      );
      
      return PdfGenerationResult.success(
        pdfBytes: pdfBytes,
        title: _generateExamTitle(wordLists, config),
        type: PdfType.exam,
      );
      
    } catch (e) {
      return PdfGenerationResult.error('시험지 생성 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 교재 생성 플로우 - WordListExportScreen에서 사용
  Future<PdfGenerationResult> generateWordListPdf({
    required Map<WordListInfo, List<Chunk>> wordListChunks,
    String? title,
  }) async {
    try {
      // 1. 구독 상태 검증 (프리미엄 사용자만)
      if (!_subscriptionService.isPremium) {
        return PdfGenerationResult.error('PDF 내보내기는 프리미엄 기능입니다.');
      }
      
      // 2. 데이터 검증
      if (wordListChunks.isEmpty) {
        return PdfGenerationResult.error('내보낼 단어장을 선택해주세요.');
      }
      
      // 3. PDF 생성
      final pdfBytes = await _materialPdfService.createWordListPdf(
        wordListChunks: wordListChunks,
        title: title,
      );
      
      return PdfGenerationResult.success(
        pdfBytes: pdfBytes,
        title: 'ChunkUp 단어장 내보내기',
        type: PdfType.material,
      );
      
    } catch (e) {
      return PdfGenerationResult.error('PDF 생성 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 기존 교재 생성 플로우 (호환성 유지)
  Future<PdfGenerationResult> generateMaterialPdf({
    required List<WordListInfo> wordLists,
    required MaterialConfig config,
  }) async {
    try {
      // 1. 구독 상태 검증
      final subscriptionResult = _validateMaterialGeneration(config);
      if (!subscriptionResult.isValid) {
        return PdfGenerationResult.error(subscriptionResult.errorMessage!);
      }
      
      // 2. 데이터 검증
      final validationResult = _validateMaterialData(wordLists, config);
      if (!validationResult.isValid) {
        return PdfGenerationResult.error(validationResult.errorMessage!);
      }
      
      // 3. PDF 생성 (타입에 따라)
      late Uint8List pdfBytes;
      late String title;
      
      switch (config.materialType) {
        case MaterialType.wordList:
          // 이제는 generateWordListPdf를 사용하도록 권장
          throw UnimplementedError('Use generateWordListPdf instead');
          break;
          
        case MaterialType.chunkCollection:
          final allChunks = _extractChunksFromWordLists(wordLists);
          pdfBytes = await _materialPdfService.createChunkCollectionPdf(
            chunks: allChunks,
            title: config.title,
            includeTranslations: config.includeTranslations,
            includeWordExplanations: config.includeWordExplanations,
          );
          title = config.title;
          break;
          
        case MaterialType.studyProgress:
          pdfBytes = await _materialPdfService.createStudyProgressPdf(
            wordLists: wordLists,
            studentName: config.studentName ?? '학습자',
            startDate: config.studyStartDate ?? DateTime.now(),
            endDate: config.studyEndDate ?? DateTime.now().add(const Duration(days: 30)),
          );
          title = '${config.studentName ?? "학습자"} 진도표';
          break;
      }
      
      return PdfGenerationResult.success(
        pdfBytes: pdfBytes,
        title: title,
        type: PdfType.material,
      );
      
    } catch (e) {
      return PdfGenerationResult.error('교재 생성 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 시험지 생성 권한 검증
  ValidationResult _validateExamGeneration(ExamConfig config) {
    // 무료 사용자는 기본 시험지만 생성 가능
    if (_subscriptionService.isFree && config.isPremiumFeature) {
      return ValidationResult.invalid('프리미엄 시험지 기능은 구독자만 사용할 수 있습니다.');
    }
    
    // 무료 사용자는 프리미엄 기능 사용 불가
    if (!_subscriptionService.isPremium && config.requiresPremium) {
      return ValidationResult.invalid('이 기능은 프리미엄 구독자만 사용할 수 있습니다.');
    }
    
    return ValidationResult.valid();
  }
  
  /// 교재 생성 권한 검증
  ValidationResult _validateMaterialGeneration(MaterialConfig config) {
    // 무료 사용자는 기본 교재만 생성 가능
    if (_subscriptionService.isFree && config.requiresSubscription) {
      return ValidationResult.invalid('이 교재 기능은 구독자만 사용할 수 있습니다.');
    }
    
    // 프리미엄 전용 기능 체크
    if (!_subscriptionService.isPremium && config.requiresPremium) {
      return ValidationResult.invalid('이 기능은 프리미엄 구독자만 사용할 수 있습니다.');
    }
    
    return ValidationResult.valid();
  }
  
  /// 시험지 데이터 검증
  ValidationResult _validateExamData(List<WordListInfo> wordLists, List<Chunk> chunks, ExamConfig config) {
    if (wordLists.isEmpty) {
      return ValidationResult.invalid('최소 하나의 단어장을 선택해야 합니다.');
    }
    
    if (chunks.isEmpty) {
      return ValidationResult.invalid('시험 문제 생성을 위한 청크가 필요합니다.');
    }
    
    if (config.questionCount <= 0 || config.questionCount > 50) {
      return ValidationResult.invalid('문제 수는 1개 이상 50개 이하여야 합니다.');
    }
    
    if (config.enabledQuestionTypes.isEmpty) {
      return ValidationResult.invalid('최소 하나의 문제 유형을 선택해야 합니다.');
    }
    
    return ValidationResult.valid();
  }
  
  /// 교재 데이터 검증
  ValidationResult _validateMaterialData(List<WordListInfo> wordLists, MaterialConfig config) {
    if (wordLists.isEmpty) {
      return ValidationResult.invalid('최소 하나의 단어장을 선택해야 합니다.');
    }
    
    if (config.title.trim().isEmpty) {
      return ValidationResult.invalid('교재 제목을 입력해야 합니다.');
    }
    
    // 청크 컬렉션의 경우 청크 존재 여부 확인
    if (config.materialType == MaterialType.chunkCollection) {
      final hasChunks = wordLists.any((list) => (list.chunks?.isNotEmpty ?? false));
      if (!hasChunks) {
        return ValidationResult.invalid('청크 컬렉션 생성을 위한 청크가 필요합니다.');
      }
    }
    
    return ValidationResult.valid();
  }
  
  /// 시험지 제목 생성
  String _generateExamTitle(List<WordListInfo> wordLists, ExamConfig config) {
    if (wordLists.length == 1) {
      return '${wordLists.first.name} 시험지';
    } else {
      return '통합 시험지 (${wordLists.length}개 단어장)';
    }
  }
  
  /// 단어장에서 청크 추출
  List<Chunk> _extractChunksFromWordLists(List<WordListInfo> wordLists) {
    final chunks = <Chunk>[];
    for (final wordList in wordLists) {
      if (wordList.chunks != null) {
        chunks.addAll(wordList.chunks!);
      }
    }
    return chunks;
  }
}

/// 검증 결과 클래스
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  const ValidationResult._(this.isValid, this.errorMessage);
  
  factory ValidationResult.valid() => const ValidationResult._(true, null);
  factory ValidationResult.invalid(String message) => ValidationResult._(false, message);
}

/// PDF 생성 결과 클래스
class PdfGenerationResult {
  final bool isSuccess;
  final Uint8List? pdfBytes;
  final String? title;
  final PdfType? type;
  final String? errorMessage;
  
  const PdfGenerationResult._({
    required this.isSuccess,
    this.pdfBytes,
    this.title,
    this.type,
    this.errorMessage,
  });
  
  factory PdfGenerationResult.success({
    required Uint8List pdfBytes,
    required String title,
    required PdfType type,
  }) => PdfGenerationResult._(
    isSuccess: true,
    pdfBytes: pdfBytes,
    title: title,
    type: type,
  );
  
  factory PdfGenerationResult.error(String message) => PdfGenerationResult._(
    isSuccess: false,
    errorMessage: message,
  );
}

/// 교재 설정 클래스
class MaterialConfig {
  final String title;
  final MaterialType materialType;
  final bool includeChunks;
  final bool includeTranslations;
  final bool includeWordExplanations;
  final bool showWordNumbers;
  final String? studentName;
  final DateTime? studyStartDate;
  final DateTime? studyEndDate;
  
  const MaterialConfig({
    required this.title,
    required this.materialType,
    this.includeChunks = false,
    this.includeTranslations = true,
    this.includeWordExplanations = true,
    this.showWordNumbers = true,
    this.studentName,
    this.studyStartDate,
    this.studyEndDate,
  });
  
  bool get requiresSubscription {
    switch (materialType) {
      case MaterialType.wordList:
        return false; // 기본 단어장은 무료
      case MaterialType.chunkCollection:
      case MaterialType.studyProgress:
        return true; // 청크 컬렉션과 진도표는 구독 필요
    }
  }
  
  bool get requiresPremium {
    switch (materialType) {
      case MaterialType.studyProgress:
        return true; // 진도표는 프리미엄 전용
      default:
        return false;
    }
  }
}

/// 교재 타입 열거형
enum MaterialType {
  wordList,        // 단어장
  chunkCollection, // 청크 컬렉션
  studyProgress,   // 학습 진도표
}

/// PDF 타입 열거형
enum PdfType {
  exam,     // 시험지
  material, // 교재
}