// lib/domain/usecases/test_word_use_case.dart
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/core/utils/test_manager.dart';
import 'package:chunk_up/core/utils/test_result.dart';
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
import 'package:chunk_up/domain/usecases/base_use_case.dart';

class TestWordParams {
  final List<Chunk> chunks;
  final TestType testType;

  TestWordParams({
    required this.chunks,
    required this.testType,
  });
}

class TestWordResult {
  final List<TestResult> results;
  final Map<String, List<Map<String, dynamic>>> incorrectWords;
  final int totalDuration;
  final double overallAccuracy;

  TestWordResult({
    required this.results,
    required this.incorrectWords,
    required this.totalDuration,
    required this.overallAccuracy,
  });
}

class TestWordUseCase extends UseCase<TestWordResult, TestWordParams> {
  final WordListRepositoryInterface _wordListRepository;

  TestWordUseCase({required WordListRepositoryInterface wordListRepository})
      : _wordListRepository = wordListRepository;

  @override
  Future<TestWordResult> call(TestWordParams params) async {
    final testManager = TestManager(
      chunks: params.chunks,
      testType: params.testType,
    );

    // 테스트 실행 (실제로는 UI에서 진행되므로 여기서는 결과만 처리)
    // 이 부분은 UI와 상호작용이 필요하므로 단순화

    final results = testManager.results;
    final incorrectWords = testManager.getAllIncorrectWords();
    final totalDuration = testManager.getTotalDuration();
    final overallAccuracy = testManager.getOverallAccuracy();

    // 테스트 결과 저장
    await _saveTestResults(results);

    return TestWordResult(
      results: results,
      incorrectWords: incorrectWords,
      totalDuration: totalDuration,
      overallAccuracy: overallAccuracy,
    );
  }

  Future<void> _saveTestResults(List<TestResult> results) async {
    // SharedPreferences에 결과 저장 로직
    // 여기서는 단순화하여 생략
  }
}