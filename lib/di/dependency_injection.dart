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
  final config = _getEnvironmentConfig(environment);
  
  // 환경별 설정 등록 (다른 서비스들이 사용할 수 있도록)
  getIt.registerLazySingleton<Environment>(() => environment, instanceName: 'environment');
  getIt.registerLazySingleton<Map<String, dynamic>>(() => config, instanceName: 'envConfig');
  
  // 각 모듈 등록
  await CoreModule.register(getIt);
  await DataModule.register(getIt);
  await DomainModule.register(getIt);
  await PresentationModule.register(getIt);
  
  // 환경별 API URL 설정
  getIt.registerLazySingleton<String>(() => config['apiUrl'], instanceName: 'baseUrl');
}

/// 환경별 설정 가져오기
Map<String, dynamic> _getEnvironmentConfig(Environment environment) {
  switch (environment) {
    case Environment.development:
      return {
        'apiUrl': 'https://api.anthropic.com',
        'enableLogging': true,
        'enableAnalytics': false,
        'cacheEnabled': true,
        'cacheTTL': 30 * 60 * 1000, // 30분
        'maxRetries': 3,
        'requestTimeout': 60000, // 60초
        'debugMode': true,
      };
    case Environment.staging:
      return {
        'apiUrl': 'https://api.anthropic.com',
        'enableLogging': true,
        'enableAnalytics': true,
        'cacheEnabled': true,
        'cacheTTL': 15 * 60 * 1000, // 15분
        'maxRetries': 2,
        'requestTimeout': 45000, // 45초
        'debugMode': false,
      };
    case Environment.production:
      return {
        'apiUrl': 'https://api.anthropic.com',
        'enableLogging': false,
        'enableAnalytics': true,
        'cacheEnabled': true,
        'cacheTTL': 60 * 60 * 1000, // 60분
        'maxRetries': 3,
        'requestTimeout': 30000, // 30초
        'debugMode': false,
      };
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