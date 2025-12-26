import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show ImageFilter;
import 'package:google_fonts/google_fonts.dart';
import '../models/quote.dart';
import '../l10n/app_localizations.dart';
import '../services/translation_service.dart';

class QuoteCard extends StatefulWidget {
  final Quote quote;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final bool compact;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.isFavorite,
    required this.onFavoritePressed,
    this.compact = false,
  });

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  final TranslationService _translationService = TranslationService();
  String? _translation;
  bool _isTranslating = false;
  bool _showTranslation = true; // 기본적으로 번역 표시
  String? _currentLangCode;

  @override
  void initState() {
    super.initState();
    // TranslationService 번역 데이터 로드
    _translationService.loadTranslations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final langCode = Localizations.localeOf(context).languageCode;

    // 언어가 바뀌었거나 명언이 바뀌었을 때 자동 번역
    if (langCode != _currentLangCode || _translation == null) {
      _currentLangCode = langCode;
      if (langCode != 'en') {
        _loadTranslation(langCode);
      }
    }
  }

  @override
  void didUpdateWidget(covariant QuoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 명언이 바뀌면 번역 상태 초기화
    if (oldWidget.quote.text != widget.quote.text) {
      setState(() {
        _translation = null;
        _isTranslating = false;
      });
      // 새로운 명언 자동 번역
      final langCode = Localizations.localeOf(context).languageCode;
      if (langCode != 'en') {
        _loadTranslation(langCode);
      }
    }
  }

  void _copyToClipboard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(
      text: '"${widget.quote.text}"\n\n- ${widget.quote.author}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.get('copied_to_clipboard')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadTranslation(String langCode) async {
    if (langCode == 'en' || _translation != null) return;

    setState(() => _isTranslating = true);

    // 내장 번역 데이터에서 찾기
    final translation = await _translationService.getTranslation(
      widget.quote.text,
      widget.quote.id,
      langCode,
    );

    if (translation != null) {
      setState(() {
        _translation = translation;
        _isTranslating = false;
      });
      return;
    }

    // 번역을 찾지 못한 경우
    setState(() {
      _translation = null;
      _isTranslating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final showTranslateButton = langCode != 'en';

    return Container(
      margin: EdgeInsets.all(widget.compact ? 8 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.9),
            Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(-10, -10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onLongPress: () => _copyToClipboard(context),
              child: Container(
                padding: EdgeInsets.all(widget.compact ? 18 : 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 스크롤 가능한 명언 영역
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 영어 원문
                      Text(
                        widget.quote.text,
                        style: GoogleFonts.merriweather(
                          fontSize: widget.compact ? 14 : 17,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // 번역 표시 (자동으로 표시, 영어가 아닌 경우)
                      if (showTranslateButton &&
                          _showTranslation &&
                          _translation != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.translate,
                                    size: 14,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.get('translation'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _translation!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontSize: widget.compact ? 13 : 15,
                                      height: 1.5,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_isTranslating) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.get('translating')),
                          ],
                        ),
                      ],

                      SizedBox(height: widget.compact ? 10 : 16),

                      // 저자
                      Text(
                        widget.quote.author,
                        style: GoogleFonts.lora(
                          fontSize: widget.compact ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: widget.compact ? 8 : 14),

              // 액션 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: widget.onFavoritePressed,
                    icon: Icon(
                      widget.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.isFavorite ? Colors.red : null,
                    ),
                    tooltip: l10n.get('favorites'),
                  ),
                  // 번역 토글 버튼 (영어가 아닌 경우만)
                  if (showTranslateButton)
                    IconButton(
                      onPressed: () {
                        setState(() => _showTranslation = !_showTranslation);
                      },
                      icon: Icon(
                        _showTranslation
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: _showTranslation
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      tooltip: _showTranslation
                          ? l10n.get('hide_translation')
                          : l10n.get('show_translation'),
                    ),
                  IconButton(
                    onPressed: () => _copyToClipboard(context),
                    icon: const Icon(Icons.copy),
                    tooltip: l10n.get('copy'),
                  ),
                ],
              ),
            ],
          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
