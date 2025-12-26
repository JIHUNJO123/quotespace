import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' show ImageFilter;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quote.dart';
import '../services/quote_service.dart';
import '../services/ad_service.dart';
import '../widgets/quote_card.dart';
import '../l10n/app_localizations.dart';

class QuoteListScreen extends StatefulWidget {
  final String title;
  final List<Quote> quotes;

  const QuoteListScreen({
    super.key,
    required this.title,
    required this.quotes,
  });

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  final QuoteService _quoteService = QuoteService();
  final AdService _adService = AdService();
  final ScrollController _scrollController = ScrollController();
  bool _hasRestoredScroll = false;
  bool _hasUnlimitedAccess = false;

  @override
  void initState() {
    super.initState();
    _restoreScrollPosition();
    _checkUnlimitedAccess();
  }

  Future<void> _checkUnlimitedAccess() async {
    final hasAccess = await _quoteService.hasUnlimitedAccess();
    setState(() {
      _hasUnlimitedAccess = hasAccess;
    });
  }

  Future<void> _handleQuoteTap(Quote quote) async {
    // 무제한 접근 권한이 있으면 바로 표시
    if (_hasUnlimitedAccess) {
      _showQuoteDetail(quote);
      return;
    }

    // 락되지 않은 명언은 바로 표시
    if (!_quoteService.isQuoteLocked(quote)) {
      _showQuoteDetail(quote);
      return;
    }

    // 락된 명언은 광고를 먼저 표시 (명언은 광고 시청 후에만 표시)
    final l10n = AppLocalizations.of(context);

    if (kIsWeb) {
      // 웹에서는 광고 대신 안내 메시지 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('광고 시청 필요'),
          content: const Text('이 명언을 보려면 모바일 앱에서 광고를 시청해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    // 보상형 광고를 먼저 표시 (명언은 광고 시청 완료 후에만 표시)
    try {
      await _adService.showRewardedAd(
        onRewarded: (rewardAmount, rewardType) async {
          // 광고 시청 완료 후에만 실행됨
          // 자정까지 무제한 접근 권한 부여
          await _quoteService.grantUnlimitedAccessUntilMidnight();
          await _checkUnlimitedAccess();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.get('unlimited_access_granted')),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            // 광고 시청 완료 후 명언 표시
            _showQuoteDetail(quote);
          }
        },
      );
    } catch (e) {
      // 광고 표시 실패 시 사용자에게 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('광고를 불러올 수 없습니다. 잠시 후 다시 시도해주세요.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showQuoteDetail(Quote quote) {
    // 명언 상세 보기 (간단한 다이얼로그)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quote.author),
        content: SingleChildScrollView(
          child: Text(
            quote.text,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreScrollPosition() async {
    if (_hasRestoredScroll) return;

    final prefs = await SharedPreferences.getInstance();
    final scrollOffset = prefs.getDouble('scroll_${widget.title}') ?? 0.0;

    if (scrollOffset > 0 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(scrollOffset);
          _hasRestoredScroll = true;
        }
      });
    } else {
      _hasRestoredScroll = true;
    }
  }

  Future<void> _saveScrollPosition() async {
    if (!_scrollController.hasClients) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('scroll_${widget.title}', _scrollController.offset);
  }

  @override
  void dispose() {
    _saveScrollPosition();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(Quote quote) async {
    await _quoteService.toggleFavorite(quote);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 무제한 접근 권한 표시
          if (_hasUnlimitedAccess)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.get('unlimited_access_until_midnight'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: widget.quotes.length,
              itemBuilder: (context, index) {
                final quote = widget.quotes[index];
                final isLocked =
                    !_hasUnlimitedAccess && _quoteService.isQuoteLocked(quote);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _handleQuoteTap(quote),
                    child: Stack(
                      children: [
                        // 명언 카드 (락된 경우 완전히 블러 처리)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            children: [
                              QuoteCard(
                                quote: quote,
                                isFavorite: _quoteService.isFavorite(quote),
                                onFavoritePressed: () => _toggleFavorite(quote),
                                compact: true,
                              ),
                              if (isLocked)
                                Positioned.fill(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 15, sigmaY: 15),
                                    child: Container(
                                      color: Colors.black.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // 락 오버레이 (명언 내용 완전히 가림)
                        if (isLocked)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.get('watch_ad_unlock'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        l10n.get('tap_to_watch_ad'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
