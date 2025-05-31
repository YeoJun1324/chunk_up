// lib/core/services/exam_service_setup.dart
import 'package:get_it/get_it.dart';
import '../../../data/services/pdf/pdf_coordinator.dart';
import 'unified_exam_generator.dart';
import '../../../data/services/subscription/subscription_service.dart';

/// 시험지 관련 서비스들을 의존성 주입에 등록
class ExamServiceSetup {
  static void registerServices(GetIt getIt) {
    // PDF 코디네이터 등록
    getIt.registerLazySingleton<PdfCoordinator>(() => PdfCoordinator(
      getIt<SubscriptionService>(),
    ));
    
    // 문제 생성기 등록
    getIt.registerLazySingleton<UnifiedExamGenerator>(() => UnifiedExamGenerator());
  }

  static void unregisterServices(GetIt getIt) {
    if (getIt.isRegistered<PdfCoordinator>()) {
      getIt.unregister<PdfCoordinator>();
    }
    
    if (getIt.isRegistered<UnifiedExamGenerator>()) {
      getIt.unregister<UnifiedExamGenerator>();
    }
  }
}