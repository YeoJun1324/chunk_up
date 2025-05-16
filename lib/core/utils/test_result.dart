// lib/core/utils/test_result.dart
import 'dart:convert';
import 'package:chunk_up/domain/models/word.dart';

/// 테스트 결과를 저장하는 데이터 모델
class TestResult {
  final String chunkTitle;
  final int totalQuestions;
  final int correctAnswers;
  final double accuracy;
  final List<String> incorrectWords;
  final Map<String, double> wordScores;
  final String testType;
  final Map<String, Map<String, dynamic>> detailedIncorrect;
  DateTime timestamp;
  int durationSeconds;

  TestResult({
    required this.chunkTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracy,
    required this.incorrectWords,
    required this.wordScores,
    required this.testType,
    Map<String, Map<String, dynamic>>? detailedIncorrect,
    this.durationSeconds = 0,
    DateTime? timestamp,
  }) :
        detailedIncorrect = detailedIncorrect ?? {},
        timestamp = timestamp ?? DateTime.now();

  /// 결과 데이터를 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'chunkTitle': chunkTitle,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'accuracy': accuracy,
      'incorrectWords': incorrectWords,
      'wordScores': wordScores,
      'testType': testType,
      'detailedIncorrect': _mapDetailedIncorrectToJson(),
      'durationSeconds': durationSeconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Map에서 결과 객체 생성
  factory TestResult.fromMap(Map<String, dynamic> map) {
    return TestResult(
      chunkTitle: map['chunkTitle'] ?? 'Unknown Chunk',
      totalQuestions: map['totalQuestions'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      accuracy: map['accuracy'] ?? 0.0,
      incorrectWords: List<String>.from(map['incorrectWords'] ?? []),
      wordScores: Map<String, double>.from(map['wordScores'] ?? {}),
      testType: map['testType'] ?? 'unknown',
      detailedIncorrect: _parseDetailedIncorrect(map['detailedIncorrect']),
      durationSeconds: map['durationSeconds'] ?? 0,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : null,
    );
  }

  /// 상세 오답 정보를 JSON 가능한 형태로 변환
  Map<String, dynamic> _mapDetailedIncorrectToJson() {
    Map<String, dynamic> result = {};

    detailedIncorrect.forEach((key, value) {
      result[key] = {
        'word': {
          'english': value['word'].english,
          'korean': value['word'].korean,
        },
        'userAnswer': value['userAnswer'],
        'correctAnswer': value['correctAnswer'],
        'explanation': value['explanation'],
      };
    });

    return result;
  }

  /// JSON에서 상세 오답 정보 파싱
  static Map<String, Map<String, dynamic>> _parseDetailedIncorrect(dynamic data) {
    if (data == null) return {};

    Map<String, Map<String, dynamic>> result = {};

    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map) {
          result[key.toString()] = {
            'word': Word(
              english: value['word']['english'] ?? '',
              korean: value['word']['korean'] ?? '',
            ),
            'userAnswer': value['userAnswer'] ?? '',
            'correctAnswer': value['correctAnswer'] ?? '',
            'explanation': value['explanation'] ?? '',
          };
        }
      });
    }

    return result;
  }

  /// JSON 문자열로 변환
  String toJson() => jsonEncode(toMap());

  /// JSON 문자열에서 결과 객체 생성
  factory TestResult.fromJson(String source) =>
      TestResult.fromMap(jsonDecode(source));

  /// 피드백 메시지 생성
  String getFeedbackMessage() {
    final percentage = accuracy;

    if (percentage >= 0.9) {
      return '훌륭해요! 완벽에 가까운 점수입니다.';
    } else if (percentage >= 0.7) {
      return '잘했어요! 대부분의 단어를 잘 알고 있네요.';
    } else if (percentage >= 0.5) {
      return '좋아요. 조금 더 학습이 필요합니다.';
    } else {
      return '더 많은 연습이 필요합니다. 다시 도전해보세요!';
    }
  }

  /// 소요 시간을 문자열로 반환
  String getDurationString() {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;

    if (minutes > 0) {
      return '$minutes분 $seconds초';
    } else {
      return '$seconds초';
    }
  }

  /// 결과 요약 문자열 반환
  @override
  String toString() {
    return 'TestResult(청크: $chunkTitle, 정확도: ${(accuracy * 100).toStringAsFixed(1)}%, 점수: $correctAnswers/$totalQuestions)';
  }

  /// 점수를 등급으로 변환 (A, B, C, D, F)
  String getGrade() {
    if (accuracy >= 0.9) return 'A';
    if (accuracy >= 0.8) return 'B';
    if (accuracy >= 0.7) return 'C';
    if (accuracy >= 0.6) return 'D';
    return 'F';
  }
}