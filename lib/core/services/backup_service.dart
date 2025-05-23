// lib/core/services/backup_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:chunk_up/core/services/auth_service.dart';
import 'package:chunk_up/data/services/storage/local_storage_service.dart';
import 'package:chunk_up/core/constants/app_constants.dart';

/// 백업 상태
enum BackupStatus {
  idle,
  backing,
  restoring,
  success,
  error
}

/// 백업 서비스 - 구글 드라이브를 통한 데이터 백업 및 복원
class BackupService {
  final AuthService _authService;
  final StorageService _storageService;
  
  // 백업 파일 이름
  static const String backupFileName = 'chunk_up_backup.json';
  
  // 백업 상태
  BackupStatus _status = BackupStatus.idle;
  BackupStatus get status => _status;
  
  // 마지막 백업 시간
  DateTime? _lastBackupTime;
  DateTime? get lastBackupTime => _lastBackupTime;
  
  BackupService({
    required AuthService authService,
    required StorageService storageService,
  }) : _authService = authService,
      _storageService = storageService {
    _initialize();
  }
  
  /// 서비스 초기화
  Future<void> _initialize() async {
    // 마지막 백업 시간 로드
    final lastBackupStr = await _storageService.getString('last_backup_time');
    if (lastBackupStr != null) {
      _lastBackupTime = DateTime.parse(lastBackupStr);
    }
  }
  
  /// Google Drive API 클라이언트 가져오기
  Future<drive.DriveApi?> _getDriveApi() async {
    if (!_authService.isAuthenticated) {
      debugPrint('❌ 드라이브 API 접근 불가: 인증되지 않음');
      return null;
    }
    
    try {
      final accessToken = await _authService.getAuthToken();
      if (accessToken == null) {
        debugPrint('❌ 드라이브 API 접근 불가: 토큰 없음');
        return null;
      }
      
      final authClient = _AuthClient(accessToken);
      return drive.DriveApi(authClient);
    } catch (e) {
      debugPrint('❌ 드라이브 API 초기화 오류: $e');
      return null;
    }
  }
  
  /// 백업 파일 찾기
  Future<drive.File?> _findBackupFile(drive.DriveApi driveApi) async {
    try {
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$backupFileName'",
      );
      
      final files = fileList.files;
      if (files == null || files.isEmpty) {
        return null;
      }
      
      return files.first;
    } catch (e) {
      debugPrint('❌ 백업 파일 찾기 오류: $e');
      return null;
    }
  }
  
  /// 백업 데이터 준비
  Future<Map<String, dynamic>> _prepareBackupData() async {
    final backupData = <String, dynamic>{};
    
    // 단어장 데이터
    final wordLists = await _storageService.getString(AppConstants.wordListsStorageKey);
    if (wordLists != null) {
      backupData[AppConstants.wordListsStorageKey] = wordLists;
    }
    
    // 테스트 기록
    final testHistory = await _storageService.getString(AppConstants.testHistoryStorageKey);
    if (testHistory != null) {
      backupData[AppConstants.testHistoryStorageKey] = testHistory;
    }
    
    // 학습 기록
    final learningHistory = await _storageService.getString(AppConstants.learningHistoryStorageKey);
    if (learningHistory != null) {
      backupData[AppConstants.learningHistoryStorageKey] = learningHistory;
    }
    
    // 리뷰 알림
    final reviewReminders = await _storageService.getString(AppConstants.reviewRemindersStorageKey);
    if (reviewReminders != null) {
      backupData[AppConstants.reviewRemindersStorageKey] = reviewReminders;
    }
    
    // 폴더 설정
    final folders = await _storageService.getString(AppConstants.foldersStorageKey);
    if (folders != null) {
      backupData[AppConstants.foldersStorageKey] = folders;
    }
    
    // 사용자 정의 캐릭터
    final customCharacters = await _storageService.getString(AppConstants.customCharactersStorageKey);
    if (customCharacters != null) {
      backupData[AppConstants.customCharactersStorageKey] = customCharacters;
    }
    
    return backupData;
  }
  
  /// 백업 수행
  Future<bool> backup() async {
    if (!_authService.isAuthenticated) {
      debugPrint('❌ 백업 실패: 인증되지 않음');
      return false;
    }
    
    _status = BackupStatus.backing;
    
    try {
      // 드라이브 API 클라이언트 가져오기
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        _status = BackupStatus.error;
        return false;
      }
      
      // 백업 데이터 준비
      final backupData = await _prepareBackupData();
      final backupContent = jsonEncode(backupData);
      
      // 기존 백업 파일 찾기
      final existingFile = await _findBackupFile(driveApi);
      
      if (existingFile != null) {
        // 기존 파일 업데이트
        final updatedFile = await driveApi.files.update(
          drive.File(),
          existingFile.id!,
          uploadMedia: drive.Media(
            Stream.fromIterable([utf8.encode(backupContent)]),
            backupContent.length,
          ),
        );
        
        _lastBackupTime = DateTime.now();
        await _storageService.setString('last_backup_time', _lastBackupTime!.toIso8601String());
        
        _status = BackupStatus.success;
        debugPrint('✅ 백업 파일 업데이트 성공: ${updatedFile.id}');
        return true;
      } else {
        // 새 파일 생성
        final newFile = drive.File()
          ..name = backupFileName
          ..parents = ['appDataFolder'];
        
        final createdFile = await driveApi.files.create(
          newFile,
          uploadMedia: drive.Media(
            Stream.fromIterable([utf8.encode(backupContent)]),
            backupContent.length,
          ),
        );
        
        _lastBackupTime = DateTime.now();
        await _storageService.setString('last_backup_time', _lastBackupTime!.toIso8601String());
        
        _status = BackupStatus.success;
        debugPrint('✅ 새 백업 파일 생성 성공: ${createdFile.id}');
        return true;
      }
    } catch (e) {
      debugPrint('❌ 백업 중 오류: $e');
      _status = BackupStatus.error;
      return false;
    }
  }
  
  /// 복원 수행
  Future<bool> restore() async {
    if (!_authService.isAuthenticated) {
      debugPrint('❌ 복원 실패: 인증되지 않음');
      return false;
    }
    
    _status = BackupStatus.restoring;
    
    try {
      // 드라이브 API 클라이언트 가져오기
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        _status = BackupStatus.error;
        return false;
      }
      
      // 백업 파일 찾기
      final backupFile = await _findBackupFile(driveApi);
      if (backupFile == null) {
        debugPrint('❌ 복원 실패: 백업 파일 없음');
        _status = BackupStatus.error;
        return false;
      }
      
      // 파일 다운로드
      final fileContent = await driveApi.files.get(
        backupFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      
      // 스트림에서 문자열로 변환
      final List<int> dataList = [];
      await for (var data in fileContent.stream) {
        dataList.addAll(data);
      }
      final contentString = utf8.decode(dataList);
      
      // JSON 파싱
      final Map<String, dynamic> backupData = jsonDecode(contentString);
      
      // 로컬 스토리지에 복원
      for (final entry in backupData.entries) {
        await _storageService.setString(entry.key, entry.value);
      }
      
      _status = BackupStatus.success;
      debugPrint('✅ 데이터 복원 성공');
      return true;
    } catch (e) {
      debugPrint('❌ 복원 중 오류: $e');
      _status = BackupStatus.error;
      return false;
    }
  }
}

/// 인증 토큰으로 HTTP 요청을 보내는 클라이언트
class _AuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  _AuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}