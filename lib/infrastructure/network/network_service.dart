// lib/core/services/network_service.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 애플리케이션의 네트워크 연결 상태를 관리하는 서비스
class NetworkService {
  // Singleton pattern
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();
  
  final Connectivity _connectivity = Connectivity();
  late StreamController<List<ConnectivityResult>> _connectivityStreamController;
  
  /// 네트워크 연결 상태 변경 스트림
  Stream<List<ConnectivityResult>> get onConnectivityChanged => 
    _connectivityStreamController.stream;
  
  /// 네트워크 서비스 초기화
  Future<void> initialize() async {
    _connectivityStreamController = StreamController.broadcast();
    
    // 초기 연결 상태 확인
    List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    _connectivityStreamController.add(results);

    // 연결 상태 변경 감지
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _connectivityStreamController.add(results);
    });
  }

  /// 현재 네트워크 연결 여부 확인
  Future<bool> isConnected() async {
    try {
      // 기본 연결 확인 방법
      final results = await _connectivity.checkConnectivity();
      if (results.any((result) => result != ConnectivityResult.none)) {
        return true;
      }
      
      // 실제 인터넷 연결 확인 (보조 방법)
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// 리소스 해제
  void dispose() {
    _connectivityStreamController.close();
  }
}