// lib/domain/usecases/generate_chunk_use_case.dart
import 'dart:convert';
import 'dart:math';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/repositories/chunk_repository_interface.dart';
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
import 'package:chunk_up/core/services/api_service.dart';
import 'package:chunk_up/core/services/character_service.dart';
import 'package:chunk_up/core/utils/business_exception.dart';
import 'package:flutter/material.dart';

/// 청크 생성을 위한 파라미터 클래스
class GenerateChunkParams {
  final List<Word> selectedWords;
  final String wordListName;
  final String? character;
  final String? scenario;
  final String? details;
  final String? modelOverride;

  GenerateChunkParams({
    required this.selectedWords,
    required this.wordListName,
    this.character,
    this.scenario,
    this.details,
    this.modelOverride,
  });
}

class GenerateChunkUseCase {
  final ChunkRepositoryInterface chunkRepository;
  final WordListRepositoryInterface wordListRepository;
  final ApiService apiService;
  final CharacterService characterService;

  GenerateChunkUseCase({
    required this.chunkRepository,
    required this.wordListRepository,
    required this.apiService,
  }) : characterService = CharacterService(); // 싱글톤 패턴 사용

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
    final wordText = words.map((w) => w.english).join("\n");

    String prompt = """
I need to create an engaging educational passage for Korean language learners that uses all of these English words naturally:

$wordText

Requirements:
1. Create a natural, engaging paragraph that uses ALL the words correctly in context
2. Use EACH vocabulary word EXACTLY ONCE - do not repeat any word from the word list
3. Make the passage coherent and interesting
4. Control the length of the passage:
   - Keep it concise while maintaining natural flow and context
   - Don't sacrifice clarity or natural expression for brevity
   - Focus on quality over quantity
5. For the Korean translation:
   - Create a natural, native-sounding Korean translation
   - Focus on natural expression rather than literal translation
6. Return ONLY valid JSON with these fields:
   - title: A catchy title for the passage
   - englishContent: The English passage
   - koreanTranslation: Natural Korean version of the passage
   - wordExplanations: An object where keys are the English words and values are explanations of how each word is used
""";

    // Add character if provided
    if (params.character != null && params.character!.isNotEmpty) {
      // 캐릭터 세부 정보 가져오기
      try {
        final character = await characterService.getCharacterByName(params.character!);
        if (character != null) {
          prompt += """
FEATURE: Include a character named '${params.character}' in the story.
CHARACTER DETAILS:
- Source: ${character.source}
- Description: ${character.details}
 NOTE: Since this character comes from "${character.source}", you MUST maintain the writing style, tone,
         world-building elements, and setting details consistent with the original work. Pay careful attention to
         how characters speak, behave, and interact in that fictional universe.
""";
          debugPrint('📄 캐릭터 정보 추가됨: ${character.name}');
        } else {
          prompt += "\nFEATURE: Include a character named '${params.character}' in the story.";
          debugPrint('⚠️ 캐릭터 정보를 찾을 수 없음: ${params.character}');
        }
      } catch (e) {
        prompt += "\nFEATURE: Include a character named '${params.character}' in the story.";
        debugPrint('⚠️ 캐릭터 정보 검색 중 오류: $e');
      }
    }

    // Add scenario if provided
    if (params.scenario != null && params.scenario!.isNotEmpty) {
      prompt += "\nSCENARIO: ${params.scenario}";
    }

    // Add details if provided
    if (params.details != null && params.details!.isNotEmpty) {
      prompt += "\nADDITIONAL DETAILS: ${params.details}";
    }

    prompt += """

IMPORTANT:
1. Make the story reflect the character's personality, background, and source material
2. Use EACH vocabulary word EXACTLY ONCE in the English passage
3. Keep the passage concise but natural:
   - Aim for 3-5 sentences in both English and Korean versions
   - Prioritize conciseness without losing context or natural flow
   - Include only essential details to effectively use the vocabulary
   - Keep the total English word count to 70-120 words
4. For the Korean translation:
   - Create a natural, native-sounding Korean translation
   - Focus on natural expression rather than literal translation
5. Return ONLY valid JSON with this exact format:
{
  "title": "Story Title",
  "englishContent": "The story text...",
  "koreanTranslation": "자연스러운 한국어 표현...",
  "wordExplanations": {
    "word1": "단어1에 대한 한국어 설명: 이 단어는 문단에서 어떻게 사용되었는지, 어떤 의미로 사용되었는지 등",
    "word2": "단어2에 대한 한국어 설명: 이 단어는 문단에서 어떻게 사용되었는지, 어떤 의미로 사용되었는지 등"
  }
}
""";

    try {
      final apiResponse = await apiService.generateChunk(
        prompt,
        modelOverride: params.modelOverride
      );
      debugPrint('API Response received: ${apiResponse.toString().substring(0, min(100, apiResponse.toString().length))}...');

      // 데이터 형식 분석
      Map<String, dynamic> jsonData = {};

      try {
        // 1. Check if the response is already in the correct format with englishContent
        if (apiResponse is Map && (apiResponse.containsKey('englishContent') || apiResponse.containsKey('english_chunk'))) {
          jsonData = {
            'title': apiResponse['title'] ?? 'Generated Chunk',
            'englishContent': apiResponse['englishContent'] ?? apiResponse['english_chunk'] ?? '',
            'koreanTranslation': apiResponse['koreanTranslation'] ?? apiResponse['korean_translation'] ?? '',
            'wordExplanations': apiResponse['wordExplanations'] ?? {},
          };
        }
        // 2. Check Claude API format with content array
        else if (apiResponse is Map &&
                apiResponse.containsKey('content') &&
                apiResponse['content'] is List &&
                apiResponse['content'].isNotEmpty) {

          final String responseText = apiResponse['content'][0]['text'] ?? '';
          debugPrint('Response text (first 100 chars): ${responseText.substring(0, min(100, responseText.length))}...');

          // Try to extract JSON from the response text
          final jsonStart = responseText.indexOf('{');
          final jsonEnd = responseText.lastIndexOf('}');

          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonString = responseText.substring(jsonStart, jsonEnd + 1);
            final parsedJson = json.decode(jsonString) as Map<dynamic, dynamic>;

            // Convert keys to ensure they match our expected format
            jsonData = {
              'title': parsedJson['title'] ?? 'Generated Chunk',
              'englishContent': parsedJson['englishContent'] ?? '',
              'koreanTranslation': parsedJson['koreanTranslation'] ?? '',
              'wordExplanations': parsedJson['wordExplanations'] ?? {},
            };
          } else {
            debugPrint('Failed to extract JSON from response: ${responseText.substring(0, min(200, responseText.length))}...');
            throw BusinessException(
              type: BusinessErrorType.invalidPrompt,
              message: 'Failed to parse AI response - no JSON found',
            );
          }
        } else {
          debugPrint('Unexpected API response format: ${apiResponse.toString().substring(0, min(200, apiResponse.toString().length))}...');
          throw BusinessException(
            type: BusinessErrorType.invalidPrompt,
            message: 'Unexpected API response format',
          );
        }
      } catch (e) {
        debugPrint('JSON parsing error: $e');
        throw BusinessException(
          type: BusinessErrorType.dataFormatError,
          message: 'Failed to parse AI response',
        );
      }

      // 단어 설명을 소문자 키로 정규화하여 일관성 유지
      final Map<String, dynamic> originalExplanations = jsonData['wordExplanations'] ?? {};
      final Map<String, String> normalizedExplanations = {};

      // 모든 키를 소문자로 변환하여 저장
      originalExplanations.forEach((key, value) {
        if (key is String) {
          normalizedExplanations[key.toLowerCase()] = value.toString();
        }
      });

      // Create a new chunk
      final newChunk = Chunk(
        id: 'chunk_${params.wordListName}_${DateTime.now().millisecondsSinceEpoch}',
        title: jsonData['title'] ?? 'Generated Chunk',
        englishContent: jsonData['englishContent'] ?? 'Generated content',
        koreanTranslation: jsonData['koreanTranslation'] ?? '',
        includedWords: words,
        wordExplanations: normalizedExplanations,
        character: params.character,
        scenario: params.scenario,
        additionalDetails: params.details,
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