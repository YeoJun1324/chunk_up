// lib/core/services/series_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chunk_up/domain/models/series.dart';
import 'package:chunk_up/domain/models/character.dart';
import 'package:chunk_up/core/services/enhanced_character_service.dart';

class SeriesService {
  static const String _seriesKey = 'series_list';
  
  // Singleton pattern
  static final SeriesService _instance = SeriesService._internal();
  factory SeriesService() => _instance;
  SeriesService._internal();

  // Cache
  List<Series>? _cachedSeries;
  
  /// Clear cache (for data reset)
  void clearCache() {
    _cachedSeries = null;
  }

  /// Get all series
  Future<List<Series>> getAllSeries() async {
    if (_cachedSeries != null) return _cachedSeries!;
    
    final prefs = await SharedPreferences.getInstance();
    final String? seriesJson = prefs.getString(_seriesKey);
    
    if (seriesJson == null) {
      // 기본 시리즈 초기화
      await _initializeDefaultSeries();
      return _cachedSeries ?? [];
    }
    
    final List<dynamic> decoded = jsonDecode(seriesJson);
    _cachedSeries = decoded.map((json) => Series.fromJson(json)).toList();
    return _cachedSeries!;
  }

  /// Get series by ID
  Future<Series?> getSeriesById(String id) async {
    final series = await getAllSeries();
    try {
      return series.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get series by name
  Future<Series?> getSeriesByName(String name) async {
    final series = await getAllSeries();
    try {
      return series.firstWhere(
        (s) => s.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Save series
  Future<void> saveSeries(Series series) async {
    final allSeries = await getAllSeries();
    final index = allSeries.indexWhere((s) => s.id == series.id);
    
    if (index >= 0) {
      allSeries[index] = series.copyWith(updatedAt: DateTime.now());
    } else {
      allSeries.add(series);
    }
    
    await _saveSeries(allSeries);
  }

  /// Delete series
  Future<void> deleteSeries(String seriesId) async {
    final allSeries = await getAllSeries();
    allSeries.removeWhere((s) => s.id == seriesId);
    await _saveSeries(allSeries);
    
    // 관련 캐릭터와 관계도 삭제
    final characterService = EnhancedCharacterService();
    final characters = await characterService.getAllCharacters();
    for (final character in characters) {
      if (character.seriesId == seriesId) {
        await characterService.deleteCharacter(character.id);
      }
    }
  }

  /// Add character to series
  Future<void> addCharacterToSeries(String seriesId, String characterId) async {
    final series = await getSeriesById(seriesId);
    if (series != null && !series.characterIds.contains(characterId)) {
      final updatedSeries = series.copyWith(
        characterIds: [...series.characterIds, characterId],
      );
      await saveSeries(updatedSeries);
    }
  }

  /// Remove character from series
  Future<void> removeCharacterFromSeries(String seriesId, String characterId) async {
    final series = await getSeriesById(seriesId);
    if (series != null) {
      final updatedSeries = series.copyWith(
        characterIds: series.characterIds.where((id) => id != characterId).toList(),
      );
      await saveSeries(updatedSeries);
    }
  }

  /// Add relationship to series
  Future<void> addRelationshipToSeries(String seriesId, String relationshipId) async {
    final series = await getSeriesById(seriesId);
    if (series != null && !series.relationshipIds.contains(relationshipId)) {
      final updatedSeries = series.copyWith(
        relationshipIds: [...series.relationshipIds, relationshipId],
      );
      await saveSeries(updatedSeries);
    }
  }

  /// Get characters in series
  Future<List<Character>> getCharactersInSeries(String seriesId) async {
    final characterService = EnhancedCharacterService();
    return await characterService.getCharactersBySeries(seriesId);
  }

  /// Get relationships in series
  Future<List<CharacterRelationship>> getRelationshipsInSeries(String seriesId) async {
    final series = await getSeriesById(seriesId);
    if (series == null) return [];
    
    final characterService = EnhancedCharacterService();
    final allRelationships = await characterService.getAllRelationships();
    
    return allRelationships.where((r) => 
      series.relationshipIds.contains(r.id)
    ).toList();
  }

  // Private methods
  Future<void> _saveSeries(List<Series> series) async {
    _cachedSeries = series;
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(series.map((s) => s.toJson()).toList());
    await prefs.setString(_seriesKey, encoded);
  }

  Future<void> _initializeDefaultSeries() async {
    try {
      debugPrint('SeriesService: 기본 시리즈 초기화 시작');
      
      final defaultSeries = [
        Series(
          id: 'sherlock_holmes',
          name: '셜록 홈즈',
          description: '아서 코난 도일의 추리 소설 시리즈',
          settings: SeriesSettings(
            genre: '추리 소설',
            worldSetting: '19세기 빅토리아 시대 런던',
            customSettings: {
              'location': '베이커 스트리트 221B',
              'period': '1880-1914년',
            },
          ),
        ),
        Series(
          id: 'little_prince',
          name: '어린 왕자',
          description: '생텍쥐페리의 철학적 동화',
          settings: SeriesSettings(
            genre: '철학적 동화',
            worldSetting: '소행성 B-612와 지구',
            customSettings: {
              'themes': '사랑, 우정, 책임',
              'style': '우화적 서술',
            },
          ),
        ),
        Series(
          id: 'wizard_of_oz',
          name: '오즈의 마법사',
          description: 'L. 프랭크 바움의 판타지 동화',
          settings: SeriesSettings(
            genre: '판타지 동화',
            worldSetting: '마법의 나라 오즈',
            customSettings: {
              'locations': '에메랄드 시티, 노란 벽돌길',
              'magic': '마법과 환상의 세계',
            },
          ),
        ),
      ];
      
      _cachedSeries = defaultSeries;
      await _saveSeries(defaultSeries);
      
      debugPrint('✅ Default series initialized: ${defaultSeries.length}개');
    } catch (e) {
      debugPrint('❌ Default series initialization error: $e');
      _cachedSeries = [];
    }
  }
}