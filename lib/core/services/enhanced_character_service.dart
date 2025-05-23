// lib/core/services/enhanced_character_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chunk_up/domain/models/character.dart';

class EnhancedCharacterService {
  static const String _charactersKey = 'enhanced_characters';
  static const String _relationshipsKey = 'character_relationships';
  
  // Singleton pattern
  static final EnhancedCharacterService _instance = EnhancedCharacterService._internal();
  factory EnhancedCharacterService() => _instance;
  EnhancedCharacterService._internal();

  // Cache
  List<Character>? _cachedCharacters;
  List<CharacterRelationship>? _cachedRelationships;

  /// Initialize with default characters
  Future<void> initializeDefaultCharacters() async {
    final characters = await getAllCharacters();
    if (characters.isEmpty) {
      await _addDefaultCharacters();
    }
  }

  /// Get all characters
  Future<List<Character>> getAllCharacters() async {
    if (_cachedCharacters != null) return _cachedCharacters!;
    
    final prefs = await SharedPreferences.getInstance();
    final String? charactersJson = prefs.getString(_charactersKey);
    
    if (charactersJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(charactersJson);
    _cachedCharacters = decoded.map((json) => Character.fromJson(json)).toList();
    return _cachedCharacters!;
  }

  /// Get characters by series
  Future<List<Character>> getCharactersBySeries(String seriesId) async {
    final allCharacters = await getAllCharacters();
    return allCharacters.where((c) => c.seriesId == seriesId).toList();
  }

  /// Get character by name
  Future<Character?> getCharacterByName(String name) async {
    final characters = await getAllCharacters();
    try {
      return characters.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get multiple characters by names
  Future<List<Character>> getCharactersByNames(List<String> names) async {
    final characters = await getAllCharacters();
    return characters.where((c) => 
      names.any((name) => c.name.toLowerCase() == name.toLowerCase())
    ).toList();
  }

  /// Add or update character
  Future<void> saveCharacter(Character character) async {
    final characters = await getAllCharacters();
    final index = characters.indexWhere((c) => c.id == character.id);
    
    if (index >= 0) {
      characters[index] = character;
    } else {
      characters.add(character);
    }
    
    await _saveCharacters(characters);
  }

  /// Delete character
  Future<void> deleteCharacter(String characterId) async {
    final characters = await getAllCharacters();
    characters.removeWhere((c) => c.id == characterId);
    await _saveCharacters(characters);
    
    // Also remove related relationships
    final relationships = await getAllRelationships();
    relationships.removeWhere((r) => 
      r.characterAId == characterId || r.characterBId == characterId
    );
    await _saveRelationships(relationships);
  }

  /// Get all relationships
  Future<List<CharacterRelationship>> getAllRelationships() async {
    if (_cachedRelationships != null) return _cachedRelationships!;
    
    final prefs = await SharedPreferences.getInstance();
    final String? relationshipsJson = prefs.getString(_relationshipsKey);
    
    if (relationshipsJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(relationshipsJson);
    _cachedRelationships = decoded.map((json) => CharacterRelationship.fromJson(json)).toList();
    return _cachedRelationships!;
  }

  /// Get relationship between two characters
  Future<CharacterRelationship?> getRelationship(String characterAId, String characterBId) async {
    final relationships = await getAllRelationships();
    try {
      return relationships.firstWhere(
        (r) => (r.characterAId == characterAId && r.characterBId == characterBId) ||
               (r.characterAId == characterBId && r.characterBId == characterAId),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get relationships for a character
  Future<List<CharacterRelationship>> getCharacterRelationships(String characterId) async {
    final relationships = await getAllRelationships();
    return relationships.where((r) => 
      r.characterAId == characterId || r.characterBId == characterId
    ).toList();
  }

  /// Save relationship
  Future<void> saveRelationship(CharacterRelationship relationship) async {
    final relationships = await getAllRelationships();
    
    // Remove existing relationship between these characters
    relationships.removeWhere((r) => 
      (r.characterAId == relationship.characterAId && r.characterBId == relationship.characterBId) ||
      (r.characterAId == relationship.characterBId && r.characterBId == relationship.characterAId)
    );
    
    relationships.add(relationship);
    await _saveRelationships(relationships);
  }

  /// Delete relationship
  Future<void> deleteRelationship(String relationshipId) async {
    final relationships = await getAllRelationships();
    relationships.removeWhere((r) => r.id == relationshipId);
    await _saveRelationships(relationships);
  }

  /// Build relationship context for prompt
  String buildRelationshipContext(
    String characterAName,
    String characterBName,
    CharacterRelationship? relationship,
  ) {
    if (relationship == null) return '';
    
    return '''

RELATIONSHIP CONTEXT:
- Type: ${relationship.type.englishName} - ${_getRelationshipTypeDescription(relationship.type)}
- Status: ${relationship.status.englishName} - ${_getRelationshipStatusDescription(relationship.status)}
- Description: ${relationship.description}
- Consider this ${relationship.type.name} dynamic in the dialogue/interaction''';
  }

  /// Build character context for prompt
  String buildCharacterContext(Character character) {
    return '''

CHARACTER: ${character.name}
- From: ${character.seriesName}
- Description: ${character.description}${character.personality.isNotEmpty ? '\n- Personality: ${character.personality}' : ''}${character.catchPhrases.isNotEmpty ? '\n- Catch phrases: ${character.catchPhrases.join(', ')}' : ''}''';
  }

  // Private helper methods
  Future<void> _saveCharacters(List<Character> characters) async {
    _cachedCharacters = characters;
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(characters.map((c) => c.toJson()).toList());
    await prefs.setString(_charactersKey, encoded);
  }

  Future<void> _saveRelationships(List<CharacterRelationship> relationships) async {
    _cachedRelationships = relationships;
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(relationships.map((r) => r.toJson()).toList());
    await prefs.setString(_relationshipsKey, encoded);
  }

  String _getRelationshipTypeDescription(RelationshipType type) {
    switch (type) {
      case RelationshipType.rivalry:
        return 'Professional competitors who push each other to excel';
      case RelationshipType.friendship:
        return 'Close friends who support each other';
      case RelationshipType.romantic:
        return 'Romantic partners with deep emotional connection';
      case RelationshipType.enemy:
        return 'Adversaries in direct opposition';
      case RelationshipType.mentor:
        return 'Teacher and student relationship';
      case RelationshipType.familial:
        return 'Family members with blood or legal ties';
      case RelationshipType.colleague:
        return 'Professional associates working together';
      case RelationshipType.master:
        return 'Hierarchical relationship with clear authority';
      case RelationshipType.complex:
        return 'Multifaceted relationship that defies simple categorization';
    }
  }

  String _getRelationshipStatusDescription(RelationshipStatus status) {
    switch (status) {
      case RelationshipStatus.harmonious:
        return 'in perfect harmony';
      case RelationshipStatus.tense:
        return 'with underlying tension';
      case RelationshipStatus.conflicted:
        return 'currently in conflict';
      case RelationshipStatus.estranged:
        return 'distant and disconnected';
      case RelationshipStatus.developing:
        return 'still evolving and growing';
      case RelationshipStatus.broken:
        return 'severely damaged or ended';
      case RelationshipStatus.normal:
        return 'stable and ordinary';
    }
  }

  /// Add default characters for testing
  Future<void> _addDefaultCharacters() async {
    debugPrint('EnhancedCharacterService: 기본 캐릭터 추가 시작');
    
    final defaultCharacters = [
      Character(
        id: 'sherlock_holmes',
        name: '셜록 홈즈',
        seriesId: 'sherlock_holmes',
        seriesName: '셜록 홈즈',
        description: '세계에서 가장 유명한 탐정. 뛰어난 관찰력과 추리력으로 불가능해 보이는 사건들을 해결한다. 바이올린 연주를 즐기며, 과학적 실험에 몰두하기도 한다.',
        personality: '논리적이고 분석적인 성격. 지적 도전을 즐기며, 평범한 일상에는 쉽게 지루함을 느낀다. 때로는 냉정해 보이지만 정의감이 강하다.',
        catchPhrases: ['초보적이야, 왓슨', '불가능을 제거하고 나면, 남는 것이 아무리 믿기 어려워도 그것이 진실이다', '당신은 보기만 할 뿐, 관찰하지 않는다'],
        tags: ['탐정', '천재', '관찰력'],
      ),
      Character(
        id: 'little_prince',
        name: '어린 왕자',
        seriesId: 'little_prince',
        seriesName: '어린 왕자',
        description: '소행성 B-612에서 온 순수한 영혼의 소년. 장미꽃을 사랑하며, 여러 별을 여행하면서 어른들의 이상한 세계를 관찰한다.',
        personality: '순수하고 호기심이 많으며, 사물의 본질을 꿰뚫어보는 통찰력을 가지고 있다. 사랑과 책임감을 중요하게 생각한다.',
        catchPhrases: ['가장 중요한 것은 눈에 보이지 않아', '네가 길들인 것에 대해선 영원히 책임을 져야 해', '어른들은 정말 이상해'],
        tags: ['순수', '철학적', '여행자'],
      ),
      Character(
        id: 'dorothy',
        name: '도로시',
        seriesId: 'wizard_of_oz',
        seriesName: '오즈의 마법사',
        description: '캔자스에서 온 용감한 소녀. 토네이도에 휩쓸려 오즈의 나라로 떨어진 후, 집으로 돌아가기 위해 모험을 떠난다. 강아지 토토와 함께 다닌다.',
        personality: '용감하고 친절하며, 어려움에 처한 친구들을 돕는 것을 주저하지 않는다. 가족을 사랑하고 집을 그리워하는 따뜻한 마음을 가지고 있다.',
        catchPhrases: ['집만한 곳은 없어', '우리가 함께라면 할 수 있어', '토토, 우리는 더 이상 캔자스에 있지 않아'],
        tags: ['모험가', '용감함', '우정'],
      ),
      Character(
        id: 'watson',
        name: '왓슨 박사',
        seriesId: 'sherlock_holmes',
        seriesName: '셜록 홈즈',
        description: '셜록 홈즈의 가장 친한 친구이자 조수. 의사이며 아프가니스탄 전쟁에 참전한 경험이 있다. 홈즈의 모험을 기록하는 화자 역할을 한다.',
        personality: '충직하고 용감하며, 상식적이고 인간적인 면모를 가지고 있다. 홈즈의 비범한 추리에 감탄하면서도 때로는 그의 기이한 행동에 당황하기도 한다.',
        catchPhrases: ['굉장해, 홈즈!', '도대체 어떻게 알았습니까?', '믿을 수 없군요!'],
        tags: ['의사', '친구', '기록자'],
      ),
    ];

    final defaultRelationships = [
      CharacterRelationship(
        id: 'rel_holmes_watson',
        characterAId: 'sherlock_holmes',
        characterBId: 'watson',
        type: RelationshipType.friendship,
        status: RelationshipStatus.harmonious,
        description: '홈즈와 왓슨은 베이커 스트리트 221B에서 함께 살며 수많은 사건을 해결하는 최고의 파트너다. 왓슨은 홈즈의 유일한 친구이자 그의 모험을 기록하는 전기 작가 역할을 한다.',
        keyEvents: ['첫 만남 - 혈자의 연구', '라이헨바흐 폭포 사건', '홈즈의 귀환'],
      ),
    ];

    for (final character in defaultCharacters) {
      await saveCharacter(character);
    }
    
    for (final relationship in defaultRelationships) {
      await saveRelationship(relationship);
    }
    
    debugPrint('✅ Default characters and relationships added');
  }
}