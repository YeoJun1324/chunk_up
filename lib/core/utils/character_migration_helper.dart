// lib/core/utils/character_migration_helper.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// 기존 CharacterService의 캐릭터를 정리하는 헬퍼
class CharacterMigrationHelper {
  static const String _charactersKey = 'custom_characters';
  static const String _migrationCompleteKey = 'character_migration_v1_complete';
  
  /// 기존 CharacterService의 캐릭터 데이터를 정리
  static Future<void> cleanupOldCharacterData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 이미 마이그레이션이 완료되었는지 확인
    final isMigrationComplete = prefs.getBool(_migrationCompleteKey) ?? false;
    if (isMigrationComplete) {
      debugPrint('✅ Character migration already completed');
      return;
    }
    
    try {
      // 기존 캐릭터 데이터 삭제
      await prefs.remove(_charactersKey);
      debugPrint('🗑️ Old character data removed');
      
      // 마이그레이션 완료 플래그 설정
      await prefs.setBool(_migrationCompleteKey, true);
      debugPrint('✅ Character migration completed');
    } catch (e) {
      debugPrint('❌ Character migration failed: $e');
    }
  }
}