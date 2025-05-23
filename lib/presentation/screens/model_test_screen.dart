// lib/presentation/screens/model_test_screen.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/core/services/api_service.dart';
import 'package:chunk_up/core/services/subscription_service.dart';
import 'package:chunk_up/core/constants/subscription_constants.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

/// 모델 성능 테스트 화면
/// 무료(Claude 3 Haiku), Basic(Claude 3.5 Haiku)와 Premium(Claude 3.7 Sonnet) 모델의 성능을 비교합니다.
class ModelTestScreen extends StatefulWidget {
  const ModelTestScreen({super.key});

  @override
  State<ModelTestScreen> createState() => _ModelTestScreenState();
}

class _ModelTestScreenState extends State<ModelTestScreen> {
  final ApiService _apiService = GetIt.instance<ApiService>();
  final TextEditingController _promptController = TextEditingController();
  late SubscriptionService _subscriptionService;

  bool _isLoading = false;
  Map<String, dynamic>? _testResults;
  String _errorMessage = '';
  bool _canUseFeature = false;

  // 테스트 유형
  String _selectedTestType = 'custom'; // custom, words, passage
  
  // 미리 정의된 테스트 프롬프트
  final Map<String, String> _predefinedPrompts = {
    'words': """
Generate an engaging English passage using these words:

innovation
sustainable
comprehensive
authentic
versatile

Instructions:
- Make it a natural paragraph
- Use each word properly in context
- Create a natural, native-sounding Korean translation
- Return content as valid JSON with title, englishContent, and koreanTranslation fields
    """,
    
    'passage': """
I need to create an engaging educational passage for Korean language learners that uses all of these English words naturally:

ambitious
determination
resilient
opportunity
breakthrough

Requirements:
1. Create a natural, engaging paragraph that uses ALL the words correctly in context
2. Use EACH vocabulary word EXACTLY ONCE - do not repeat any word from the word list
3. Make the passage coherent and interesting
4. Create a natural, native-sounding Korean translation
5. Return ONLY valid JSON with these fields:
   - title: A catchy title for the passage
   - englishContent: The English passage
   - koreanTranslation: Natural Korean version of the passage
    """,
  };
  
  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
  
  // 프롬프트 테스트 실행
  Future<void> _runTest() async {
    // 무료 사용자 차단
    if (!_canUseFeature) {
      setState(() {
        _errorMessage = '';
      });
      
      // 구독 안내 다이얼로그 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('프리미엄 기능'),
          content: const Text('무료 기능에서는 지원하지 않습니다.\n프리미엄 구독 사용자만 모델 테스트 기능을 이용할 수 있습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/subscription');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('구독 플랜 보기'),
            ),
          ],
        ),
      );
      return;
    }

    if (_promptController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = '프롬프트를 입력해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _testResults = null;
    });

    try {
      final results = await _apiService.compareModels(_promptController.text);
      setState(() {
        _testResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '테스트 실패: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  // 테스트 타입 변경시 프롬프트 업데이트
  void _updateTestType(String type) {
    setState(() {
      _selectedTestType = type;
      if (type != 'custom') {
        _promptController.text = _predefinedPrompts[type] ?? '';
      } else {
        _promptController.text = '';
      }
    });
  }
  
  // 결과 복사하기
  void _copyResults() {
    if (_testResults != null) {
      final basicTime = _testResults!['basic']['response_time_ms'];
      final premiumTime = _testResults!['premium']['response_time_ms'];
      final timeDiff = (basicTime - premiumTime).abs();
      final fasterModel = basicTime < premiumTime ? 'Basic (Haiku)' : 'Premium (Sonnet)';
      
      final resultSummary = """
모델 성능 테스트 결과:
- Basic 모델 (${SubscriptionConstants.basicAiModel}): ${basicTime}ms (${(basicTime / 1000).toStringAsFixed(2)}초)
- Premium 모델 (${SubscriptionConstants.premiumAiModel}): ${premiumTime}ms (${(premiumTime / 1000).toStringAsFixed(2)}초)
- 속도 차이: ${timeDiff}ms (${(timeDiff / 1000).toStringAsFixed(2)}초)
- 더 빠른 모델: $fasterModel
      """;
      
      Clipboard.setData(ClipboardData(text: resultSummary));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결과가 클립보드에 복사되었습니다')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // 구독 상태 확인
    _checkSubscription();
  }

  void _checkSubscription() {
    try {
      if (GetIt.instance.isRegistered<SubscriptionService>()) {
        _subscriptionService = GetIt.instance<SubscriptionService>();
        _canUseFeature = _subscriptionService.canUseTestFeature;
        debugPrint('✅ 모델 테스트 화면: 기능 사용 가능 여부 = $_canUseFeature');
      } else {
        debugPrint('⚠️ SubscriptionService가 등록되어 있지 않음');
        _canUseFeature = false;
      }
    } catch (e) {
      debugPrint('❌ 구독 서비스 확인 실패: $e');
      _canUseFeature = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('모델 성능 테스트'),
        actions: [
          if (_testResults != null)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyResults,
              tooltip: '결과 복사하기',
            ),
        ],
      ),
      body: Column(
        children: [
          // 프리미엄 기능 알림 배너
          if (!_canUseFeature)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: isDarkMode ? Colors.amber.shade900 : Colors.amber.shade100,
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '이 기능은 프리미엄 사용자 전용입니다. 구독하고 모든 기능을 이용해보세요.',
                      style: TextStyle(
                        color: isDarkMode ? Colors.amber.shade100 : Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/subscription'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text(
                      '구독하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 테스트 유형 선택
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '테스트 유형',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('직접 입력'),
                                selected: _selectedTestType == 'custom',
                                onSelected: (selected) {
                                  if (selected) _updateTestType('custom');
                                },
                              ),
                              ChoiceChip(
                                label: const Text('단어 프롬프트'),
                                selected: _selectedTestType == 'words',
                                onSelected: (selected) {
                                  if (selected) _updateTestType('words');
                                },
                              ),
                              ChoiceChip(
                                label: const Text('문단 프롬프트'),
                                selected: _selectedTestType == 'passage',
                                onSelected: (selected) {
                                  if (selected) _updateTestType('passage');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 프롬프트 입력
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '프롬프트',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_promptController.text.isNotEmpty)
                                TextButton(
                                  onPressed: () => setState(() {
                                    _promptController.clear();
                                  }),
                                  child: const Text('지우기'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _promptController,
                            maxLines: 10,
                            decoration: const InputDecoration(
                              hintText: '테스트할 프롬프트를 입력하세요',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _runTest,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('테스트 실행'),
                            ),
                          ),
                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 테스트 결과
                  if (_testResults != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '테스트 결과',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // 기본 통계
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModelResultCard(
                                    'Basic (Haiku)',
                                    SubscriptionConstants.basicAiModel,
                                    _testResults!['basic']['response_time_ms'],
                                    Colors.blue.shade50,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildModelResultCard(
                                    'Premium (Sonnet)',
                                    SubscriptionConstants.premiumAiModel,
                                    _testResults!['premium']['response_time_ms'],
                                    Colors.purple.shade50,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // 속도 차이
                            _buildTimeDifferenceCard(),
                            
                            const SizedBox(height: 16),
                            
                            // 응답 비교 섹션
                            ExpansionTile(
                              title: const Text('응답 내용 비교'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Basic 모델 응답
                                      const Text(
                                        'Basic 모델 응답',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: _buildResponsePreview(_testResults!['basic']['result']),
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Premium 모델 응답
                                      const Text(
                                        'Premium 모델 응답',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: _buildResponsePreview(_testResults!['premium']['result']),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 모델 결과 카드 위젯
  Widget _buildModelResultCard(String name, String modelId, int responseTimeMs, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(modelId, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer, size: 16),
              const SizedBox(width: 4),
              Text(
                '${responseTimeMs}ms',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text('(${(responseTimeMs / 1000).toStringAsFixed(2)}초)'),
        ],
      ),
    );
  }
  
  // 시간 차이 카드 위젯
  Widget _buildTimeDifferenceCard() {
    final basicTime = _testResults!['basic']['response_time_ms'];
    final premiumTime = _testResults!['premium']['response_time_ms'];
    final timeDiff = (basicTime - premiumTime).abs();
    final fasterModel = basicTime < premiumTime 
        ? 'Basic (Haiku)' 
        : 'Premium (Sonnet)';
    final percentage = basicTime != 0 && premiumTime != 0
        ? ((basicTime - premiumTime).abs() / (basicTime > premiumTime ? basicTime : premiumTime) * 100).toStringAsFixed(1)
        : '0';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, size: 18),
              const SizedBox(width: 8),
              const Text(
                '성능 차이',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('시간 차이: ${timeDiff}ms (${(timeDiff / 1000).toStringAsFixed(2)}초)'),
          Text('속도 차이: $percentage% 차이'),
          Text('더 빠른 모델: $fasterModel', 
            style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  // API 응답 미리보기 위젯
  Widget _buildResponsePreview(Map<String, dynamic> response) {
    String preview = '';
    
    try {
      if (response.containsKey('content') && response['content'] is List && response['content'].isNotEmpty) {
        final content = response['content'][0]['text'];
        preview = content.substring(0, content.length > 300 ? 300 : content.length);
      } else {
        preview = response.toString().substring(0, response.toString().length > 300 ? 300 : response.toString().length);
      }
    } catch (e) {
      preview = '응답 형식 분석 실패: $e';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(preview),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: preview));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('응답이 클립보드에 복사되었습니다')),
              );
            },
            child: const Text('응답 복사'),
          ),
        ),
      ],
    );
  }
}