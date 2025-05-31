// lib/core/services/auth_service_extended.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase 인증 서비스 확장
class AuthServiceExtended {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthServiceExtended({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// 현재 사용자
  User? get currentUser => _auth.currentUser;

  /// 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();


  /// 이메일/비밀번호로 회원가입
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('📧 이메일 회원가입 시도: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        debugPrint('✅ 회원가입 성공: ${credential.user!.uid}');
        
        // Firestore에 사용자 데이터 초기화
        await _initializeUserData(credential.user!, email: email);
      }

      return credential;
    } catch (e) {
      debugPrint('❌ 회원가입 실패: $e');
      return null;
    }
  }

  /// 이메일/비밀번호로 로그인
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔑 이메일 로그인 시도: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        debugPrint('✅ 로그인 성공: ${credential.user!.uid}');
      }

      return credential;
    } catch (e) {
      debugPrint('❌ 로그인 실패: $e');
      return null;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      debugPrint('👋 로그아웃 시도 중...');
      await _auth.signOut();
      debugPrint('✅ 로그아웃 성공');
    } catch (e) {
      debugPrint('❌ 로그아웃 실패: $e');
    }
  }

  /// 사용자 데이터 초기화 (Firestore)
  Future<void> _initializeUserData(User user, {String? email}) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      // 이미 존재하는 사용자는 업데이트하지 않음
      if (docSnapshot.exists) {
        debugPrint('📋 기존 사용자 데이터 발견, 초기화 스킵');
        return;
      }

      // 새 사용자 데이터 생성
      final userData = {
        'uid': user.uid,
        'email': email ?? user.email,
        'isAnonymous': user.isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'subscription': {
          'tier': 'free',
          'startDate': FieldValue.serverTimestamp(),
        },
        'settings': {
          'language': 'ko',
          'notifications': true,
        },
        'stats': {
          'totalChunksGenerated': 0,
          'totalWordsLearned': 0,
          'totalTestsTaken': 0,
        }
      };

      await userDoc.set(userData);
      debugPrint('✅ 사용자 데이터 초기화 완료');
    } catch (e) {
      debugPrint('❌ 사용자 데이터 초기화 실패: $e');
    }
  }

  /// 사용자 프로필 업데이트
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = currentUser;
      if (user == null) return;

      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);

      // Firestore에도 업데이트
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
        'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ 사용자 프로필 업데이트 완료');
    } catch (e) {
      debugPrint('❌ 사용자 프로필 업데이트 실패: $e');
    }
  }

  /// 사용자 데이터 가져오기
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('❌ 사용자 데이터 가져오기 실패: $e');
      return null;
    }
  }

  /// 사용자 데이터 스트림
  Stream<DocumentSnapshot<Map<String, dynamic>>?> getUserDataStream() {
    final user = currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  /// 계정 삭제
  Future<bool> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Firestore 데이터 삭제
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Firebase Auth 계정 삭제
      await user.delete();

      debugPrint('✅ 계정 삭제 완료');
      return true;
    } catch (e) {
      debugPrint('❌ 계정 삭제 실패: $e');
      return false;
    }
  }

  /// 비밀번호 재설정 이메일 전송
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ 비밀번호 재설정 이메일 전송 완료');
      return true;
    } catch (e) {
      debugPrint('❌ 비밀번호 재설정 이메일 전송 실패: $e');
      return false;
    }
  }

  /// 자동 로그인 (앱 시작 시)
  Future<bool> initializeAuth() async {
    try {
      debugPrint('🔄 인증 상태 확인 중...');
      
      final user = currentUser;
      if (user == null) {
        debugPrint('❌ 로그인된 사용자 없음');
        return false;
      }

      debugPrint('✅ 기존 로그인 상태 유지: ${user.uid}');
      
      // 마지막 로그인 시간 업데이트
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('❌ 인증 초기화 실패: $e');
      return false;
    }
  }

  /// Google 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔐 Google 로그인 시도 중...');
      
      // Google 로그인 플로우 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('❌ Google 로그인 취소됨');
        return null;
      }

      debugPrint('🔐 Google 인증 정보 가져오는 중...');
      
      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase용 credential 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase로 로그인
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        debugPrint('✅ Google 로그인 성공: ${userCredential.user!.email}');
        
        // 사용자 데이터 초기화
        await _initializeUserData(
          userCredential.user!,
          email: userCredential.user!.email,
        );
        
        return userCredential;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Google 로그인 실패: $e');
      return null;
    }
  }

  /// Google 계정 연결 (기존 익명 계정을 Google 계정과 연결)
  Future<UserCredential?> linkWithGoogle() async {
    try {
      final user = currentUser;
      if (user == null || !user.isAnonymous) {
        debugPrint('❌ 연결할 수 있는 익명 계정이 없음');
        return null;
      }

      debugPrint('🔐 Google 계정 연결 시도 중...');
      
      // Google 로그인 플로우 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('❌ Google 계정 연결 취소됨');
        return null;
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase용 credential 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 익명 계정에 Google 계정 연결
      final userCredential = await user.linkWithCredential(credential);

      if (userCredential.user != null) {
        debugPrint('✅ Google 계정 연결 성공: ${userCredential.user!.email}');
        
        // 사용자 데이터 업데이트 (익명에서 실명으로)
        await _firestore.collection('users').doc(user.uid).update({
          'email': userCredential.user!.email,
          'displayName': userCredential.user!.displayName,
          'photoURL': userCredential.user!.photoURL,
          'isAnonymous': false,
          'linkedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        return userCredential;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Google 계정 연결 실패: $e');
      return null;
    }
  }

  /// 로그아웃 (Google 포함)
  Future<void> signOutWithGoogle() async {
    try {
      // Google 로그아웃
      await _googleSignIn.signOut();
      
      // Firebase 로그아웃
      await _auth.signOut();
      
      debugPrint('✅ Google 로그아웃 성공');
    } catch (e) {
      debugPrint('❌ Google 로그아웃 실패: $e');
    }
  }

  /// 이메일/비밀번호 회원가입
  Future<UserCredential?> signUpWithEmailPassword(String email, String password) async {
    try {
      debugPrint('🔐 이메일 회원가입 시도 중: $email');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        debugPrint('✅ 이메일 회원가입 성공: $email');
        
        // 사용자 데이터 초기화
        await _initializeUserData(credential.user!, email: email);
        
        return credential;
      }

      return null;
    } catch (e) {
      debugPrint('❌ 이메일 회원가입 실패: $e');
      return null;
    }
  }

  /// 이메일/비밀번호 로그인
  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      debugPrint('🔐 이메일 로그인 시도 중: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        debugPrint('✅ 이메일 로그인 성공: $email');
        
        // 마지막 로그인 시간 업데이트
        await _firestore.collection('users').doc(credential.user!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        
        return credential;
      }

      return null;
    } catch (e) {
      debugPrint('❌ 이메일 로그인 실패: $e');
      return null;
    }
  }

  /// 현재 사용자가 익명 사용자인지 확인
  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  /// 현재 사용자가 Google 계정으로 로그인했는지 확인
  bool get isGoogleUser {
    final user = currentUser;
    if (user == null) return false;
    
    return user.providerData.any((info) => info.providerId == 'google.com');
  }

  /// 현재 사용자가 이메일 계정으로 로그인했는지 확인
  bool get isEmailUser {
    final user = currentUser;
    if (user == null) return false;
    
    return user.providerData.any((info) => info.providerId == 'password');
  }
}