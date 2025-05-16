// lib/data/services/storage/local_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Interface for storage service
abstract class StorageService {
  /// Get a value from storage
  Future<String?> getString(String key);

  /// Save a value to storage
  Future<bool> setString(String key, String value);

  /// Remove a value from storage
  Future<bool> remove(String key);

  /// Clear all values from storage
  Future<bool> clear();

  /// Check if a key exists in storage
  Future<bool> containsKey(String key);

  /// Get all keys from storage
  Future<Set<String>> getKeys();
}

/// Implementation of StorageService using SharedPreferences
class LocalStorageService implements StorageService {
  // Singleton pattern
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();
  
  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
  
  @override
  Future<bool> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }
  
  @override
  Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }
  
  @override
  Future<bool> clear() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }
  
  @override
  Future<bool> containsKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  @override
  Future<Set<String>> getKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys();
  }
  
  /// Helper method to save an object to storage
  Future<bool> setObject<T>(String key, T value, Map<String, dynamic> Function(T) toJson) async {
    final String jsonString = jsonEncode(toJson(value));
    return setString(key, jsonString);
  }
  
  /// Helper method to get an object from storage
  Future<T?> getObject<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final String? jsonString = await getString(key);
    if (jsonString == null) {
      return null;
    }
    
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return fromJson(json);
  }
  
  /// Helper method to save a list of objects to storage
  Future<bool> setObjectList<T>(String key, List<T> values, Map<String, dynamic> Function(T) toJson) async {
    final String jsonString = jsonEncode(values.map((value) => toJson(value)).toList());
    return setString(key, jsonString);
  }
  
  /// Helper method to get a list of objects from storage
  Future<List<T>> getObjectList<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final String? jsonString = await getString(key);
    if (jsonString == null) {
      return [];
    }
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map<T>((json) => fromJson(json)).toList();
  }
}