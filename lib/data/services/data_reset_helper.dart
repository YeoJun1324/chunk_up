// lib/core/utils/data_reset_helper.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chunk_up/domain/services/series/series_service.dart';
import 'package:chunk_up/domain/services/character/enhanced_character_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class DataResetHelper {
  static Future<void> resetToDefaultData() async {
    try {
      debugPrint('🔄 데이터 리셋 시작...');
      
      // SharedPreferences 인스턴스 가져오기
      final prefs = await SharedPreferences.getInstance();
      
      // 기존 시리즈 데이터 삭제
      await prefs.remove('series_list');
      debugPrint('✅ 기존 시리즈 데이터 삭제됨');
      
      // 기존 캐릭터 데이터 삭제
      await prefs.remove('enhanced_characters');
      await prefs.remove('character_relationships');
      debugPrint('✅ 기존 캐릭터 데이터 삭제됨');
      
      // 서비스 인스턴스의 캐시 초기화
      final seriesService = getIt<SeriesService>();
      final characterService = EnhancedCharacterService();
      
      // 캐시 클리어
      seriesService.clearCache();
      
      // 새로운 기본 데이터로 재초기화
      await seriesService.getAllSeries(); // 이게 기본 시리즈를 다시 생성함
      await characterService.initializeDefaultCharacters(); // 이게 기본 캐릭터를 다시 생성함
      
      debugPrint('✅ 데이터 리셋 완료!');
    } catch (e) {
      debugPrint('❌ 데이터 리셋 실패: $e');
      rethrow;
    }
  }
}