import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chunk_up/core/constants/prompt_templates.dart';

/// 사용자 정의 프롬프트 템플릿
class CustomPromptTemplate {
  final String id;
  final String name;
  final String description;
  final OutputFormat outputFormat;
  final Map<String, String> sections;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final int version;

  CustomPromptTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.outputFormat,
    required this.sections,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.version = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'outputFormat': outputFormat.name,
    'sections': sections,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'isActive': isActive,
    'version': version,
  };

  factory CustomPromptTemplate.fromJson(Map<String, dynamic> json) {
    return CustomPromptTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      outputFormat: OutputFormat.values.firstWhere(
        (e) => e.name == json['outputFormat'],
        orElse: () => OutputFormat.narrative,
      ),
      sections: Map<String, String>.from(json['sections']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isActive: json['isActive'] ?? true,
      version: json['version'] ?? 1,
    );
  }

  CustomPromptTemplate copyWith({
    String? name,
    String? description,
    OutputFormat? outputFormat,
    Map<String, String>? sections,
    bool? isActive,
  }) {
    return CustomPromptTemplate(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      outputFormat: outputFormat ?? this.outputFormat,
      sections: sections ?? this.sections,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
      version: version + 1,
    );
  }
}

/// 프롬프트 생성 히스토리
class PromptHistory {
  final String id;
  final String promptTemplateId;
  final String generatedPrompt;
  final List<String> words;
  final String? characterName;
  final String? scenario;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final int qualityScore;
  final String? resultChunkId;

  PromptHistory({
    required this.id,
    required this.promptTemplateId,
    required this.generatedPrompt,
    required this.words,
    this.characterName,
    this.scenario,
    required this.settings,
    required this.createdAt,
    required this.qualityScore,
    this.resultChunkId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'promptTemplateId': promptTemplateId,
    'generatedPrompt': generatedPrompt,
    'words': words,
    'characterName': characterName,
    'scenario': scenario,
    'settings': settings,
    'createdAt': createdAt.toIso8601String(),
    'qualityScore': qualityScore,
    'resultChunkId': resultChunkId,
  };

  factory PromptHistory.fromJson(Map<String, dynamic> json) {
    return PromptHistory(
      id: json['id'],
      promptTemplateId: json['promptTemplateId'],
      generatedPrompt: json['generatedPrompt'],
      words: List<String>.from(json['words']),
      characterName: json['characterName'],
      scenario: json['scenario'],
      settings: Map<String, dynamic>.from(json['settings']),
      createdAt: DateTime.parse(json['createdAt']),
      qualityScore: json['qualityScore'],
      resultChunkId: json['resultChunkId'],
    );
  }
}

/// 프롬프트 템플릿 관리 서비스
class PromptTemplateService {
  static const String _templatesKey = 'custom_prompt_templates';
  static const String _historyKey = 'prompt_history';
  static const String _activeTemplateKey = 'active_prompt_template';
  static const int _maxHistoryItems = 50;

  // Singleton 패턴
  static final PromptTemplateService _instance = PromptTemplateService._internal();
  factory PromptTemplateService() => _instance;
  PromptTemplateService._internal();

  /// 기본 템플릿 생성
  Future<void> initializeDefaultTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final existingTemplates = await getTemplates();
    
    if (existingTemplates.isEmpty) {
      // 기본 템플릿 추가
      final defaultTemplate = CustomPromptTemplate(
        id: 'default_narrative',
        name: '기본 나레이션 템플릿',
        description: '표준 나레이션 형식의 기본 템플릿',
        outputFormat: OutputFormat.narrative,
        sections: {
          'intro': 'You are a creative writer helping students learn vocabulary through contextual stories.',
          'requirements': 'Use each word exactly once in a natural, educational context.',
          'style': 'Write in third-person narrative style with descriptive language.',
        },
        createdAt: DateTime.now(),
      );
      
      await saveTemplate(defaultTemplate);
      await setActiveTemplate(defaultTemplate.id);
    }
  }

  /// 템플릿 저장
  Future<void> saveTemplate(CustomPromptTemplate template) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templates = await getTemplates();
      
      // 기존 템플릿 업데이트 또는 새 템플릿 추가
      final index = templates.indexWhere((t) => t.id == template.id);
      if (index >= 0) {
        templates[index] = template;
      } else {
        templates.add(template);
      }
      
      // 저장
      final jsonList = templates.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList(_templatesKey, jsonList);
      
      debugPrint('✅ Template saved: ${template.name}');
    } catch (e) {
      debugPrint('❌ Error saving template: $e');
      rethrow;
    }
  }

  /// 템플릿 목록 가져오기
  Future<List<CustomPromptTemplate>> getTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_templatesKey) ?? [];
      
      return jsonList
          .map((json) => CustomPromptTemplate.fromJson(jsonDecode(json)))
          .where((t) => t.isActive)
          .toList()
        ..sort((a, b) => b.updatedAt?.compareTo(a.updatedAt ?? a.createdAt) ?? 
                        b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('❌ Error loading templates: $e');
      return [];
    }
  }

  /// 특정 템플릿 가져오기
  Future<CustomPromptTemplate?> getTemplate(String id) async {
    final templates = await getTemplates();
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 활성 템플릿 설정
  Future<void> setActiveTemplate(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeTemplateKey, templateId);
  }

  /// 활성 템플릿 가져오기
  Future<String?> getActiveTemplateId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeTemplateKey);
  }

  /// 템플릿 삭제 (비활성화)
  Future<void> deleteTemplate(String id) async {
    final template = await getTemplate(id);
    if (template != null) {
      final deactivated = template.copyWith(isActive: false);
      await saveTemplate(deactivated);
    }
  }

  /// 프롬프트 생성 히스토리 저장
  Future<void> savePromptHistory(PromptHistory history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = await getPromptHistory();
      
      // 최신 항목을 앞에 추가
      historyList.insert(0, history);
      
      // 최대 개수 유지
      if (historyList.length > _maxHistoryItems) {
        historyList.removeRange(_maxHistoryItems, historyList.length);
      }
      
      // 저장
      final jsonList = historyList.map((h) => jsonEncode(h.toJson())).toList();
      await prefs.setStringList(_historyKey, jsonList);
      
      debugPrint('✅ Prompt history saved');
    } catch (e) {
      debugPrint('❌ Error saving prompt history: $e');
    }
  }

  /// 프롬프트 히스토리 가져오기
  Future<List<PromptHistory>> getPromptHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_historyKey) ?? [];
      
      return jsonList
          .map((json) => PromptHistory.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error loading prompt history: $e');
      return [];
    }
  }

  /// 특정 캐릭터의 프롬프트 히스토리
  Future<List<PromptHistory>> getCharacterPromptHistory(String characterName) async {
    final history = await getPromptHistory();
    return history.where((h) => h.characterName == characterName).toList();
  }

  /// 품질 점수별 히스토리
  Future<List<PromptHistory>> getHighQualityPrompts({int minScore = 80}) async {
    final history = await getPromptHistory();
    return history.where((h) => h.qualityScore >= minScore).toList();
  }

  /// 템플릿 복제
  Future<CustomPromptTemplate> duplicateTemplate(String templateId, String newName) async {
    final original = await getTemplate(templateId);
    if (original == null) {
      throw Exception('Template not found');
    }
    
    final duplicate = CustomPromptTemplate(
      id: 'template_${DateTime.now().millisecondsSinceEpoch}',
      name: newName,
      description: '${original.description} (복사본)',
      outputFormat: original.outputFormat,
      sections: Map.from(original.sections),
      createdAt: DateTime.now(),
    );
    
    await saveTemplate(duplicate);
    return duplicate;
  }

  /// 템플릿 내보내기
  Future<String> exportTemplate(String templateId) async {
    final template = await getTemplate(templateId);
    if (template == null) {
      throw Exception('Template not found');
    }
    
    return jsonEncode({
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'template': template.toJson(),
    });
  }

  /// 템플릿 가져오기
  Future<CustomPromptTemplate> importTemplate(String jsonData) async {
    try {
      final data = jsonDecode(jsonData);
      final templateData = data['template'];
      
      // 새 ID 생성
      templateData['id'] = 'imported_${DateTime.now().millisecondsSinceEpoch}';
      templateData['name'] = '${templateData['name']} (가져옴)';
      templateData['createdAt'] = DateTime.now().toIso8601String();
      templateData['updatedAt'] = null;
      
      final template = CustomPromptTemplate.fromJson(templateData);
      await saveTemplate(template);
      
      return template;
    } catch (e) {
      debugPrint('❌ Error importing template: $e');
      throw Exception('템플릿 가져오기 실패: 잘못된 형식');
    }
  }

  /// 템플릿 통계
  Future<Map<String, dynamic>> getTemplateStatistics() async {
    final templates = await getTemplates();
    final history = await getPromptHistory();
    
    final stats = <String, dynamic>{
      'totalTemplates': templates.length,
      'totalPrompts': history.length,
      'averageQualityScore': history.isEmpty ? 0 : 
          history.map((h) => h.qualityScore).reduce((a, b) => a + b) / history.length,
      'templateUsage': <String, int>{},
      'outputFormatDistribution': <String, int>{},
    };
    
    // 템플릿 사용 통계
    for (final h in history) {
      stats['templateUsage'][h.promptTemplateId] = 
          (stats['templateUsage'][h.promptTemplateId] ?? 0) + 1;
    }
    
    // 출력 형식 분포
    for (final t in templates) {
      stats['outputFormatDistribution'][t.outputFormat.name] = 
          (stats['outputFormatDistribution'][t.outputFormat.name] ?? 0) + 1;
    }
    
    return stats;
  }
}