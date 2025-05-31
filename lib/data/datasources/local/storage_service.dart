// lib/data/datasources/local/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/core/constants/app_constants.dart';

class StorageService {
  static const String _wordListsKey = AppConstants.wordListsStorageKey;

  // Save all word lists to shared preferences
  static Future<bool> saveWordLists(List<WordListInfo> wordLists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String wordListsJson = jsonEncode(
          wordLists.map((list) => list.toJson()).toList()
      );

      return await prefs.setString(_wordListsKey, wordListsJson);
    } catch (e) {
      print('Error saving word lists: $e');
      return false;
    }
  }

  // Load all word lists from shared preferences
  static Future<List<WordListInfo>> loadWordLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? wordListsJson = prefs.getString(_wordListsKey);

      if (wordListsJson == null || wordListsJson.isEmpty) {
        return _getInitialWordLists(); // Return initial data if nothing is saved
      }

      final List<dynamic> decoded = jsonDecode(wordListsJson);
      return decoded.map((json) => WordListInfo.fromJson(json)).toList();
    } catch (e) {
      print('Error loading word lists: $e');
      return _getInitialWordLists(); // Return initial data on error
    }
  }

  // Clear all saved data (for testing/reset purposes)
  static Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }

  // Initial data to use when the app is first launched
  static List<WordListInfo> _getInitialWordLists() {
    return [
      WordListInfo(
        name: '수능 영단어',
        words: [
          // Essential Academic Vocabulary (1-50)
          Word(english: 'abandon', korean: '버리다, 포기하다'),
          Word(english: 'abolish', korean: '폐지하다'),
          Word(english: 'abstract', korean: '추상적인'),
          Word(english: 'abundant', korean: '풍부한'),
          Word(english: 'accelerate', korean: '가속하다'),
          Word(english: 'accompany', korean: '동반하다'),
          Word(english: 'accomplish', korean: '성취하다'),
          Word(english: 'accumulate', korean: '축적하다'),
          Word(english: 'accurate', korean: '정확한'),
          Word(english: 'acknowledge', korean: '인정하다'),
          Word(english: 'acquire', korean: '획득하다'),
          Word(english: 'adapt', korean: '적응하다'),
          Word(english: 'adequate', korean: '적절한'),
          Word(english: 'adjacent', korean: '인접한'),
          Word(english: 'adjust', korean: '조정하다'),
          Word(english: 'advocate', korean: '옹호하다'),
          Word(english: 'affect', korean: '영향을 미치다'),
          Word(english: 'aggregate', korean: '합계의, 집합의'),
          Word(english: 'allocate', korean: '할당하다'),
          Word(english: 'alternative', korean: '대안의'),
          Word(english: 'ambiguous', korean: '모호한'),
          Word(english: 'amend', korean: '수정하다'),
          Word(english: 'analogy', korean: '유추, 비유'),
          Word(english: 'analyze', korean: '분석하다'),
          Word(english: 'anticipate', korean: '예상하다'),
          Word(english: 'apparent', korean: '명백한'),
          Word(english: 'approach', korean: '접근하다'),
          Word(english: 'appropriate', korean: '적절한'),
          Word(english: 'approximate', korean: '대략적인'),
          Word(english: 'arbitrary', korean: '임의의'),
          Word(english: 'aspect', korean: '측면'),
          Word(english: 'assemble', korean: '모으다'),
          Word(english: 'assess', korean: '평가하다'),
          Word(english: 'assign', korean: '할당하다'),
          Word(english: 'assume', korean: '가정하다'),
          Word(english: 'assure', korean: '보장하다'),
          Word(english: 'attain', korean: '달성하다'),
          Word(english: 'attribute', korean: '속성; ~탓으로 하다'),
          Word(english: 'authentic', korean: '진짜의'),
          Word(english: 'authority', korean: '권위, 권한'),
          Word(english: 'available', korean: '이용 가능한'),
          Word(english: 'bias', korean: '편견'),
          Word(english: 'brief', korean: '간단한'),
          Word(english: 'bulk', korean: '대량, 부피'),
          Word(english: 'capable', korean: '~할 수 있는'),
          Word(english: 'capacity', korean: '용량, 능력'),
          Word(english: 'category', korean: '범주'),
          Word(english: 'cease', korean: '중단하다'),
          Word(english: 'challenge', korean: '도전'),
          Word(english: 'circumstance', korean: '상황'),
          
          // Common Reading Comprehension Words (51-100)
          Word(english: 'clarify', korean: '명확히 하다'),
          Word(english: 'coincide', korean: '일치하다'),
          Word(english: 'collapse', korean: '붕괴하다'),
          Word(english: 'colleague', korean: '동료'),
          Word(english: 'commence', korean: '시작하다'),
          Word(english: 'comment', korean: '논평하다'),
          Word(english: 'commit', korean: '전념하다'),
          Word(english: 'commodity', korean: '상품'),
          Word(english: 'communicate', korean: '의사소통하다'),
          Word(english: 'community', korean: '공동체'),
          Word(english: 'compatible', korean: '호환되는'),
          Word(english: 'compensate', korean: '보상하다'),
          Word(english: 'compile', korean: '편집하다'),
          Word(english: 'complement', korean: '보완하다'),
          Word(english: 'complex', korean: '복잡한'),
          Word(english: 'component', korean: '구성요소'),
          Word(english: 'compound', korean: '혼합물; 복합의'),
          Word(english: 'comprehensive', korean: '포괄적인'),
          Word(english: 'comprise', korean: '구성하다'),
          Word(english: 'compute', korean: '계산하다'),
          Word(english: 'conceive', korean: '생각하다, 임신하다'),
          Word(english: 'concentrate', korean: '집중하다'),
          Word(english: 'concept', korean: '개념'),
          Word(english: 'conclude', korean: '결론짓다'),
          Word(english: 'concurrent', korean: '동시의'),
          Word(english: 'conduct', korean: '수행하다'),
          Word(english: 'confer', korean: '수여하다'),
          Word(english: 'confine', korean: '제한하다'),
          Word(english: 'confirm', korean: '확인하다'),
          Word(english: 'conflict', korean: '갈등'),
          Word(english: 'conform', korean: '순응하다'),
          Word(english: 'consent', korean: '동의'),
          Word(english: 'consequent', korean: '결과적인'),
          Word(english: 'considerable', korean: '상당한'),
          Word(english: 'consist', korean: '구성되다'),
          Word(english: 'constant', korean: '지속적인'),
          Word(english: 'constitute', korean: '구성하다'),
          Word(english: 'constrain', korean: '제약하다'),
          Word(english: 'construct', korean: '건설하다'),
          Word(english: 'consult', korean: '상담하다'),
          Word(english: 'consume', korean: '소비하다'),
          Word(english: 'contact', korean: '접촉'),
          Word(english: 'contemporary', korean: '현대의'),
          Word(english: 'context', korean: '맥락'),
          Word(english: 'contract', korean: '계약; 수축하다'),
          Word(english: 'contradict', korean: '모순되다'),
          Word(english: 'contrary', korean: '반대의'),
          Word(english: 'contrast', korean: '대조'),
          Word(english: 'contribute', korean: '기여하다'),
          Word(english: 'controversial', korean: '논란이 많은'),
          
          // Important Phrasal Verbs and Idioms (101-150)
          Word(english: 'bring about', korean: '초래하다, 야기하다'),
          Word(english: 'carry out', korean: '수행하다'),
          Word(english: 'come across', korean: '우연히 만나다'),
          Word(english: 'come up with', korean: '생각해내다'),
          Word(english: 'deal with', korean: '다루다, 처리하다'),
          Word(english: 'figure out', korean: '이해하다, 알아내다'),
          Word(english: 'get along with', korean: '~와 잘 지내다'),
          Word(english: 'give up', korean: '포기하다'),
          Word(english: 'go through', korean: '겪다, 검토하다'),
          Word(english: 'keep up with', korean: '따라잡다'),
          Word(english: 'look forward to', korean: '기대하다'),
          Word(english: 'make up', korean: '구성하다, 화해하다'),
          Word(english: 'put off', korean: '연기하다'),
          Word(english: 'run out of', korean: '~이 떨어지다'),
          Word(english: 'take advantage of', korean: '~을 이용하다'),
          Word(english: 'take into account', korean: '고려하다'),
          Word(english: 'turn out', korean: '~로 판명되다'),
          Word(english: 'derive', korean: '유래하다'),
          Word(english: 'design', korean: '설계하다'),
          Word(english: 'despite', korean: '~에도 불구하고'),
          Word(english: 'detect', korean: '감지하다'),
          Word(english: 'determine', korean: '결정하다'),
          Word(english: 'deviate', korean: '벗어나다'),
          Word(english: 'device', korean: '장치'),
          Word(english: 'devote', korean: '헌신하다'),
          Word(english: 'differentiate', korean: '구별하다'),
          Word(english: 'dimension', korean: '차원'),
          Word(english: 'diminish', korean: '감소하다'),
          Word(english: 'discrete', korean: '개별적인'),
          Word(english: 'discriminate', korean: '차별하다'),
          Word(english: 'display', korean: '전시하다'),
          Word(english: 'dispose', korean: '처리하다'),
          Word(english: 'distinct', korean: '뚜렷한'),
          Word(english: 'distribute', korean: '분배하다'),
          Word(english: 'diverse', korean: '다양한'),
          Word(english: 'domain', korean: '영역'),
          Word(english: 'domestic', korean: '국내의'),
          Word(english: 'dominate', korean: '지배하다'),
          Word(english: 'draft', korean: '초안'),
          Word(english: 'dramatic', korean: '극적인'),
          Word(english: 'duration', korean: '지속기간'),
          Word(english: 'dynamic', korean: '역동적인'),
          Word(english: 'economy', korean: '경제'),
          Word(english: 'edit', korean: '편집하다'),
          Word(english: 'element', korean: '요소'),
          Word(english: 'eliminate', korean: '제거하다'),
          Word(english: 'emerge', korean: '나타나다'),
          Word(english: 'emphasis', korean: '강조'),
          Word(english: 'empirical', korean: '경험적인'),
          
          // Advanced Academic Vocabulary (151-200)
          Word(english: 'enable', korean: '가능하게 하다'),
          Word(english: 'encounter', korean: '마주치다'),
          Word(english: 'energy', korean: '에너지'),
          Word(english: 'enforce', korean: '시행하다'),
          Word(english: 'enhance', korean: '향상시키다'),
          Word(english: 'enormous', korean: '거대한'),
          Word(english: 'ensure', korean: '보장하다'),
          Word(english: 'entity', korean: '실체'),
          Word(english: 'environment', korean: '환경'),
          Word(english: 'equate', korean: '동일시하다'),
          Word(english: 'equip', korean: '갖추다'),
          Word(english: 'equivalent', korean: '동등한'),
          Word(english: 'erode', korean: '침식하다'),
          Word(english: 'error', korean: '오류'),
          Word(english: 'establish', korean: '설립하다'),
          Word(english: 'estimate', korean: '추정하다'),
          Word(english: 'ethic', korean: '윤리'),
          Word(english: 'ethnic', korean: '민족의'),
          Word(english: 'evaluate', korean: '평가하다'),
          Word(english: 'eventual', korean: '결국의'),
          Word(english: 'evident', korean: '명백한'),
          Word(english: 'evolve', korean: '진화하다'),
          Word(english: 'exceed', korean: '초과하다'),
          Word(english: 'exclude', korean: '제외하다'),
          Word(english: 'exhibit', korean: '전시하다'),
          Word(english: 'expand', korean: '확장하다'),
          Word(english: 'expert', korean: '전문가'),
          Word(english: 'explicit', korean: '명시적인'),
          Word(english: 'exploit', korean: '이용하다'),
          Word(english: 'export', korean: '수출하다'),
          Word(english: 'expose', korean: '노출시키다'),
          Word(english: 'external', korean: '외부의'),
          Word(english: 'extract', korean: '추출하다'),
          Word(english: 'facilitate', korean: '용이하게 하다'),
          Word(english: 'factor', korean: '요인'),
          Word(english: 'feature', korean: '특징'),
          Word(english: 'federal', korean: '연방의'),
          Word(english: 'fee', korean: '수수료'),
          Word(english: 'file', korean: '파일; 제출하다'),
          Word(english: 'final', korean: '최종의'),
          Word(english: 'finance', korean: '재정'),
          Word(english: 'finite', korean: '유한한'),
          Word(english: 'flexible', korean: '유연한'),
          Word(english: 'fluctuate', korean: '변동하다'),
          Word(english: 'focus', korean: '초점'),
          Word(english: 'format', korean: '형식'),
          Word(english: 'formula', korean: '공식'),
          Word(english: 'forthcoming', korean: '다가오는'),
          Word(english: 'found', korean: '설립하다'),
          Word(english: 'foundation', korean: '기초'),
        ],
        chunkCount: 0,
      ),
    ];
  }
}