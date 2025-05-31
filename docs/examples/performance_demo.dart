// performance_demo.dart - 성능 개선 데모 스크립트

import 'dart:io';
import 'lib/core/services/sentence/unified_sentence_mapping_service.dart';
import 'lib/domain/models/chunk.dart';
import 'lib/domain/models/word.dart';

/// 성능 개선 효과를 실시간으로 확인할 수 있는 데모
Future<void> main() async {
  print('🚀 ChunkUp 성능 개선 데모 시작');
  print('=' * 50);

  // 테스트 데이터 준비
  final testChunk = Chunk(
    id: 'demo_chunk',
    title: 'Performance Demo Chunk',
    englishContent: '''
      Sherlock Holmes will investigate this comprehensive case.||| The detective needs to demonstrate his innovative approach.||| Watson observed the magnificent evidence carefully.||| The investigation was thorough and systematic.|||
    ''',
    koreanTranslation: '''
      셜록 홈즈는 이 포괄적인 사건을 조사할 것입니다.||| 형사는 혁신적인 접근법을 증명해야 합니다.||| 왓슨은 웅장한 증거를 신중히 관찰했습니다.||| 조사는 철저하고 체계적이었습니다.|||
    ''',
    includedWords: [
      Word(english: 'investigate', korean: '조사하다'),
      Word(english: 'comprehensive', korean: '포괄적인'),
      Word(english: 'demonstrate', korean: '증명하다'),
      Word(english: 'innovative', korean: '혁신적인'),
      Word(english: 'magnificent', korean: '웅장한'),
    ],
    createdAt: DateTime.now(),
  );

  // 개선된 서비스 인스턴스 생성
  final optimizedService = UnifiedSentenceMappingService(
    maxCacheSize: 100,
    onError: (msg) => print('❌ Error: $msg'),
    onWarning: (msg) => print('⚠️ Warning: $msg'),
  );

  print('📊 성능 테스트 시작...\n');

  // 1. 첫 번째 실행 (캐시 미스)
  final stopwatch1 = Stopwatch()..start();
  final pairs1 = optimizedService.extractSentencePairs(testChunk, enableDebug: true);
  stopwatch1.stop();

  print('🔹 첫 번째 실행 (캐시 미스):');
  print('   - 실행 시간: ${stopwatch1.elapsedMicroseconds}μs');
  print('   - 문장 쌍 개수: ${pairs1.length}');
  print('   - 캐시 상태: ${optimizedService.isCached(testChunk.id) ? 'CACHED' : 'NOT CACHED'}');

  // 2. 두 번째 실행 (캐시 히트)
  final stopwatch2 = Stopwatch()..start();
  final pairs2 = optimizedService.extractSentencePairs(testChunk, enableDebug: true);
  stopwatch2.stop();

  print('\n🔹 두 번째 실행 (캐시 히트):');
  print('   - 실행 시간: ${stopwatch2.elapsedMicroseconds}μs');
  print('   - 문장 쌍 개수: ${pairs2.length}');
  print('   - 성능 향상: ${((stopwatch1.elapsedMicroseconds - stopwatch2.elapsedMicroseconds) / stopwatch1.elapsedMicroseconds * 100).toStringAsFixed(1)}%');

  // 3. 매핑 품질 분석
  print('\n📈 매핑 품질 분석:');
  final qualityReport = optimizedService.analyzeMappingQuality(testChunk);
  print('   - 품질 점수: ${(qualityReport.score * 100).toStringAsFixed(1)}%');
  print('   - 총 문장 쌍: ${qualityReport.totalPairs}');
  print('   - 품질 등급: ${qualityReport.isGood ? '우수' : qualityReport.isAcceptable ? '양호' : '개선 필요'}');
  
  if (qualityReport.issues.isNotEmpty) {
    print('   - 발견된 이슈:');
    for (final issue in qualityReport.issues) {
      print('     • $issue');
    }
  }

  // 4. 메모리 사용량 테스트
  print('\n🧠 메모리 관리 테스트:');
  print('   - 현재 캐시 크기: ${optimizedService.getCacheSize()}');
  
  // 여러 청크로 캐시 크기 테스트
  for (int i = 0; i < 5; i++) {
    final testChunkCopy = Chunk(
      id: 'demo_chunk_$i',
      title: 'Test Chunk $i',
      englishContent: testChunk.englishContent,
      koreanTranslation: testChunk.koreanTranslation,
      includedWords: testChunk.includedWords,
      createdAt: DateTime.now(),
    );
    optimizedService.extractSentencePairs(testChunkCopy);
  }
  
  print('   - 추가 청크 처리 후 캐시 크기: ${optimizedService.getCacheSize()}');

  // 5. 구분자 정규화 테스트
  print('\n🔧 구분자 정규화 테스트:');
  final problematicContent = 'First sentence.|||Second sentence.|||Third sentence.|||';
  final testChunkWithIssues = Chunk(
    id: 'delimiter_test',
    title: 'Delimiter Test',
    englishContent: problematicContent,
    koreanTranslation: '첫 번째 문장.|||두 번째 문장.|||세 번째 문장.|||',
    includedWords: [Word(english: 'test', korean: '테스트')],
    createdAt: DateTime.now(),
  );

  final delimiterPairs = optimizedService.extractSentencePairs(testChunkWithIssues);
  print('   - 입력: "$problematicContent"');
  print('   - 파싱된 문장 수: ${delimiterPairs.length}');
  print('   - 구분자 처리: ${delimiterPairs.isNotEmpty ? '성공' : '실패'}');

  // 6. 종합 성능 보고서
  print('\n📋 종합 성능 보고서:');
  print('   ✅ LRU 캐시로 메모리 사용량 제한');
  print('   ✅ 정적 RegExp 패턴으로 성능 최적화');
  print('   ✅ 구분자 정규화로 일관성 보장');
  print('   ✅ 매핑 품질 분석 기능 제공');
  print('   ✅ 체계적인 에러 처리 및 로깅');

  final improvementPercentage = stopwatch1.elapsedMicroseconds > 0 
    ? ((stopwatch1.elapsedMicroseconds - stopwatch2.elapsedMicroseconds) / stopwatch1.elapsedMicroseconds * 100)
    : 0.0;

  print('\n🎯 예상 성능 향상:');
  print('   - 캐시 히트 시: ${improvementPercentage.toStringAsFixed(1)}% 빠름');
  print('   - 메모리 사용량: 안정적 (최대 100개 엔트리)');
  print('   - 에러 처리: 완전 (로깅 포함)');

  print('\n🎉 성능 개선 데모 완료!');
  print('=' * 50);
}

/// 간단한 사용 예제
void demonstrateUsage() {
  print('''

📖 사용 방법:

1. 기존 코드:
   final mappingService = UnifiedSentenceMappingService();

2. 개선된 코드:
   final mappingService = UnifiedSentenceMappingService(
     maxCacheSize: 100,
     onError: (msg) => logger.error(msg),
     onWarning: (msg) => logger.warning(msg),
   );

3. 품질 분석:
   final report = mappingService.analyzeMappingQuality(chunk);
   if (report.isGood) {
     print('매핑 품질이 우수합니다!');
   }

4. 캐시 관리:
   mappingService.clearCacheForChunk(chunkId);
   mappingService.clearCache(); // 전체 캐시 클리어

''');
}