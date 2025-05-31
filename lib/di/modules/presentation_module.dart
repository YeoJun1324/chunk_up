// lib/di/modules/presentation_module.dart
import 'package:get_it/get_it.dart';

import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/presentation/providers/folder_notifier.dart';
import 'package:chunk_up/presentation/providers/theme_notifier.dart';
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
import 'package:chunk_up/domain/repositories/chunk_repository_interface.dart';
import 'package:chunk_up/domain/usecases/create_word_list_use_case.dart';

/// 프레젠테이션 모듈 - UI 관련 상태 관리 객체를 등록합니다.
class PresentationModule {
  static Future<void> register(GetIt getIt) async {
    // 프로바이더 - 싱글톤으로 변경
    getIt.registerLazySingleton<WordListNotifier>(() => WordListNotifier(
      wordListRepository: getIt<WordListRepositoryInterface>(),
      chunkRepository: getIt<ChunkRepositoryInterface>(),
      createWordListUseCase: getIt<CreateWordListUseCase>(),
    ));
    
    getIt.registerLazySingleton<FolderNotifier>(() => FolderNotifier());
    getIt.registerLazySingleton<ThemeNotifier>(() => ThemeNotifier());
  }
}