import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  final Locale locale;
  static Map<String, Map<String, String>> _dynamicTranslations = {};
  static Set<String> _initializedLanguages = {};

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // 앱 시작 시 번역 로드
  static Future<void> initialize(String langCode) async {
    try {
      // 이미 초기화된 언어는 스킵
      if (_initializedLanguages.contains(langCode) &&
          _dynamicTranslations.containsKey(langCode)) {
        return;
      }

      // 수동 번역이 있는 언어는 스킵
      if (_localizedValues.containsKey(langCode)) {
        _initializedLanguages.add(langCode);
        return;
      }

      // 동적 번역이 필요한 언어는 먼저 초기화 완료로 표시 (영어로 폴백)
      // 이렇게 하면 앱이 즉시 시작되고, 번역은 백그라운드에서 로드됨
      _initializedLanguages.add(langCode);
      if (!_dynamicTranslations.containsKey(langCode)) {
        _dynamicTranslations[langCode] = {};
      }

      // 캐시에서 로드 시도
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('ui_translations_$langCode');

      if (cached != null) {
        try {
          final decoded = Map<String, String>.from(json.decode(cached));
          if (decoded.isNotEmpty) {
            _dynamicTranslations[langCode] = decoded;
            return;
          }
        } catch (e) {
          // 캐시 파싱 실패 시 무시하고 API로 재시도
        }
      }

      // API로 번역 (백그라운드에서, 실패해도 앱은 정상 작동)
      _translateUIStrings(langCode).catchError((e) {
        // API 실패는 무시 (이미 빈 맵으로 초기화됨)
      });
    } catch (e) {
      // 모든 예외를 잡아서 앱이 크래시하지 않도록 함
      _initializedLanguages.add(langCode);
      if (!_dynamicTranslations.containsKey(langCode)) {
        _dynamicTranslations[langCode] = {};
      }
    }
  }

  // 언어 변경 시 해당 언어 초기화 강제
  static Future<void> reinitializeLanguage(String langCode) async {
    try {
      // 먼저 빈 맵으로 초기화하여 앱이 정상 작동하도록 보장
      _initializedLanguages.add(langCode);
      _dynamicTranslations[langCode] = {};

      // 캐시에서 로드 시도
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('ui_translations_$langCode');

      if (cached != null) {
        try {
          final decoded = Map<String, String>.from(json.decode(cached));
          if (decoded.isNotEmpty) {
            _dynamicTranslations[langCode] = decoded;
            return;
          }
        } catch (e) {
          // 캐시 파싱 실패 시 무시하고 API로 재시도
        }
      }

      // API로 번역 (백그라운드에서, 실패해도 앱은 정상 작동)
      _translateUIStrings(langCode).catchError((e) {
        // API 실패는 무시 (이미 빈 맵으로 초기화됨)
      });
    } catch (e) {
      // 모든 예외를 잡아서 앱이 크래시하지 않도록 함
      _initializedLanguages.add(langCode);
      if (!_dynamicTranslations.containsKey(langCode)) {
        _dynamicTranslations[langCode] = {};
      }
    }
  }

  // UI 문자열 자동 번역
  static Future<void> _translateUIStrings(String langCode) async {
    try {
      final englishStrings = _localizedValues['en']!;
      final translated = <String, String>{};

      // 배치로 번역 (API 호출 최소화)
      for (final entry in englishStrings.entries) {
        try {
          final result = await _translateText(entry.value, langCode);
          translated[entry.key] = result ?? entry.value;
        } catch (e) {
          translated[entry.key] = entry.value; // 실패 시 영어 유지
        }
      }

      _dynamicTranslations[langCode] = translated;

      // 캐시에 저장 (실패해도 계속 진행)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'ui_translations_$langCode', json.encode(translated));
      } catch (e) {
        // 캐시 저장 실패는 무시
      }
    } catch (e) {
      // 전체 번역 실패 시 빈 맵이라도 설정 (영어로 폴백)
      _dynamicTranslations[langCode] = {};
    }
  }

  static Future<String?> _translateText(String text, String targetLang) async {
    try {
      final url = Uri.parse(
          'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=en|$targetLang');

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translation = data['responseData']['translatedText'];

        if (translation != null &&
            !translation
                .toString()
                .toUpperCase()
                .contains('MYMEMORY WARNING')) {
          return translation;
        }
      }
    } catch (e) {
      // 무시
    }
    return null;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'home': 'Home',
      'categories': 'Categories',
      'favorites': 'Favorites',
      'settings': 'Settings',

      // Home Screen
      'daily_quote': "Today's Quote",
      'random_quote': 'Random Quote',
      'new_quote': 'New Quote',
      'view_daily_quote': 'View Daily Quote',
      'filter_category': 'Filter by Category',
      'filter_category_desc':
          'Select a category to see quotes only from that topic',
      'all_categories': 'All Categories',

      // Categories
      'happiness': 'Happiness',
      'inspiration': 'Inspiration',
      'love': 'Love',
      'success': 'Success',
      'truth': 'Truth',
      'poetry': 'Poetry',
      'death': 'Life & Death',
      'romance': 'Romance',
      'science': 'Science',
      'time': 'Time',
      'quotes_count': 'quotes',

      // Favorites
      'no_favorites': 'No favorite quotes yet',
      'add_favorites_hint': 'Tap the heart icon on quotes you love',

      // Actions
      'share': 'Share',
      'copy': 'Copy',
      'copied_to_clipboard': 'Copied to clipboard',

      // Settings
      'notifications': 'Notifications',
      'daily_notification': 'Daily Quote Notification',
      'notification_time': 'Notification Time',
      'notification_language': 'Notification Language',
      'notification_english_desc': 'Receive quotes in English',
      'notification_local_desc': 'Receive notification title in your language',
      'local_language': 'Local Language',
      'notification_on': 'Notification enabled',
      'notification_off': 'Notification disabled',
      'notification_time_changed': 'Notification time changed to',
      'notification_permission_required': 'Notification permission required',
      'app_info': 'App Info',
      'version': 'Version',
      'quote_data': 'Quote Data',
      'quotes_available': 'quotes available',

      // Translation
      'translation': 'Translation',
      'show_translation': 'Show Translation',
      'hide_translation': 'Hide Translation',
      'translating': 'Translating...',
      'auto_translate': 'Auto Translate',
      'auto_translate_desc': 'Automatically translate quotes to your language',
      'notification_web_unavailable':
          'Notifications are only available on mobile devices',

      // IAP
      'premium': 'Premium',
      'remove_ads': 'Remove Ads',
      'remove_ads_desc': 'Enjoy ad-free experience',
      'restore_purchases': 'Restore Purchases',
      'restore_purchases_desc':
          'Restore previous purchases on this device or after reinstalling the app',
      'purchase_success': 'Purchase successful! Ads removed.',
      'purchase_failed': 'Purchase failed. Please try again.',
      'already_premium': 'You already have premium!',
      'restoring': 'Restoring purchases...',

      // Rewarded Ads
      'watch_ad_for_reward': 'Watch Ad for 10 Free Quotes',
      'reward_received': 'You received {amount} free quotes!',
      'rewarded_quotes_available': '{count} free quotes available',
      'unlimited_access_granted': 'Unlimited access granted until midnight!',

      // Language
      'language': 'Language',
      'app_language': 'App Language',
      'select_language': 'Select Language',
      'language_changed_restart': 'Language changed. Please restart the app.',
      'restart_app': 'Restart',
    },
    'ko': {
      // Navigation
      'home': '홈',
      'categories': '카테고리',
      'favorites': '즐겨찾기',
      'settings': '설정',

      // Home Screen
      'daily_quote': '오늘의 명언',
      'random_quote': '랜덤 명언',
      'new_quote': '새로운 명언 보기',
      'view_daily_quote': '오늘의 명언 보기',
      'filter_category': '카테고리 필터',
      'filter_category_desc': '원하는 주제의 명언만 볼 수 있습니다',
      'all_categories': '전체 카테고리',

      // Categories
      'happiness': '행복',
      'inspiration': '영감',
      'love': '사랑',
      'success': '성공',
      'truth': '진실',
      'poetry': '시',
      'death': '삶과 죽음',
      'romance': '로맨스',
      'science': '과학',
      'time': '시간',
      'quotes_count': '개의 명언',

      // Favorites
      'no_favorites': '즐겨찾기한 명언이 없습니다',
      'add_favorites_hint': '마음에 드는 명언에 하트를 눌러보세요',

      // Actions
      'share': '공유',
      'copy': '복사',
      'copied_to_clipboard': '클립보드에 복사되었습니다',

      // Settings
      'notifications': '알림',
      'daily_notification': '매일 명언 알림',
      'notification_time': '알림 시간',
      'notification_language': '알림 언어',
      'notification_english_desc': '영어로 명언 받기',
      'notification_local_desc': '알림 제목을 한국어로 받기',
      'local_language': '한국어',
      'notification_on': '알림이 설정되었습니다',
      'notification_off': '알림이 해제되었습니다',
      'notification_time_changed': '알림 시간이 변경되었습니다:',
      'notification_permission_required': '알림 권한이 필요합니다',
      'app_info': '앱 정보',
      'version': '버전',
      'quote_data': '명언 데이터',
      'quotes_available': '개의 명언',

      // Translation
      'translation': '번역',
      'show_translation': '번역 보기',
      'hide_translation': '번역 숨기기',
      'translating': '번역 중...',
      'auto_translate': '자동 번역',
      'auto_translate_desc': '명언을 자동으로 번역하여 표시합니다',
      'notification_web_unavailable': '알림은 모바일 기기에서만 사용 가능합니다',

      // IAP
      'premium': '프리미엄',
      'remove_ads': '광고 제거',
      'remove_ads_desc': '광고 없이 앱을 즐기세요',
      'restore_purchases': '구매 복원',
      'restore_purchases_desc': '이전에 구매한 항목을 이 기기에서 복원하거나, 앱 재설치 후 복원할 때 사용하세요',
      'purchase_success': '구매 완료! 광고가 제거되었습니다.',
      'purchase_failed': '구매 실패. 다시 시도해주세요.',
      'already_premium': '이미 프리미엄 사용자입니다!',
      'restoring': '구매 복원 중...',

      // Rewarded Ads
      'watch_ad_for_reward': '광고 시청하고 명언 10개 받기',
      'reward_received': '명언 {amount}개를 받았습니다!',
      'rewarded_quotes_available': '무료 명언 {count}개 사용 가능',

      // Language
      'language': '언어',
      'app_language': '앱 언어',
      'select_language': '언어 선택',
      'language_changed_restart': '언어가 변경되었습니다. 앱을 재시작해주세요.',
      'restart_app': '재시작',
    },
    'ja': {
      'home': 'ホーム',
      'categories': 'カテゴリー',
      'favorites': 'お気に入り',
      'settings': '設定',
      'daily_quote': '今日の名言',
      'random_quote': 'ランダム名言',
      'new_quote': '新しい名言を見る',
      'view_daily_quote': '今日の名言を見る',
      'filter_category': 'カテゴリーフィルター',
      'filter_category_desc': '特定のカテゴリーの名言だけを見ることができます',
      'all_categories': 'すべてのカテゴリー',
      'happiness': '幸福',
      'inspiration': 'インスピレーション',
      'love': '愛',
      'success': '成功',
      'truth': '真実',
      'poetry': '詩',
      'death': '生と死',
      'romance': 'ロマンス',
      'science': '科学',
      'time': '時間',
      'quotes_count': '件の名言',
      'no_favorites': 'お気に入りの名言がありません',
      'add_favorites_hint': '好きな名言のハートをタップしてください',
      'share': '共有',
      'copy': 'コピー',
      'copied_to_clipboard': 'クリップボードにコピーしました',
      'notifications': '通知',
      'daily_notification': '毎日の名言通知',
      'notification_time': '通知時間',
      'notification_language': '通知言語',
      'notification_english_desc': '英語で名言を受け取る',
      'notification_local_desc': '通知タイトルを日本語で受け取る',
      'local_language': '日本語',
      'notification_on': '通知が設定されました',
      'notification_off': '通知が解除されました',
      'notification_time_changed': '通知時間が変更されました:',
      'notification_permission_required': '通知権限が必要です',
      'app_info': 'アプリ情報',
      'version': 'バージョン',
      'quote_data': '名言データ',
      'quotes_available': '件の名言',
      'translation': '翻訳',
      'show_translation': '翻訳を表示',
      'hide_translation': '翻訳を非表示',
      'translating': '翻訳中...',
      'auto_translate': '自動翻訳',
      'auto_translate_desc': '名言を自動的に翻訳して表示します',
      'notification_web_unavailable': '通知はモバイル端末でのみ利用可能です',
      'premium': 'プレミアム',
      'remove_ads': '広告を削除',
      'remove_ads_desc': '広告なしでアプリをお楽しみください',
      'restore_purchases': '購入を復元',
      'restore_purchases_desc': '以前の購入をこのデバイスで復元、またはアプリ再インストール後に復元する場合に使用',
      'purchase_success': '購入完了！広告が削除されました。',
      'purchase_failed': '購入に失敗しました。もう一度お試しください。',
      'already_premium': 'すでにプレミアムです！',
      'restoring': '購入を復元中...',

      // Rewarded Ads
      'watch_ad_for_reward': '広告を見て名言10個を獲得',
      'reward_received': '名言{amount}個を獲得しました！',
      'rewarded_quotes_available': '無料名言{count}個利用可能',

      // Language
      'language': '言語',
      'app_language': 'アプリ言語',
      'select_language': '言語を選択',
      'language_changed_restart': '言語が変更されました。アプリを再起動してください。',
      'restart_app': '再起動',
    },
    'zh': {
      'home': '首页',
      'categories': '分类',
      'favorites': '收藏',
      'settings': '设置',
      'daily_quote': '今日名言',
      'random_quote': '随机名言',
      'new_quote': '查看新名言',
      'view_daily_quote': '查看今日名言',
      'filter_category': '分类筛选',
      'filter_category_desc': '选择一个分类，只查看该主题的名言',
      'all_categories': '全部分类',
      'happiness': '幸福',
      'inspiration': '灵感',
      'love': '爱情',
      'success': '成功',
      'truth': '真理',
      'poetry': '诗歌',
      'death': '生死',
      'romance': '浪漫',
      'science': '科学',
      'time': '时间',
      'quotes_count': '条名言',
      'no_favorites': '还没有收藏的名言',
      'add_favorites_hint': '点击喜欢的名言的心形图标',
      'share': '分享',
      'copy': '复制',
      'copied_to_clipboard': '已复制到剪贴板',
      'notifications': '通知',
      'daily_notification': '每日名言通知',
      'notification_time': '通知时间',
      'notification_language': '通知语言',
      'notification_english_desc': '用英语接收名言',
      'notification_local_desc': '用中文接收通知标题',
      'local_language': '中文',
      'notification_on': '通知已开启',
      'notification_off': '通知已关闭',
      'notification_time_changed': '通知时间已更改为:',
      'notification_permission_required': '需要通知权限',
      'app_info': '应用信息',
      'version': '版本',
      'quote_data': '名言数据',
      'quotes_available': '条名言',
      'translation': '翻译',
      'show_translation': '显示翻译',
      'hide_translation': '隐藏翻译',
      'translating': '翻译中...',
      'auto_translate': '自动翻译',
      'auto_translate_desc': '自动将名言翻译为您的语言',
      'notification_web_unavailable': '通知仅在移动设备上可用',
      'premium': '高级版',
      'remove_ads': '移除广告',
      'remove_ads_desc': '享受无广告体验',
      'restore_purchases': '恢复购买',
      'restore_purchases_desc': '在此设备上恢复之前的购买，或在重新安装应用后恢复',
      'purchase_success': '购买成功！广告已移除。',
      'purchase_failed': '购买失败，请重试。',
      'already_premium': '您已经是高级用户！',
      'restoring': '正在恢复购买...',

      // Rewarded Ads
      'watch_ad_for_reward': '观看广告获得10条免费名言',
      'reward_received': '您获得了{amount}条免费名言！',
      'rewarded_quotes_available': '还有{count}条免费名言可用',

      // Language
      'language': '语言',
      'app_language': '应用语言',
      'select_language': '选择语言',
      'language_changed_restart': '语言已更改。请重启应用。',
      'restart_app': '重启',
    },
    'es': {
      'home': 'Inicio',
      'categories': 'Categorías',
      'favorites': 'Favoritos',
      'settings': 'Ajustes',
      'daily_quote': 'Cita del día',
      'random_quote': 'Cita aleatoria',
      'new_quote': 'Nueva cita',
      'view_daily_quote': 'Ver cita del día',
      'happiness': 'Felicidad',
      'inspiration': 'Inspiración',
      'love': 'Amor',
      'success': 'Éxito',
      'truth': 'Verdad',
      'poetry': 'Poesía',
      'death': 'Vida y muerte',
      'romance': 'Romance',
      'science': 'Ciencia',
      'time': 'Tiempo',
      'quotes_count': 'citas',
      'no_favorites': 'No hay citas favoritas',
      'add_favorites_hint': 'Toca el corazón en las citas que te gusten',
      'share': 'Compartir',
      'copy': 'Copiar',
      'copied_to_clipboard': 'Copiado al portapapeles',
      'notifications': 'Notificaciones',
      'daily_notification': 'Notificación diaria',
      'notification_time': 'Hora de notificación',
      'notification_on': 'Notificación activada',
      'notification_off': 'Notificación desactivada',
      'notification_time_changed': 'Hora cambiada a:',
      'notification_permission_required': 'Se requiere permiso de notificación',
      'app_info': 'Info de la app',
      'version': 'Versión',
      'quote_data': 'Datos de citas',
      'quotes_available': 'citas disponibles',
      'translation': 'Traducción',
      'show_translation': 'Mostrar traducción',
      'hide_translation': 'Ocultar traducción',
      'translating': 'Traduciendo...',
      'auto_translate': 'Traducción automática',
      'auto_translate_desc': 'Traducir automáticamente las citas a su idioma',
      'notification_web_unavailable':
          'Las notificaciones solo están disponibles en dispositivos móviles',
      'premium': 'Premium',
      'remove_ads': 'Eliminar anuncios',
      'remove_ads_desc': 'Disfruta sin anuncios',
      'restore_purchases': 'Restaurar compras',
      'purchase_success': '¡Compra exitosa! Anuncios eliminados.',
      'purchase_failed': 'Compra fallida. Inténtalo de nuevo.',
      'already_premium': '¡Ya tienes premium!',
      'restoring': 'Restaurando compras...',

      // Rewarded Ads
      'watch_ad_for_reward': 'Ver anuncio para 10 citas gratis',
      'reward_received': '¡Recibiste {amount} citas gratis!',
      'rewarded_quotes_available': '{count} citas gratis disponibles',

      // Language
      'language': 'Idioma',
      'app_language': 'Idioma de la app',
      'select_language': 'Seleccionar idioma',
      'language_changed_restart': 'Idioma cambiado. Por favor reinicia la app.',
      'restart_app': 'Reiniciar',
    },
    'fr': {
      // Navigation
      'home': 'Accueil',
      'categories': 'Catégories',
      'favorites': 'Favoris',
      'settings': 'Paramètres',

      // Home Screen
      'daily_quote': 'Citation du jour',
      'random_quote': 'Citation aléatoire',
      'new_quote': 'Nouvelle citation',
      'view_daily_quote': 'Voir la citation du jour',
      'filter_category': 'Filtrer par catégorie',
      'filter_category_desc':
          'Sélectionnez une catégorie pour voir uniquement ces citations',
      'all_categories': 'Toutes les catégories',

      // Categories
      'happiness': 'Bonheur',
      'inspiration': 'Inspiration',
      'love': 'Amour',
      'success': 'Succès',
      'truth': 'Vérité',
      'poetry': 'Poésie',
      'death': 'Vie et mort',
      'romance': 'Romance',
      'science': 'Science',
      'time': 'Temps',
      'quotes_count': 'citations',

      // Favorites
      'no_favorites': 'Pas encore de citations favorites',
      'add_favorites_hint': 'Appuyez sur le cœur des citations que vous aimez',

      // Actions
      'share': 'Partager',
      'copy': 'Copier',
      'copied_to_clipboard': 'Copié dans le presse-papiers',

      // Settings
      'notifications': 'Notifications',
      'daily_notification': 'Notification quotidienne',
      'notification_time': 'Heure de notification',
      'notification_language': 'Langue de notification',
      'notification_english_desc': 'Recevoir les citations en anglais',
      'notification_local_desc': 'Recevoir le titre en français',
      'local_language': 'Français',
      'notification_on': 'Notification activée',
      'notification_off': 'Notification désactivée',
      'notification_time_changed': 'Heure modifiée à:',
      'notification_permission_required': 'Permission de notification requise',
      'app_info': 'Info de l\'app',
      'version': 'Version',
      'quote_data': 'Données des citations',
      'quotes_available': 'citations disponibles',

      // Translation
      'translation': 'Traduction',
      'show_translation': 'Afficher la traduction',
      'hide_translation': 'Masquer la traduction',
      'translating': 'Traduction en cours...',
      'auto_translate': 'Traduction automatique',
      'auto_translate_desc': 'Traduire automatiquement les citations',
      'notification_web_unavailable':
          'Les notifications ne sont disponibles que sur mobile',

      // IAP
      'premium': 'Premium',
      'remove_ads': 'Supprimer les publicités',
      'remove_ads_desc': 'Profitez sans publicités',
      'restore_purchases': 'Restaurer les achats',
      'restore_purchases_desc':
          'Restaurer les achats précédents sur cet appareil',
      'purchase_success': 'Achat réussi! Publicités supprimées.',
      'purchase_failed': 'Achat échoué. Veuillez réessayer.',
      'already_premium': 'Vous êtes déjà premium!',
      'restoring': 'Restauration en cours...',

      // Rewarded Ads
      'watch_ad_for_reward': 'Regarder une pub pour 10 citations gratuites',
      'reward_received': 'Vous avez reçu {amount} citations gratuites!',
      'rewarded_quotes_available': '{count} citations gratuites disponibles',

      // Language
      'language': 'Langue',
      'app_language': 'Langue de l\'app',
      'select_language': 'Sélectionner la langue',
      'language_changed_restart':
          'Langue modifiée. Veuillez redémarrer l\'app.',
      'restart_app': 'Redémarrer',
    },
    'pt': {
      // Navigation
      'home': 'Início',
      'categories': 'Categorias',
      'favorites': 'Favoritos',
      'settings': 'Configurações',

      // Home Screen
      'daily_quote': 'Citação do dia',
      'random_quote': 'Citação aleatória',
      'new_quote': 'Nova citação',
      'view_daily_quote': 'Ver citação do dia',
      'filter_category': 'Filtrar por categoria',
      'filter_category_desc':
          'Selecione uma categoria para ver apenas essas citações',
      'all_categories': 'Todas as categorias',

      // Categories
      'happiness': 'Felicidade',
      'inspiration': 'Inspiração',
      'love': 'Amor',
      'success': 'Sucesso',
      'truth': 'Verdade',
      'poetry': 'Poesia',
      'death': 'Vida e morte',
      'romance': 'Romance',
      'science': 'Ciência',
      'time': 'Tempo',
      'quotes_count': 'citações',

      // Favorites
      'no_favorites': 'Ainda não há citações favoritas',
      'add_favorites_hint': 'Toque no coração das citações que você gosta',

      // Actions
      'share': 'Compartilhar',
      'copy': 'Copiar',
      'copied_to_clipboard': 'Copiado para a área de transferência',

      // Settings
      'notifications': 'Notificações',
      'daily_notification': 'Notificação diária',
      'notification_time': 'Hora da notificação',
      'notification_language': 'Idioma da notificação',
      'notification_english_desc': 'Receber citações em inglês',
      'notification_local_desc': 'Receber título em português',
      'local_language': 'Português',
      'notification_on': 'Notificação ativada',
      'notification_off': 'Notificação desativada',
      'notification_time_changed': 'Hora alterada para:',
      'notification_permission_required': 'Permissão de notificação necessária',
      'app_info': 'Info do app',
      'version': 'Versão',
      'quote_data': 'Dados das citações',
      'quotes_available': 'citações disponíveis',

      // Translation
      'translation': 'Tradução',
      'show_translation': 'Mostrar tradução',
      'hide_translation': 'Ocultar tradução',
      'translating': 'Traduzindo...',
      'auto_translate': 'Tradução automática',
      'auto_translate_desc': 'Traduzir citações automaticamente',
      'notification_web_unavailable':
          'Notificações disponíveis apenas em dispositivos móveis',

      // IAP
      'premium': 'Premium',
      'remove_ads': 'Remover anúncios',
      'remove_ads_desc': 'Aproveite sem anúncios',
      'restore_purchases': 'Restaurar compras',
      'restore_purchases_desc':
          'Restaurar compras anteriores neste dispositivo',
      'purchase_success': 'Compra realizada! Anúncios removidos.',
      'purchase_failed': 'Compra falhou. Tente novamente.',
      'already_premium': 'Você já é premium!',
      'restoring': 'Restaurando compras...',

      // Rewarded Ads
      'watch_ad_for_reward': 'Assista um anúncio para 10 citações grátis',
      'reward_received': 'Você recebeu {amount} citações grátis!',
      'rewarded_quotes_available': '{count} citações grátis disponíveis',

      // Language
      'language': 'Idioma',
      'app_language': 'Idioma do app',
      'select_language': 'Selecionar idioma',
      'language_changed_restart': 'Idioma alterado. Reinicie o app.',
      'restart_app': 'Reiniciar',
    },
  };

  String get(String key) {
    final langCode = locale.languageCode;

    // 1. 수동 번역 확인
    if (_localizedValues.containsKey(langCode)) {
      return _localizedValues[langCode]?[key] ??
          _localizedValues['en']?[key] ??
          key;
    }

    // 2. 동적 번역 확인 (값이 있어야 함)
    if (_dynamicTranslations.containsKey(langCode)) {
      final translations = _dynamicTranslations[langCode];
      if (translations != null &&
          translations.isNotEmpty &&
          translations.containsKey(key)) {
        return translations[key] ?? _localizedValues['en']?[key] ?? key;
      }
    }

    // 3. 기본값 (영어)
    return _localizedValues['en']?[key] ?? key;
  }

  String getCategory(String category) {
    return get(category.toLowerCase());
  }

  // 모든 언어 지원 (동적 번역 포함)
  static List<Locale> get supportedLocales {
    return _allLanguageCodes.map((code) => Locale(code)).toList();
  }

  // 수동 번역된 언어
  static List<String> get manuallyTranslatedLanguages =>
      ['en', 'ko', 'ja', 'zh', 'es', 'fr', 'pt'];

  // 모든 지원 언어 코드
  static List<String> get _allLanguageCodes => _languageNames.keys.toList();

  static List<String> get supportedLanguageCodes => _allLanguageCodes;

  // 주요 언어 6개 + 영어 (GPT-4o mini로 미리 번역된 언어)
  static const Map<String, String> _languageNames = {
    'en': 'English',
    'ko': '한국어',
    'ja': '日本語',
    'zh': '中文',
    'es': 'Español',
    'fr': 'Français',
    'pt': 'Português',
  };

  String get languageName {
    return _languageNames[locale.languageCode] ??
        _languageNames['en'] ??
        locale.languageCode.toUpperCase();
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLanguageCodes
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
