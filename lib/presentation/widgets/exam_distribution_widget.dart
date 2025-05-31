import 'package:flutter/material.dart';
import 'package:chunk_up/domain/models/exam_models.dart';
import 'package:chunk_up/domain/services/exam/exam_distribution_helper.dart';
import 'safe_state_mixin.dart';

/// Widget for setting exam question distribution
class ExamDistributionWidget extends StatefulWidget {
  final int totalQuestions;
  final List<QuestionType> availableTypes;
  final Function(Map<QuestionType, int>) onDistributionChanged;
  
  const ExamDistributionWidget({
    Key? key,
    required this.totalQuestions,
    required this.availableTypes,
    required this.onDistributionChanged,
  }) : super(key: key);

  @override
  State<ExamDistributionWidget> createState() => _ExamDistributionWidgetState();
}

class _ExamDistributionWidgetState extends State<ExamDistributionWidget> 
    with SafeStateMixin {
  late List<QuestionType> _selectedTypes;
  late Map<QuestionType, int> _distribution;
  final Map<QuestionType, TextEditingController> _controllers = {};
  bool _useAutoDistribution = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _selectedTypes = List.from(widget.availableTypes);
    _distribution = {};
    _updateDistribution();
  }

  @override
  void dispose() {
    _mounted = false;
    
    // Focus 해제
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
    
    // 모든 TextEditingController 정리
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    
    super.dispose();
  }

  @override
  void didUpdateWidget(ExamDistributionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalQuestions != widget.totalQuestions) {
      _updateDistribution();
    }
  }

  void _updateDistribution() {
    if (!_mounted) return;
    
    if (_useAutoDistribution && _selectedTypes.isNotEmpty) {
      _distribution = ExamDistributionHelper.distributeQuestions(
        totalQuestions: widget.totalQuestions,
        selectedTypes: _selectedTypes,
        weights: ExamDistributionHelper.getDefaultWeights(),
      );
      
      // 컨트롤러 텍스트 업데이트
      for (final entry in _distribution.entries) {
        if (_controllers.containsKey(entry.key)) {
          _controllers[entry.key]!.text = entry.value.toString();
        }
      }
    } else {
      // Manual distribution - ensure total matches
      _adjustManualDistribution();
    }
    
    if (_mounted) {
      widget.onDistributionChanged(_distribution);
    }
  }

  void _adjustManualDistribution() {
    final currentTotal = _distribution.values.fold<int>(0, (sum, count) => sum + count);
    
    if (currentTotal != widget.totalQuestions) {
      // Adjust the first type's count to match total
      if (_selectedTypes.isNotEmpty) {
        final firstType = _selectedTypes.first;
        final adjustment = widget.totalQuestions - currentTotal;
        _distribution[firstType] = (_distribution[firstType] ?? 0) + adjustment;
        
        // Ensure non-negative
        if (_distribution[firstType]! < 0) {
          _distribution[firstType] = 0;
        }
        
        // 컨트롤러 텍스트 업데이트
        if (_controllers.containsKey(firstType)) {
          _controllers[firstType]!.text = _distribution[firstType].toString();
        }
      }
    }
  }

  TextEditingController _getController(QuestionType type) {
    if (!_controllers.containsKey(type)) {
      final count = _distribution[type] ?? 0;
      _controllers[type] = TextEditingController(text: count.toString());
    }
    return _controllers[type]!;
  }

  @override
  Widget build(BuildContext context) {
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '문제 유형 분배',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '총 ${widget.totalQuestions}문제',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Auto/Manual toggle
            SwitchListTile(
              title: const Text('자동 분배'),
              subtitle: const Text('문제를 자동으로 균등 분배합니다'),
              value: _useAutoDistribution,
              onChanged: (value) {
                safeSetState(() {
                  _useAutoDistribution = value;
                  _updateDistribution();
                });
              },
            ),
            
            const Divider(),
            
            // Question type selection and distribution
            ...widget.availableTypes.map((type) => _buildTypeRow(type)),
            
            const Divider(),
            
            // Distribution summary
            if (_distribution.isNotEmpty) _buildSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeRow(QuestionType type) {
    final isSelected = _selectedTypes.contains(type);
    final count = _distribution[type] ?? 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Checkbox for selection
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              safeSetState(() {
                if (value == true) {
                  _selectedTypes.add(type);
                } else {
                  _selectedTypes.remove(type);
                  _distribution.remove(type);
                  // 컨트롤러 정리
                  _controllers[type]?.dispose();
                  _controllers.remove(type);
                }
                _updateDistribution();
              });
            },
          ),
          
          // Type name
          Expanded(
            child: Text(
              _getTypeName(type),
              style: TextStyle(
                color: isSelected ? null : Colors.grey,
              ),
            ),
          ),
          
          // Question count
          if (isSelected) ...[
            if (_useAutoDistribution) 
              Text(
                '$count문제',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            else
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _getController(type),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8, 
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final newCount = int.tryParse(value) ?? 0;
                    safeSetState(() {
                      _distribution[type] = newCount;
                      _adjustManualDistribution();
                      widget.onDistributionChanged(_distribution);
                    });
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final totalDistributed = _distribution.values.fold<int>(0, (sum, count) => sum + count);
    final isValid = totalDistributed == widget.totalQuestions;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: isValid ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '분배된 문제: $totalDistributed / ${widget.totalQuestions}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isValid ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          if (!isValid && !_useAutoDistribution) ...[
            const SizedBox(height: 8),
            Text(
              '수동 분배 시 총 문제 수가 일치해야 합니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTypeName(QuestionType type) {
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