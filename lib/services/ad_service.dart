import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInitialized = false;
  bool _isPremium = false;
  
  // 보상형 광고 콜백
  Function(int rewardAmount, String rewardType)? _onRewarded;
  bool _adWasShown = false; // 광고가 실제로 표시되었는지 추적

  // 프리미엄 상태 확인
  bool get isPremium => _isPremium;
  
  // 프리미엄 상태 설정 (IAP에서 호출)
  set isPremium(bool value) {
    _isPremium = value;
    _savePremiumStatus(value);
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('is_premium') ?? false;
  }

  Future<void> _savePremiumStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', value);
  }

  // 실제 광고 ID
  static String get bannerAdUnitId {
    if (kIsWeb) return ''; // 웹은 지원 안함
    if (Platform.isAndroid) {
      return 'ca-app-pub-5837885590326347/9922573116'; // Android 배너
    } else if (Platform.isIOS) {
      return 'ca-app-pub-5837885590326347/7915179264'; // iOS 배너
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-5837885590326347/5847596734'; // Android 전면
    } else if (Platform.isIOS) {
      return 'ca-app-pub-5837885590326347/3664286522'; // iOS 전면
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-5837885590326347/6752195239'; // Android 보상형 전면
    } else if (Platform.isIOS) {
      return 'ca-app-pub-5837885590326347/8065276902'; // iOS 보상형 전면
    }
    return '';
  }

  // 플랫폼이 광고를 지원하는지 확인 (프리미엄이면 광고 안 보임)
  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  bool get shouldShowAds => isSupported && !_isPremium;

  Future<void> initialize() async {
    if (!isSupported || _isInitialized) return;

    await _loadPremiumStatus();
    
    if (_isPremium) {
      _isInitialized = true;
      return; // 프리미엄 사용자는 광고 로드 안함
    }

    await MobileAds.instance.initialize();
    _isInitialized = true;
    
    // 보상형 광고 미리 로드
    await loadRewardedAd();
  }

  // 배너 광고 로드
  Future<void> loadBannerAd() async {
    if (!shouldShowAds) return;

    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('배너 광고 로드됨');
        },
        onAdFailedToLoad: (ad, error) {
          print('배너 광고 로드 실패: $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );

    await _bannerAd?.load();
  }

  // 전면 광고 로드
  Future<void> loadInterstitialAd() async {
    if (!shouldShowAds) return;

    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          print('전면 광고 로드됨');
        },
        onAdFailedToLoad: (error) {
          print('전면 광고 로드 실패: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  // 배너 광고 가져오기
  BannerAd? get bannerAd => _bannerAd;

  // 더 이상 사용하지 않음 (보상형 광고로 대체)

  // 보상형 광고 로드
  Future<void> loadRewardedAd() async {
    if (!shouldShowAds) return;

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          print('보상형 광고 로드됨');
        },
        onAdFailedToLoad: (error) {
          print('보상형 광고 로드 실패: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  // 보상형 광고 표시
  Future<void> showRewardedAd({
    required Function(int rewardAmount, String rewardType) onRewarded,
  }) async {
    _adWasShown = false;
    
    if (!shouldShowAds) {
      // 프리미엄 사용자에게는 보상 제공
      _adWasShown = true; // 프리미엄은 광고 없이 보상 제공
      onRewarded(10, 'quotes');
      return;
    }
    
    if (_rewardedAd == null) {
      await loadRewardedAd();
      if (_rewardedAd == null) {
        // 광고 로드 실패 시 보상 제공하지 않음
        print('광고 로드 실패: 보상을 제공하지 않습니다');
        return;
      }
    }

    _onRewarded = onRewarded;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        // 광고가 실제로 표시됨
        _adWasShown = true;
        print('보상형 광고 표시됨');
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd(); // 다음 광고 미리 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('광고 표시 실패: $error');
        ad.dispose();
        loadRewardedAd();
        _adWasShown = false;
        // 실패 시 보상 제공하지 않음
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        // 광고 시청 완료 후에만 보상 지급
        if (_onRewarded != null && _adWasShown) {
          _onRewarded!(reward.amount.toInt(), reward.type);
        }
      },
    );
    _rewardedAd = null;
    _onRewarded = null;
  }

  // 보상형 광고 준비 여부 확인
  bool get isRewardedAdReady => _rewardedAd != null;

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
