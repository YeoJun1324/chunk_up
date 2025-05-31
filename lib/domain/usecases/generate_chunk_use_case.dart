// lib/domain/usecases/generate_chunk_use_case.dart
import 'dart:convert';
import 'dart:math';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/repositories/chunk_repository_interface.dart';
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
import 'package:chunk_up/domain/services/api_service_interface.dart';
import 'package:chunk_up/domain/services/character/enhanced_character_service.dart';
import 'package:chunk_up/domain/models/character.dart' as enhanced_char;
import 'package:chunk_up/core/utils/business_exception.dart';
import 'package:chunk_up/data/services/subscription/subscription_service.dart';
import 'package:chunk_up/core/constants/prompt_templates.dart';
import 'package:chunk_up/core/constants/prompt_config.dart';
import 'package:chunk_up/domain/services/prompt/prompt_builder_service.dart';
import 'package:chunk_up/domain/services/prompt/prompt_template_service.dart';
import 'package:chunk_up/domain/services/content/response_parser_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// 청크 생성을 위한 파라미터 클래스
class GenerateChunkParams {
  final List<Word> selectedWords;
  final String wordListName;
  final List<String> character;
  final String? scenario;
  final String? details;
  final String? modelOverride;
  final OutputFormat outputFormat;
  final AdvancedSettings? advancedSettings;

  GenerateChunkParams({
    required this.selectedWords,
    required this.wordListName,
    this.character = const [],
    this.scenario,
    this.details,
    this.modelOverride,
    this.outputFormat = OutputFormat.narrative,
    this.advancedSettings,
  });
}

class GenerateChunkUseCase {
  final ChunkRepositoryInterface chunkRepository;
  final WordListRepositoryInterface wordListRepository;
  final ApiServiceInterface apiService;
  final EnhancedCharacterService characterService;
  final PromptBuilderService promptBuilder;
  final PromptTemplateService templateService;
  final SubscriptionService subscriptionService;
  final ResponseParserService responseParser;

  GenerateChunkUseCase({
    required this.chunkRepository,
    required this.wordListRepository,
    required this.apiService,
    required this.characterService,
    required this.promptBuilder,
    required this.templateService,
    required this.subscriptionService,
    required this.responseParser,
  });

  /// Execute with wordListId (legacy method)
  Future<List<Chunk>> execute(String wordListId, {String? modelOverride}) async {
    // Check if word list exists
    final wordList = await wordListRepository.getWordListById(wordListId);
    if (wordList == null) {
      throw BusinessException(
        type: BusinessErrorType.wordNotFound,
        message: 'Word list not found',
      );
    }

    return await chunkRepository.generateChunks(wordListId, modelOverride: modelOverride);
  }

  /// Call method for GenerateChunkParams
  Future<Chunk> call(GenerateChunkParams params) async {
    // Check if word list exists
    final wordList = await wordListRepository.getWordListById(params.wordListName);
    if (wordList == null) {
      throw BusinessException(
        type: BusinessErrorType.wordNotFound,
        message: 'Word list not found',
      );
    }

    // Prepare generation prompt
    final words = params.selectedWords;
    final wordStringList = words.map((w) => w.english).toList();

    // Calculate appropriate length based on word count
    final int wordCount = words.length;
    final int minLength;
    final int maxLength;
    
    if (wordCount <= 10) {
      minLength = 70;
      maxLength = 120;
    } else if (wordCount <= 15) {
      minLength = 100;
      maxLength = 150;
    } else if (wordCount <= 20) {
      minLength = 130;
      maxLength = 180;
    } else {
      minLength = 160;
      maxLength = 220;
    }

    // 캐릭터 정보 가져오기
    String? characterDescription;
    String? characterPersonality;
    String? characterSetting;
    List<String>? additionalCharacterNames;
    String? relationshipContext;
    
    // 의존성 주입된 캐릭터 서비스 사용
    
    if (params.character.isNotEmpty) {
      // Enhanced character service에서 캐릭터 정보 가져오기
      final characters = await characterService.getCharactersByNames(params.character);
      
      if (characters.isNotEmpty) {
        // 첫 번째 캐릭터를 메인 캐릭터로 설정
        final mainCharacter = characters.first;
        characterDescription = mainCharacter.description;
        characterPersonality = mainCharacter.personality;
        characterSetting = mainCharacter.seriesName;
        
        // 여러 캐릭터가 선택된 경우
        if (characters.length > 1) {
          additionalCharacterNames = params.character.sublist(1);
          
          // 모든 캐릭터 정보를 수집
          final characterContexts = <String>[];
          for (final character in characters) {
            characterContexts.add(characterService.buildCharacterContext(character));
          }
          
          // 캐릭터 간 관계 정보 수집
          final relationshipContexts = <String>[];
          for (int i = 0; i < characters.length - 1; i++) {
            for (int j = i + 1; j < characters.length; j++) {
              final relationship = await characterService.getRelationship(
                characters[i].id,
                characters[j].id,
              );
              
              if (relationship != null) {
                relationshipContexts.add(
                  characterService.buildRelationshipContext(
                    characters[i].name,
                    characters[j].name,
                    relationship,
                  )
                );
              }
            }
          }
          
          // 관계 컨텍스트 결합
          if (characterContexts.isNotEmpty || relationshipContexts.isNotEmpty) {
            relationshipContext = characterContexts.join('') + relationshipContexts.join('');
          }
        }
        
        debugPrint('📄 Enhanced 캐릭터 정보 추가됨: ${characters.map((c) => c.name).join(", ")}');
      }
    }

    // 의존성 주입된 프롬프트 빌더 서비스 사용
    final prompt = promptBuilder.buildPrompt(
      words: wordStringList,
      outputFormat: params.outputFormat,
      minLength: minLength,
      maxLength: maxLength,
      characterName: params.character.isNotEmpty ? params.character.first : null,
      characterDescription: characterDescription,
      characterPersonality: characterPersonality,
      characterSetting: characterSetting,
      scenario: params.scenario ?? params.details, // 기존 details를 scenario로 사용
      advancedSettings: params.advancedSettings,
      additionalCharacterNames: additionalCharacterNames,
      relationshipContext: relationshipContext,
    );
    
    // 프롬프트 디버깅 출력
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔍 최종 생성된 프롬프트:');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint(prompt);
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📝 프롬프트 길이: ${prompt.length}자');
    debugPrint('📝 선택된 단어: ${wordStringList.join(', ')}');
    debugPrint('📝 출력 형식: ${params.outputFormat.name}');
    if (params.character.isNotEmpty) {
      debugPrint('📝 캐릭터: ${params.character.join(", ")}');
    }
    if (params.scenario != null && params.scenario!.isNotEmpty) {
      debugPrint('📝 시나리오: ${params.scenario}');
    }
    if (params.advancedSettings != null) {
      debugPrint('📝 고급 설정:');
      if (params.advancedSettings!.customTimePoint != null) {
        debugPrint('  - 시점: ${params.advancedSettings!.customTimePoint}');
      }
      if (params.advancedSettings!.emotionalState != null) {
        debugPrint('  - 감정: ${params.advancedSettings!.emotionalState!.name}');
      }
      if (params.advancedSettings!.tone != null) {
        debugPrint('  - 톤: ${params.advancedSettings!.tone!.name}');
      }
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // 프롬프트 품질 분석 (디버깅용)
    final quality = promptBuilder.analyzePromptQuality(
      prompt: prompt,
      words: wordStringList,
      scenario: params.scenario,
    );
    debugPrint('📊 Prompt quality: ${quality['qualityGrade']} (${quality['qualityScore']}/100)');
    
    // 프롬프트 히스토리 저장
    final history = PromptHistory(
      id: 'history_${DateTime.now().millisecondsSinceEpoch}',
      promptTemplateId: 'default', // 나중에 실제 템플릿 ID 사용
      generatedPrompt: prompt,
      words: wordStringList,
      characterName: params.character.isNotEmpty ? params.character.join(", ") : null,
      scenario: params.scenario,
      settings: {
        'outputFormat': params.outputFormat.name,
        'advancedSettings': params.advancedSettings?.toContextString() ?? '',
      },
      createdAt: DateTime.now(),
      qualityScore: quality['qualityScore'] ?? 0,
    );
    await templateService.savePromptHistory(history);

    try {
      // 사용할 모델 결정
      String actualModel;
      if (params.modelOverride != null) {
        actualModel = params.modelOverride!;
        debugPrint('🤖 명시적으로 지정된 모델 사용: $actualModel');
      } else {
        // 구독 상태에 따라 모델 결정
        actualModel = subscriptionService.getCurrentModel();
        debugPrint('🤖 구독 기반 모델 사용: $actualModel');
      }

      debugPrint('🚀 API 호출 시작 - 모델: $actualModel');
      final apiResponse = await apiService.generateChunk(
        prompt,
        modelOverride: actualModel
      );
      
      // API 응답 디버깅
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ API 응답 수신 완료');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('API Response received: ${apiResponse.toString().substring(0, min(100, apiResponse.toString().length))}...');

      // 응답 파싱 서비스 사용
      final jsonData = responseParser.parseApiResponse(apiResponse);

      // JSON 파싱 성공 디버깅
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📋 파싱된 JSON 데이터:');
      debugPrint('  - 제목: ${jsonData['title']}');
      debugPrint('  - 영어 내용 길이: ${jsonData['englishContent']?.toString().length ?? 0}자');
      debugPrint('  - 한국어 번역 길이: ${jsonData['koreanTranslation']?.toString().length ?? 0}자');
      debugPrint('  - 단어 설명 개수: ${(jsonData['wordExplanations'] as Map?)?.length ?? 0}개');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // 응답 파싱 서비스를 사용한 정규화
      final normalizedExplanations = responseParser.normalizeWordExplanations(
        jsonData['wordExplanations'] ?? {}
      );
      final wordMappings = responseParser.normalizeWordMappings(
        jsonData['wordMappings']
      );

      // Create a new chunk
      final newChunk = Chunk(
        id: 'chunk_${params.wordListName}_${DateTime.now().millisecondsSinceEpoch}',
        title: jsonData['title'] ?? 'Generated Chunk',
        englishContent: jsonData['englishContent'] ?? 'Generated content',
        koreanTranslation: jsonData['koreanTranslation'] ?? '',
        includedWords: words,
        wordExplanations: normalizedExplanations,
        wordMappings: wordMappings,
        character: params.character,
        scenario: params.scenario,
        additionalDetails: params.details,
        usedModel: actualModel, // 실제 사용된 모델 정보 저장
      );

      // Save the chunk
      await chunkRepository.saveChunk(newChunk);

      return newChunk;
    } catch (e) {
      if (e is BusinessException) {
        rethrow;
      }
      throw BusinessException(
        type: BusinessErrorType.chunkGenerationFailed,
        message: 'Failed to generate chunk: ${e.toString()}',
      );
    }
  }
}