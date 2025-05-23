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
        name: '토익 필수',
        words: [
          Word(english: 'appreciate', korean: '감사하다; 평가하다'),
          Word(english: 'authority', korean: '권위, 권한'),
          Word(english: 'efficient', korean: '효율적인'),
        ],
        chunkCount: 0,
      ),
    ];
  }
}