import 'package:chunk_up/domain/models/exam_models.dart';

/// Helper class for distributing exam questions among different types
class ExamDistributionHelper {
  /// Distribute total question count among selected question types
  /// Handles cases where total doesn't divide evenly
  static Map<QuestionType, int> distributeQuestions({
    required int totalQuestions,
    required List<QuestionType> selectedTypes,
    Map<QuestionType, double>? weights,
  }) {
    if (selectedTypes.isEmpty || totalQuestions <= 0) {
      return {};
    }

    final distribution = <QuestionType, int>{};
    
    // If no weights provided, distribute evenly
    if (weights == null || weights.isEmpty) {
      return _distributeEvenly(totalQuestions, selectedTypes);
    }
    
    // Distribute according to weights
    return _distributeByWeights(totalQuestions, selectedTypes, weights);
  }

  /// Distribute questions evenly among types
  static Map<QuestionType, int> _distributeEvenly(
    int totalQuestions,
    List<QuestionType> types,
  ) {
    final distribution = <QuestionType, int>{};
    final baseCount = totalQuestions ~/ types.length;
    final remainder = totalQuestions % types.length;
    
    // Give each type the base count
    for (int i = 0; i < types.length; i++) {
      distribution[types[i]] = baseCount;
    }
    
    // Distribute remainder questions to first few types
    for (int i = 0; i < remainder; i++) {
      distribution[types[i]] = distribution[types[i]]! + 1;
    }
    
    return distribution;
  }

  /// Distribute questions according to weights
  static Map<QuestionType, int> _distributeByWeights(
    int totalQuestions,
    List<QuestionType> types,
    Map<QuestionType, double> weights,
  ) {
    final distribution = <QuestionType, int>{};
    
    // Calculate total weight for selected types
    double totalWeight = 0;
    for (final type in types) {
      totalWeight += weights[type] ?? 1.0;
    }
    
    // Distribute questions proportionally
    int distributedCount = 0;
    final sortedTypes = List<QuestionType>.from(types)
      ..sort((a, b) => (weights[b] ?? 1.0).compareTo(weights[a] ?? 1.0));
    
    for (int i = 0; i < sortedTypes.length; i++) {
      final type = sortedTypes[i];
      final weight = weights[type] ?? 1.0;
      
      if (i == sortedTypes.length - 1) {
        // Last type gets all remaining questions
        distribution[type] = totalQuestions - distributedCount;
      } else {
        // Calculate proportional count
        final count = (totalQuestions * weight / totalWeight).round();
        distribution[type] = count;
        distributedCount += count;
      }
    }
    
    // Ensure we don't exceed total questions
    _adjustDistribution(distribution, totalQuestions);
    
    return distribution;
  }

  /// Adjust distribution to match exact total
  static void _adjustDistribution(
    Map<QuestionType, int> distribution,
    int targetTotal,
  ) {
    final currentTotal = distribution.values.reduce((a, b) => a + b);
    
    if (currentTotal == targetTotal) return;
    
    // Sort types by current count (descending)
    final sortedTypes = distribution.keys.toList()
      ..sort((a, b) => distribution[b]!.compareTo(distribution[a]!));
    
    if (currentTotal > targetTotal) {
      // Need to reduce - take from types with most questions
      int toReduce = currentTotal - targetTotal;
      for (final type in sortedTypes) {
        if (toReduce == 0) break;
        final reduction = (distribution[type]! > 1) ? 1 : 0;
        distribution[type] = distribution[type]! - reduction;
        toReduce -= reduction;
      }
    } else {
      // Need to add - give to types with least questions
      int toAdd = targetTotal - currentTotal;
      final reversedTypes = sortedTypes.reversed.toList();
      for (final type in reversedTypes) {
        if (toAdd == 0) break;
        distribution[type] = distribution[type]! + 1;
        toAdd--;
      }
    }
  }

  /// Get recommended weights for question types
  static Map<QuestionType, double> getDefaultWeights() {
    return {
      QuestionType.fillInBlanks: 1.0,        // 33.3%
      QuestionType.contextMeaning: 1.0,      // 33.3%
      QuestionType.korToEngTranslation: 1.0, // 33.3%
    };
  }

  /// Validate if distribution is possible
  static bool canDistribute({
    required int totalQuestions,
    required int typeCount,
    int? minimumPerType,
  }) {
    final minPerType = minimumPerType ?? 1;
    return totalQuestions >= (typeCount * minPerType);
  }

  /// Get distribution summary as string
  static String getDistributionSummary(Map<QuestionType, int> distribution) {
    final buffer = StringBuffer();
    final total = distribution.values.reduce((a, b) => a + b);
    
    buffer.writeln('문제 분배 (총 $total문제):');
    for (final entry in distribution.entries) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      buffer.writeln('  ${_getTypeName(entry.key)}: ${entry.value}문제 ($percentage%)');
    }
    
    return buffer.toString();
  }

  static String _getTypeName(QuestionType type) {
    switch (type) {
      case QuestionType.fillInBlanks:
        return '단어 철자 쓰기';
      case QuestionType.contextMeaning:
        return '단어 용법 설명';
      case QuestionType.korToEngTranslation:
        return '문장 번역 (한→영)';
    }
  }
}