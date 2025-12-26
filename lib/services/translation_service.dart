import 'dart:convert';
import 'package:flutter/services.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  // 내장 번역 데이터 (quote_id -> translations)
  static Map<int, Map<String, String>>? _embeddedTranslations;
  static bool _isLoaded = false;

  // 지원 언어 (주요 6개 언어 + 영어)
  static const List<String> supportedLanguages = [
    'en', // English (원본)
    'ko', // 한국어
    'ja', // 日本語
    'zh', // 中文
    'es', // Español
    'fr', // Français
    'pt', // Português
  ];

  // 번역 데이터 로드
  Future<void> loadTranslations() async {
    if (_isLoaded) return;

    try {
      final String jsonString =
          await rootBundle.loadString('assets/quotes_translations.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      _embeddedTranslations = {};
      jsonData.forEach((quoteIdStr, data) {
        final quoteId = int.parse(quoteIdStr);
        final translations =
            Map<String, String>.from(data['translations'] ?? {});
        _embeddedTranslations![quoteId] = translations;
      });

      _isLoaded = true;
      print('Loaded ${_embeddedTranslations!.length} quote translations');
    } catch (e) {
      // 번역 파일이 없어도 앱은 정상 작동 (영어만 표시)
      print('Translation file not found or error loading: $e');
      print('App will work without translations (English only)');
      _embeddedTranslations = {};
      _isLoaded = true;
    }
  }

  // 번역 가져오기 (quote_id와 텍스트로 검색)
  Future<String?> getTranslation(
      String text, int? quoteId, String targetLang) async {
    // 영어면 번역 필요 없음
    if (targetLang == 'en') return null;

    // 지원하지 않는 언어면 null 반환
    if (!supportedLanguages.contains(targetLang)) return null;

    // 빈 텍스트 체크
    if (text.trim().isEmpty) return null;

    // 번역 데이터가 로드되지 않았으면 로드
    if (!_isLoaded) {
      await loadTranslations();
    }

    // quote_id로 번역 찾기 (가장 정확)
    if (quoteId != null && _embeddedTranslations != null) {
      final translations = _embeddedTranslations![quoteId];
      if (translations != null && translations.containsKey(targetLang)) {
        return translations[targetLang];
      }
    }

    // quote_id가 없거나 찾지 못한 경우 null 반환
    // (quote_id를 사용하는 것이 가장 정확함)
    return null;
  }

  // 지원 언어인지 확인
  static bool isLanguageSupported(String langCode) {
    return supportedLanguages.contains(langCode);
  }
}
