// lib/core/services/character_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 캐릭터 모델 클래스
class Character {
  final String name;
  final String source;
  final String details;
  final DateTime createdAt;

  Character({
    required this.name,
    required this.source,
    this.details = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'source': source,
      'details': details,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['name'],
      source: json['source'],
      details: json['details'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// 캐릭터 관리 서비스
class CharacterService {
  static const String _charactersKey = 'custom_characters';
  static const String _defaultCharactersInitializedKey = 'default_characters_initialized';
  List<Character> get defaultCharacters => _defaultCharacters;

  // 기본 캐릭터 목록
  final List<Character> _defaultCharacters = [
    Character(
      name: '셜록 홈즈',
      source: '셜록 홈즈 시리즈',
      details: '세계적으로 유명한 명탐정. 논리적이고 분석적인 사고를 하며, 사건을 해결하는 데 뛰어난 능력을 가지고 있습니다.',
    ),
    Character(
      name: '어린 왕자',
      source: '어린 왕자 (생텍쥐페리)',
      details: '순수하고 호기심 많은 어린 왕자. 별에서 별로 여행하며 다양한 사람들을 만납니다.',
    ),
    Character(
      name: '도로시 게일',
      source: '오즈의 마법사',
      details: '캔자스에서 온 용감한 소녀. 토네이도에 휩쓸려 오즈의 나라로 가게 됩니다.',
    ),
  ];
  
  // Singleton 패턴
  static final CharacterService _instance = CharacterService._internal();
  factory CharacterService() => _instance;
  CharacterService._internal();
  
  /// 기본 캐릭터 초기화
  Future<void> initializeDefaultCharacters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isInitialized = prefs.getBool(_defaultCharactersInitializedKey) ?? false;
      
      debugPrint('Checking default characters initialization: $isInitialized');
      
      if (!isInitialized) {
        // 기본 캐릭터 추가
        for (var character in _defaultCharacters) {
          await addCharacter(character);
        }
        
        // 초기화 완료 표시
        await prefs.setBool(_defaultCharactersInitializedKey, true);
        debugPrint('Default characters initialized successfully');
      }
    } catch (e) {
      debugPrint('Error initializing default characters: $e');
    }
  }
  
  /// 모든 캐릭터 목록 가져오기
  Future<List<Character>> getCharacters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final charactersJson = prefs.getStringList(_charactersKey) ?? [];
      
      return charactersJson
          .map((json) => Character.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('Error getting characters: $e');
      return [];
    }
  }
  
  /// 캐릭터 추가
  Future<bool> addCharacter(Character character) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final charactersJson = prefs.getStringList(_charactersKey) ?? [];
      
      // 이미 존재하는 캐릭터인지 확인
      final existingCharacters = charactersJson
          .map((json) => Character.fromJson(jsonDecode(json)))
          .toList();
      
      if (existingCharacters.any((c) => c.name == character.name)) {
        debugPrint('Character with name ${character.name} already exists');
        return false;
      }
      
      // 새 캐릭터 추가
      charactersJson.add(jsonEncode(character.toJson()));
      await prefs.setStringList(_charactersKey, charactersJson);
      
      debugPrint('Character ${character.name} added successfully');
      return true;
    } catch (e) {
      debugPrint('Error adding character: $e');
      return false;
    }
  }
  
  /// 캐릭터 업데이트
  Future<bool> updateCharacter(String oldName, Character updatedCharacter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final charactersJson = prefs.getStringList(_charactersKey) ?? [];
      
      // 이름이 변경된 경우 중복 확인
      if (oldName != updatedCharacter.name) {
        final existingCharacters = charactersJson
            .map((json) => Character.fromJson(jsonDecode(json)))
            .toList();
        
        if (existingCharacters.any((c) => c.name == updatedCharacter.name)) {
          debugPrint('Character with name ${updatedCharacter.name} already exists');
          return false;
        }
      }
      
      // 캐릭터 업데이트
      bool found = false;
      final updatedJson = charactersJson.map((json) {
        final data = jsonDecode(json);
        if (data['name'] == oldName) {
          found = true;
          return jsonEncode(updatedCharacter.toJson());
        }
        return json;
      }).toList();
      
      if (!found) {
        debugPrint('Character with name $oldName not found');
        return false;
      }
      
      await prefs.setStringList(_charactersKey, updatedJson);
      debugPrint('Character $oldName updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating character: $e');
      return false;
    }
  }
  
  /// 캐릭터 삭제
  Future<bool> deleteCharacter(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final charactersJson = prefs.getStringList(_charactersKey) ?? [];
      
      final initialLength = charactersJson.length;
      final updatedJson = charactersJson.where((json) {
        final data = jsonDecode(json);
        return data['name'] != name;
      }).toList();
      
      if (initialLength == updatedJson.length) {
        debugPrint('Character with name $name not found');
        return false;
      }
      
      await prefs.setStringList(_charactersKey, updatedJson);
      debugPrint('Character $name deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting character: $e');
      return false;
    }
  }
  
  /// 이름으로 캐릭터 찾기
  Future<Character?> getCharacterByName(String name) async {
    try {
      final characters = await getCharacters();
      return characters.firstWhere(
        (c) => c.name == name,
        orElse: () => throw Exception('Character not found'),
      );
    } catch (e) {
      debugPrint('Error finding character: $e');
      return null;
    }
  }
  
  /// 사용 가능한 모든 캐릭터 이름 목록 가져오기
  Future<List<String>> getCharacterNames() async {
    try {
      final characters = await getCharacters();
      return characters.map((c) => c.name).toList();
    } catch (e) {
      debugPrint('Error getting character names: $e');
      return [];
    }
  }

  /// 캐릭터 옵션 목록 가져오기 (static 메서드)
  static Future<List<String>> getCharacterOptions() async {
    final service = CharacterService();
    return await service.getCharacterNames();
  }
}