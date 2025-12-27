import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // 상품 ID (앱스토어/플레이스토어에서 설정한 ID와 일치해야 함)
  static const String removeAdsProductId = 'com.quotespace.app.removeads';
  static const Set<String> _productIds = {removeAdsProductId};
  
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isPremium = false;
  
  // 구매 상태 알림
  final _premiumController = StreamController<bool>.broadcast();
  Stream<bool> get premiumStream => _premiumController.stream;
  
  bool get isPremium => _isPremium;
  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  Future<void> initialize() async {
    if (kIsWeb) return;
    
    try {
      // 저장된 프리미엄 상태 로드
      await _loadPremiumStatus();
      
      // IAP 사용 가능 여부 확인
      _isAvailable = await _inAppPurchase.isAvailable();
      if (!_isAvailable) {
        print('IAP를 사용할 수 없습니다');
        return;
      }
      
      // 구매 스트림 리스닝
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => print('구매 오류: $error'),
      );
      
      // 상품 정보 로드
      await _loadProducts();
      
      // 이전 구매 복원
      await restorePurchases();
    } catch (e) {
      print('IAPService 초기화 에러: $e');
      // 에러가 발생해도 앱이 크래시하지 않도록 함
    }
  }

  Future<void> _loadProducts() async {
    final response = await _inAppPurchase.queryProductDetails(_productIds);
    
    if (response.notFoundIDs.isNotEmpty) {
      print('상품을 찾을 수 없음: ${response.notFoundIDs}');
    }
    
    _products = response.productDetails;
    print('로드된 상품: ${_products.length}개');
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('is_premium') ?? false;
    _premiumController.add(_isPremium);
  }

  Future<void> _savePremiumStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', value);
    _isPremium = value;
    _premiumController.add(value);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      // 결제 대기 중
      print('결제 대기 중...');
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      // 결제 오류
      print('결제 오류: ${purchaseDetails.error}');
    } else if (purchaseDetails.status == PurchaseStatus.purchased ||
               purchaseDetails.status == PurchaseStatus.restored) {
      // 결제 완료 또는 복원
      if (purchaseDetails.productID == removeAdsProductId) {
        await _savePremiumStatus(true);
        print('광고 제거 구매 완료!');
      }
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      print('결제 취소됨');
    }

    // 구매 완료 처리
    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  // 광고 제거 구매
  Future<bool> purchaseRemoveAds() async {
    if (!_isAvailable || _products.isEmpty) {
      print('상품을 사용할 수 없습니다');
      return false;
    }

    final product = _products.firstWhere(
      (p) => p.id == removeAdsProductId,
      orElse: () => throw Exception('상품을 찾을 수 없습니다'),
    );

    final purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      final success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      return success;
    } catch (e) {
      print('구매 실패: $e');
      return false;
    }
  }

  // 구매 복원
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    await _inAppPurchase.restorePurchases();
  }

  // 가격 가져오기
  String? getRemoveAdsPrice() {
    if (_products.isEmpty) return null;
    
    try {
      final product = _products.firstWhere(
        (p) => p.id == removeAdsProductId,
      );
      return product.price;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _premiumController.close();
  }
}
