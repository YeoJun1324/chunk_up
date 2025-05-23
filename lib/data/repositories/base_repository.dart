// lib/data/repositories/base_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Base repository class for shared repository functionality
abstract class BaseRepository<T> {
  /// The storage key to use for this repository
  String get storageKey;
  
  /// Convert a JSON map to an entity
  T fromJson(Map<String, dynamic> json);
  
  /// Convert an entity to a JSON map
  Map<String, dynamic> toJson(T entity);
  
  /// Get all entities
  Future<List<T>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? dataJson = prefs.getString(storageKey);

      if (dataJson == null) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(dataJson);
      return decoded.map<T>((item) => fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      print('오류 발생: $e');
      return [];
    }
  }
  
  /// Save all entities
  Future<void> saveAll(List<T> entities) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(entities.map((e) => toJson(e)).toList());
    await prefs.setString(storageKey, encoded);
  }
  
  /// Find an entity by predicate
  Future<T?> findBy(bool Function(T entity) predicate) async {
    final allEntities = await getAll();
    try {
      return allEntities.firstWhere(predicate);
    } catch (e) {
      return null;
    }
  }
  
  /// Create a new entity
  Future<T> create(T entity) async {
    final entities = await getAll();
    entities.add(entity);
    await saveAll(entities);
    return entity;
  }
  
  /// Update an entity
  Future<T> update(T entity, bool Function(T) finder) async {
    final entities = await getAll();
    final index = entities.indexWhere(finder);
    
    if (index == -1) {
      throw Exception('Entity not found');
    }
    
    entities[index] = entity;
    await saveAll(entities);
    return entity;
  }
  
  /// Delete an entity
  Future<bool> delete(bool Function(T) finder) async {
    final entities = await getAll();
    final initialLength = entities.length;
    
    entities.removeWhere(finder);
    
    if (entities.length == initialLength) {
      return false;
    }
    
    await saveAll(entities);
    return true;
  }
}