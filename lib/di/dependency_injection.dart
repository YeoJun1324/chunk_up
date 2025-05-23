// lib/di/dependency_injection.dart
import 'package:get_it/get_it.dart';

import 'modules/core_module.dart';
import 'modules/data_module.dart';
import 'modules/domain_module.dart';
import 'modules/presentation_module.dart';

final getIt = GetIt.instance;

enum Environment { development, staging, production }

/// 의존성 주입 설정
Future<void> setupServiceLocator({Environment environment = Environment.development}) async {
  // 환경별 설정
  final envType = environment;
  
  // 각 모듈 등록
  await CoreModule.register(getIt);
  await DataModule.register(getIt);
  await DomainModule.register(getIt);
  await PresentationModule.register(getIt);
  
  // 환경별 API URL 설정
  if (environment == Environment.development) {
    // 개발 환경 설정
    getIt.registerLazySingleton<String>(() => 'https://api.anthropic.com', instanceName: 'baseUrl');
  } else if (environment == Environment.staging) {
    // 스테이징 환경 설정
    getIt.registerLazySingleton<String>(() => 'https://api.anthropic.com', instanceName: 'baseUrl');
  } else {
    // 프로덕션 환경 설정
    getIt.registerLazySingleton<String>(() => 'https://api.anthropic.com', instanceName: 'baseUrl');
  }
}

/// 서비스 로케이터 초기화
void resetServiceLocator() {
  getIt.reset();
}

/// 의존성 정리
Future<void> dispose() async {
  await getIt.reset(dispose: true);
}