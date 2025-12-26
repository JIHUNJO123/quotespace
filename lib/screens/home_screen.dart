import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/quote.dart';
import '../services/quote_service.dart';
import '../services/ad_service.dart';
import '../widgets/quote_card.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final QuoteService _quoteService = QuoteService();
  final AdService _adService = AdService();
  Quote? _currentQuote;
  bool _isLoading = true;
  bool _showDailyQuote = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    await _quoteService.loadQuotes();
    setState(() {
      _selectedCategory = _quoteService.selectedCategory;
      _currentQuote = _quoteService.getDailyQuote();
      _isLoading = false;
    });
  }

  Future<void> _getNewQuote() async {
    // 보상 명언이 있으면 사용
    await _quoteService.useRewardedQuote();
    
    setState(() {
      _currentQuote = _quoteService.getRandomQuote();
      _showDailyQuote = false;
    });
  }

  Future<void> _showRewardedAd() async {
    final l10n = AppLocalizations.of(context);
    
    await _adService.showRewardedAd(
      onRewarded: (rewardAmount, rewardType) async {
        await _quoteService.addRewardedQuotes(rewardAmount);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.get('reward_received').replaceAll('{amount}', rewardAmount.toString())),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  void _showDailyQuoteAgain() {
    setState(() {
      _currentQuote = _quoteService.getDailyQuote();
      _showDailyQuote = true;
    });
  }

  Future<void> _showCategoryFilter(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final categories = _quoteService.getCategories();
    
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.get('filter_category'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.get('filter_category_desc'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 전체 선택 (필터 해제)
                ChoiceChip(
                  label: Text(l10n.get('all_categories')),
                  selected: _selectedCategory == null,
                  onSelected: (selected) async {
                    await _quoteService.setSelectedCategory(null);
                    setState(() {
                      _selectedCategory = null;
                      _currentQuote = _quoteService.getDailyQuote();
                      _showDailyQuote = true;
                    });
                    Navigator.pop(context);
                  },
                ),
                // 각 카테고리
                ...categories.map((category) => ChoiceChip(
                  label: Text(l10n.getCategory(category)),
                  selected: _selectedCategory?.toLowerCase() == category.toLowerCase(),
                  onSelected: (selected) async {
                    await _quoteService.setSelectedCategory(category);
                    setState(() {
                      _selectedCategory = category;
                      _currentQuote = _quoteService.getDailyQuote();
                      _showDailyQuote = true;
                    });
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_currentQuote != null) {
      await _quoteService.toggleFavorite(_currentQuote!);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.3, 0.7, 1.0],
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
              Theme.of(context).colorScheme.secondaryContainer,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 배경 장식 원들
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // 헤더 (비대칭 레이아웃)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _showDailyQuote ? l10n.get('daily_quote') : l10n.get('random_quote'),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _formatDate(DateTime.now(), l10n),
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_selectedCategory != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          l10n.getCategory(_selectedCategory!),
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: Theme.of(context).colorScheme.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 필터 버튼
                              IconButton(
                                onPressed: () => _showCategoryFilter(context),
                                icon: Icon(
                                  _selectedCategory != null ? Icons.filter_alt : Icons.filter_alt_outlined,
                                  color: _selectedCategory != null 
                                      ? Theme.of(context).colorScheme.primary 
                                      : null,
                                ),
                                tooltip: l10n.get('filter_category'),
                              ),
                              if (!_showDailyQuote)
                                IconButton(
                                  onPressed: _showDailyQuoteAgain,
                                  icon: const Icon(Icons.today),
                                  tooltip: l10n.get('view_daily_quote'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // 명언 카드
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: QuoteCard(
                            quote: _currentQuote!,
                            isFavorite: _quoteService.isFavorite(_currentQuote!),
                            onFavoritePressed: _toggleFavorite,
                          ),
                        ),
                      ),
                    ),
                    
                    // 새 명언 버튼 및 보상형 광고 버튼
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // 보상 명언 수 표시
                          if (_quoteService.rewardedQuotes > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.stars,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.get('rewarded_quotes_available').replaceAll('{count}', _quoteService.rewardedQuotes.toString()),
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // 새 명언 버튼
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _getNewQuote,
                              icon: const Icon(Icons.refresh),
                              label: Text(l10n.get('new_quote')),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          
                          // 보상형 광고 버튼
                          if (!kIsWeb && _adService.shouldShowAds)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: OutlinedButton.icon(
                                onPressed: _showRewardedAd,
                                icon: const Icon(Icons.play_circle_outline),
                                label: Text(l10n.get('watch_ad_for_reward')),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final locale = l10n.locale.languageCode;
    
    switch (locale) {
      case 'ko':
        const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
        return '${date.year}년 ${date.month}월 ${date.day}일 (${weekdays[date.weekday - 1]})';
      case 'ja':
        const weekdaysJa = ['月', '火', '水', '木', '金', '土', '日'];
        return '${date.year}年${date.month}月${date.day}日 (${weekdaysJa[date.weekday - 1]})';
      case 'zh':
        const weekdaysZh = ['一', '二', '三', '四', '五', '六', '日'];
        return '${date.year}年${date.month}月${date.day}日 周${weekdaysZh[date.weekday - 1]}';
      default:
        const weekdaysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${weekdaysEn[date.weekday - 1]}, ${monthsEn[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}
