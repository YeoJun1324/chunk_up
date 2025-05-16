// lib/core/services/ad_service.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:chunk_up/core/constants/subscription_constants.dart';

/// 광고 서비스 - AdMob 광고 처리
class AdService {
  // 광고 초기화 여부
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  // 리워드 광고 로드 상태
  bool _isRewardedAdLoaded = false;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  
  // 광고 객체
  BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;
  
  // 배너 광고 로드 완료 여부
  bool _isBannerAdLoaded = false;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  
  /// AdMob 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ AdMob 초기화 성공');
      
      // 첫 광고 준비
      await loadRewardedAd();
    } catch (e) {
      debugPrint('❌ AdMob 초기화 오류: $e');
    }
  }
  
  /// 배너 광고 ID 가져오기
  String get _bannerAdUnitId {
    if (kDebugMode) {
      // 테스트 광고 ID 사용
      if (Platform.isAndroid) {
        return SubscriptionConstants.androidBannerAdUnitId;
      } else if (Platform.isIOS) {
        return SubscriptionConstants.iosBannerAdUnitId;
      }
    }
    
    // TODO: 실제 앱에서는 실제 광고 ID 사용
    if (Platform.isAndroid) {
      return SubscriptionConstants.androidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return SubscriptionConstants.iosBannerAdUnitId;
    }
    
    throw UnsupportedError('지원되지 않는 플랫폼');
  }
  
  /// 리워드 광고 ID 가져오기
  String get _rewardedAdUnitId {
    if (kDebugMode) {
      // 테스트 광고 ID 사용
      if (Platform.isAndroid) {
        return SubscriptionConstants.androidRewardedAdUnitId;
      } else if (Platform.isIOS) {
        return SubscriptionConstants.iosRewardedAdUnitId;
      }
    }
    
    // TODO: 실제 앱에서는 실제 광고 ID 사용
    if (Platform.isAndroid) {
      return SubscriptionConstants.androidRewardedAdUnitId;
    } else if (Platform.isIOS) {
      return SubscriptionConstants.iosRewardedAdUnitId;
    }
    
    throw UnsupportedError('지원되지 않는 플랫폼');
  }
  
  /// 배너 광고 로드
  Future<void> loadBannerAd() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_bannerAd != null) {
      await _bannerAd!.dispose();
      _bannerAd = null;
      _isBannerAdLoaded = false;
    }
    
    try {
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerAdLoaded = true;
            debugPrint('✅ 배너 광고 로드 성공');
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _bannerAd = null;
            _isBannerAdLoaded = false;
            debugPrint('❌ 배너 광고 로드 실패: ${error.message}');
          },
          onAdOpened: (ad) => debugPrint('배너 광고 열림'),
          onAdClosed: (ad) => debugPrint('배너 광고 닫힘'),
        ),
      );
      
      await _bannerAd!.load();
    } catch (e) {
      debugPrint('❌ 배너 광고 로드 중 오류: $e');
    }
  }
  
  /// 배너 광고 위젯 가져오기
  Widget? getBannerAdWidget() {
    if (!_isInitialized || _bannerAd == null || !_isBannerAdLoaded) {
      return null;
    }
    
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
  
  /// 리워드 광고 로드
  Future<void> loadRewardedAd() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_rewardedAd != null) {
      await _rewardedAd!.dispose();
      _rewardedAd = null;
      _isRewardedAdLoaded = false;
    }
    
    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            debugPrint('✅ 리워드 광고 로드 성공');
            
            // 광고가 자동으로 닫힐 때(full reward) 콜백 설정
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _rewardedAd = null;
                _isRewardedAdLoaded = false;
                loadRewardedAd(); // 광고가 보여진 후 새 광고 다시 로드
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _rewardedAd = null;
                _isRewardedAdLoaded = false;
                debugPrint('❌ 리워드 광고 표시 실패: ${error.message}');
                loadRewardedAd(); // 실패 시 새 광고 다시 로드
              },
            );
          },
          onAdFailedToLoad: (error) {
            _rewardedAd = null;
            _isRewardedAdLoaded = false;
            debugPrint('❌ 리워드 광고 로드 실패: ${error.message}');
            
            // 일정 시간 후 다시 로드 시도
            Future.delayed(const Duration(minutes: 1), () {
              loadRewardedAd();
            });
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ 리워드 광고 로드 중 오류: $e');
    }
  }
  
  /// 리워드 광고 표시
  Future<bool> showRewardedAd({
    required Function onRewarded,
    required Function onFailed,
  }) async {
    if (!_isInitialized || _rewardedAd == null || !_isRewardedAdLoaded) {
      onFailed();
      return false;
    }
    
    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (_, reward) {
          debugPrint('✅ 리워드 획득: ${reward.amount} ${reward.type}');
          onRewarded();
        }
      );
      return true;
    } catch (e) {
      debugPrint('❌ 리워드 광고 표시 중 오류: $e');
      onFailed();
      return false;
    }
  }
  
  /// 리소스 해제
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd = null;
    _rewardedAd = null;
    _isBannerAdLoaded = false;
    _isRewardedAdLoaded = false;
  }
}