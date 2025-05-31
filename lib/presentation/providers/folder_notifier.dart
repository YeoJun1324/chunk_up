// lib/presentation/providers/folder_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:chunk_up/domain/models/folder.dart';

/// 폴더 목록을 관리하는 Provider
/// 불변성 원칙을 적용하여 폴더 데이터를 안전하게 관리합니다.
/// 모든 데이터 수정은 새 객체를 생성하는 방식으로 이루어집니다.
class FolderNotifier with ChangeNotifier {
  List<Folder> _folders = [];
  bool _isLoading = true;

  FolderNotifier() {
    loadFolders();
  }

  /// 불변성이 보장된 폴더 목록 반환
  List<Folder> get folders => List.unmodifiable(_folders);
  bool get isLoading => _isLoading;

  /// 폴더 목록 로드 (public 메서드)
  Future<void> loadFolders() async {
    await _loadFolders();
  }

  /// 폴더 목록 로드 - 내부 상태 변경
  Future<void> _loadFolders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final foldersJson = prefs.getStringList('folders') ?? [];

      _folders = foldersJson
          .map((json) => Folder.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error loading folders: $e');
      _folders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 폴더 목록 저장
  Future<bool> _saveFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final foldersJson = _folders
          .map((folder) => jsonEncode(folder.toJson()))
          .toList();

      return await prefs.setStringList('folders', foldersJson);
    } catch (e) {
      print('Error saving folders: $e');
      return false;
    }
  }

  /// 새 폴더 추가 - 불변성 패턴 적용
  Future<void> addFolder(String name) async {
    if (name.isEmpty || _folders.any((folder) => folder.name == name)) {
      return;
    }

    final newFolders = List<Folder>.from(_folders)..add(Folder(name: name));
    _updateFolders(newFolders);
    await _saveFolders();
  }

  /// 폴더 이름 변경 - 불변성 패턴 적용
  Future<void> renameFolder(String oldName, String newName) async {
    if (newName.isEmpty || oldName == newName ||
        _folders.any((folder) => folder.name == newName)) {
      return;
    }

    final index = _folders.indexWhere((folder) => folder.name == oldName);
    if (index == -1) {
      return;
    }

    final newFolders = List<Folder>.from(_folders);
    newFolders[index] = _folders[index].copyWith(name: newName);

    _updateFolders(newFolders);
    await _saveFolders();
  }

  /// 폴더 삭제 - 불변성 패턴 적용
  Future<void> deleteFolder(String name) async {
    final newFolders = _folders.where((folder) => folder.name != name).toList();

    if (newFolders.length == _folders.length) {
      return; // 폴더가 존재하지 않음
    }

    _updateFolders(newFolders);
    await _saveFolders();
  }

  /// 폴더에 단어장 추가 - 불변성 패턴 적용
  Future<void> addWordListToFolder(String folderName, String wordListName) async {
    final index = _folders.indexWhere((folder) => folder.name == folderName);
    if (index == -1) {
      return;
    }

    final folder = _folders[index];
    if (folder.wordListNames.contains(wordListName)) {
      return; // 이미 존재하는 단어장
    }

    final newFolder = folder.addWordList(wordListName);
    final newFolders = List<Folder>.from(_folders);
    newFolders[index] = newFolder;

    _updateFolders(newFolders);
    await _saveFolders();
  }

  /// 폴더에서 단어장 제거 - 불변성 패턴 적용
  Future<void> removeWordListFromFolder(String folderName, String wordListName) async {
    final index = _folders.indexWhere((folder) => folder.name == folderName);
    if (index == -1) {
      return;
    }

    final folder = _folders[index];
    if (!folder.wordListNames.contains(wordListName)) {
      return; // 존재하지 않는 단어장
    }

    final newFolder = folder.removeWordList(wordListName);
    final newFolders = List<Folder>.from(_folders);
    newFolders[index] = newFolder;

    _updateFolders(newFolders);
    await _saveFolders();
  }

  /// 특정 단어장이 포함된 폴더 이름 목록 반환
  List<String> getFoldersContainingWordList(String wordListName) {
    return _folders
        .where((folder) => folder.wordListNames.contains(wordListName))
        .map((folder) => folder.name)
        .toList();
  }

  /// 모든 폴더 데이터 초기화
  Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('folders');
    _updateFolders([]);
  }

  /// 내부 상태 업데이트 공통 메서드 - 일관성 유지
  void _updateFolders(List<Folder> newFolders) {
    _folders = newFolders;
    notifyListeners();
  }
}