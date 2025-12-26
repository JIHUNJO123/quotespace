import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui' as ui;
import 'dart:ui' show ImageFilter;
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/category_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'l10n/app_localizations.dart';
import 'services/ad_service.dart';
import 'services/iap_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 웹이 아닌 경우에만 광고 및 IAP 초기화
  if (!kIsWeb) {
    await AdService().initialize();
    await IAPService().initialize();
  }
  
  // 저장된 언어 설정 로드 또는 시스템 언어 사용
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('selected_language');
  final systemLocale = ui.PlatformDispatcher.instance.locale;
  final targetLanguage = savedLanguage ?? systemLocale.languageCode;
  
  // UI 번역 초기화
  await AppLocalizations.initialize(targetLanguage);
  
  runApp(DailyQuotesApp(locale: savedLanguage != null ? Locale(savedLanguage) : null));
}

class DailyQuotesApp extends StatelessWidget {
  final Locale? locale;
  
  const DailyQuotesApp({super.key, this.locale});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuoteSpace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: const Color(0xFF00C9A7), // 틸 그린
          onPrimary: Colors.white,
          secondary: const Color(0xFFFF6B9D), // 핑크
          onSecondary: Colors.white,
          tertiary: const Color(0xFFFFC75F), // 골드
          onTertiary: Colors.white,
          error: const Color(0xFFE63946),
          onError: Colors.white,
          surface: Colors.white,
          onSurface: const Color(0xFF2D3748),
          surfaceContainerHighest: const Color(0xFFF7FAFC),
          primaryContainer: const Color(0xFFE0F7F4),
          secondaryContainer: const Color(0xFFFFE5EC),
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide.none,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: const Color(0xFF00D4AA), // 밝은 틸 그린
          onPrimary: const Color(0xFF1A1A2E),
          secondary: const Color(0xFFFF7BA3), // 밝은 핑크
          onSecondary: const Color(0xFF1A1A2E),
          tertiary: const Color(0xFFFFD93D), // 밝은 골드
          onTertiary: const Color(0xFF1A1A2E),
          error: const Color(0xFFFF6B6B),
          onError: Colors.white,
          surface: const Color(0xFF1A1A2E),
          onSurface: const Color(0xFFE8E8E8),
          surfaceContainerHighest: const Color(0xFF2D2D44),
          primaryContainer: const Color(0xFF003D35),
          secondaryContainer: const Color(0xFF4D1A2A),
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide.none,
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      
      // 다국어 지원
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoryScreen(),
    const FavoritesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          // 플로팅 네비게이션 바
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(context, 0, Icons.home_outlined, Icons.home, l10n.get('home')),
                        _buildNavItem(context, 1, Icons.category_outlined, Icons.category, l10n.get('categories')),
                        _buildNavItem(context, 2, Icons.favorite_outline, Icons.favorite, l10n.get('favorites')),
                        _buildNavItem(context, 3, Icons.settings_outlined, Icons.settings, l10n.get('settings')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavItem(BuildContext context, int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
