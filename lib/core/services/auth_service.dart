// lib/core/services/auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chunk_up/data/services/storage/local_storage_service.dart';
import 'package:chunk_up/core/constants/subscription_constants.dart';

/// 인증 서비스 상태
enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  error
}

/// 사용자 정보 클래스
class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  
  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });
  
  /// JSON 변환 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }
  
  /// JSON에서 객체 생성
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}

/// 인증 서비스 - 구글 로그인 및 사용자 인증 처리
class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );
  
  final StorageService _storageService;
  
  // 인증 상태 변경 이벤트를 위한 스트림 컨트롤러
  final _authStatusController = StreamController<AuthStatus>.broadcast();
  Stream<AuthStatus> get authStatusStream => _authStatusController.stream;
  
  // 현재 인증 상태 및 사용자 정보
  AuthStatus _status = AuthStatus.unauthenticated;
  AuthStatus get status => _status;
  
  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;
  
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  
  // 로그인 시도 중
  bool _isSigningIn = false;
  bool get isSigningIn => _isSigningIn;
  
  // 구글 계정 오브젝트(API 접근용)
  GoogleSignInAccount? _googleAccount;
  GoogleSignInAccount? get googleAccount => _googleAccount;
  
  AuthService({
    required StorageService storageService,
  }) : _storageService = storageService {
    _initialize();
  }
  
  /// 서비스 초기화
  Future<void> _initialize() async {
    try {
      // 저장된 사용자 정보 로드
      await _loadUserProfile();
      
      // 구글 계정이 이미 로그인되어 있는지 확인
      _googleAccount = await _googleSignIn.signInSilently();
      
      if (_googleAccount != null) {
        await _updateUserProfile(_googleAccount!);
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
      
      _authStatusController.add(_status);
    } catch (e) {
      debugPrint('❌ 인증 서비스 초기화 오류: $e');
      _status = AuthStatus.error;
      _authStatusController.add(_status);
    }
  }
  
  /// 저장된 사용자 정보 로드
  Future<void> _loadUserProfile() async {
    try {
      final userJson = await _storageService.getString(SubscriptionConstants.userIdKey);
      
      if (userJson != null) {
        final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(
          jsonDecode(userJson) as Map
        );
        _userProfile = UserProfile.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('❌ 사용자 정보 로드 중 오류: $e');
    }
  }
  
  /// 사용자 정보 저장
  Future<void> _saveUserProfile(UserProfile profile) async {
    try {
      final jsonMap = profile.toJson();
      await _storageService.setString(
        SubscriptionConstants.userIdKey,
        jsonEncode(jsonMap),
      );
    } catch (e) {
      debugPrint('❌ 사용자 정보 저장 중 오류: $e');
    }
  }
  
  /// 구글 계정에서 사용자 정보 업데이트
  Future<void> _updateUserProfile(GoogleSignInAccount account) async {
    _userProfile = UserProfile(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
    
    await _saveUserProfile(_userProfile!);
  }
  
  /// 구글 로그인 수행
  Future<bool> signInWithGoogle() async {
    if (_isSigningIn) return false;
    
    try {
      _isSigningIn = true;
      _status = AuthStatus.authenticating;
      _authStatusController.add(_status);
      
      // 구글 로그인 다이얼로그 표시
      final account = await _googleSignIn.signIn();
      
      if (account == null) {
        // 사용자가 로그인 취소
        _status = AuthStatus.unauthenticated;
        _authStatusController.add(_status);
        _isSigningIn = false;
        return false;
      }
      
      _googleAccount = account;
      await _updateUserProfile(account);
      
      _status = AuthStatus.authenticated;
      _authStatusController.add(_status);
      _isSigningIn = false;
      
      debugPrint('✅ 구글 로그인 성공: ${account.email}');
      return true;
    } catch (e) {
      debugPrint('❌ 구글 로그인 오류: $e');
      _status = AuthStatus.error;
      _authStatusController.add(_status);
      _isSigningIn = false;
      return false;
    }
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _googleAccount = null;
      _userProfile = null;
      _status = AuthStatus.unauthenticated;
      _authStatusController.add(_status);
      
      debugPrint('✅ 로그아웃 성공');
    } catch (e) {
      debugPrint('❌ 로그아웃 오류: $e');
    }
  }
  
  /// 인증 토큰 가져오기
  Future<String?> getAuthToken() async {
    if (_googleAccount == null) {
      return null;
    }
    
    try {
      final googleAuth = await _googleAccount!.authentication;
      return googleAuth.accessToken;
    } catch (e) {
      debugPrint('❌ 인증 토큰 가져오기 오류: $e');
      return null;
    }
  }
  
  /// 리소스 해제
  void dispose() {
    _authStatusController.close();
  }
}