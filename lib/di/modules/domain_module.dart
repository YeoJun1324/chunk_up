// lib/di/modules/domain_module.dart
import 'package:get_it/get_it.dart';

import 'package:chunk_up/domain/usecases/create_word_list_use_case.dart';
import 'package:chunk_up/domain/usecases/generate_chunk_use_case.dart';
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
import 'package:chunk_up/domain/repositories/chunk_repository_interface.dart';
import 'package:chunk_up/domain/services/api_service_interface.dart';
import 'package:chunk_up/domain/services/character/enhanced_character_service.dart';
import 'package:chunk_up/domain/services/prompt/prompt_builder_service.dart';
import 'package:chunk_up/domain/services/prompt/prompt_template_service.dart';
import 'package:chunk_up/data/services/subscription/subscription_service.dart';
import 'package:chunk_up/domain/services/content/response_parser_service.dart';

/// 도메인 모듈 - 비즈니스 로직 관련 유스케이스를 등록합니다.
class DomainModule {
  static Future<void> register(GetIt getIt) async {
    // 유스케이스
    getIt.registerLazySingleton<CreateWordListUseCase>(() => CreateWordListUseCase(
      wordListRepository: getIt<WordListRepositoryInterface>(),
    ));
    
    getIt.registerLazySingleton<GenerateChunkUseCase>(() => GenerateChunkUseCase(
      chunkRepository: getIt<ChunkRepositoryInterface>(),
      wordListRepository: getIt<WordListRepositoryInterface>(),
      apiService: getIt<ApiServiceInterface>(),
      characterService: getIt<EnhancedCharacterService>(),
      promptBuilder: getIt<PromptBuilderService>(),
      templateService: getIt<PromptTemplateService>(),
      subscriptionService: getIt<SubscriptionService>(),
      responseParser: getIt<ResponseParserService>(),
    ));
  }
}