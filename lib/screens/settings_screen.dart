import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/notification_service.dart';
import '../services/iap_service.dart';
import '../services/ad_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final Function(Locale)? onLocaleChanged;
  
  const SettingsScreen({super.key, this.onLocaleChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final IAPService _iapService = IAPService();
  final AdService _adService = AdService();
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);
  bool _notificationUseEnglish = true;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initIAP();
  }

  Future<void> _initIAP() async {
    if (!kIsWeb) {
      await _iapService.initialize();
      // 프리미엄 상태 변경 리스닝
      _iapService.premiumStream.listen((isPremium) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  Future<void> _loadSettings() async {
    await _notificationService.initialize();
    final settings = await _notificationService.getNotificationSettings();
    
    setState(() {
      _notificationsEnabled = settings['enabled'] ?? false;
      _notificationTime = TimeOfDay(
        hour: settings['hour'] ?? 8,
        minute: settings['minute'] ?? 0,
      );
      _notificationUseEnglish = settings['useEnglish'] ?? true;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(BuildContext context, bool value) async {
    final l10n = AppLocalizations.of(context);
    
    if (value) {
      final granted = await _notificationService.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.get('notification_permission_required'))),
          );
        }
        return;
      }
      
      await _notificationService.scheduleDailyNotification(
        hour: _notificationTime.hour,
        minute: _notificationTime.minute,
        useEnglish: _notificationUseEnglish,
      );
    } else {
      await _notificationService.cancelAllNotifications();
    }
    
    setState(() {
      _notificationsEnabled = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? l10n.get('notification_on') : l10n.get('notification_off')),
        ),
      );
    }
  }

  Future<void> _toggleNotificationLanguage(bool useEnglish) async {
    setState(() {
      _notificationUseEnglish = useEnglish;
    });
    
    if (_notificationsEnabled) {
      await _notificationService.scheduleDailyNotification(
        hour: _notificationTime.hour,
        minute: _notificationTime.minute,
        useEnglish: useEnglish,
      );
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('notification_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              title: const Text('English'),
              subtitle: Text(l10n.get('notification_english_desc')),
              value: true,
              groupValue: _notificationUseEnglish,
              onChanged: (value) {
                _toggleNotificationLanguage(true);
                Navigator.pop(context);
              },
            ),
            RadioListTile<bool>(
              title: Text(l10n.get('local_language')),
              subtitle: Text(l10n.get('notification_local_desc')),
              value: false,
              groupValue: _notificationUseEnglish,
              onChanged: (value) {
                _toggleNotificationLanguage(false);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _notificationTime) {
      setState(() {
        _notificationTime = picked;
      });

      if (_notificationsEnabled) {
        await _notificationService.scheduleDailyNotification(
          hour: picked.hour,
          minute: picked.minute,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.get('notification_time_changed')} ${_formatTime(picked, l10n)}'),
            ),
          );
        }
      }
    }
  }


  Future<void> _changeLanguage(BuildContext context, String langCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', langCode);
      
      // 새 언어 초기화 (즉시 빈 맵으로 초기화하여 안전하게 처리)
      // 완료를 기다리지 않고 백그라운드에서 진행
      AppLocalizations.reinitializeLanguage(langCode).catchError((e) {
        // 초기화 실패는 무시 (이미 빈 맵으로 초기화됨)
      });
      
      // 실시간으로 locale 변경
      if (widget.onLocaleChanged != null) {
        widget.onLocaleChanged!(Locale(langCode));
      }
    } catch (e) {
      // 언어 변경 실패 시에도 앱은 정상 작동
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Language change failed. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatTime(TimeOfDay time, AppLocalizations l10n) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final locale = l10n.locale.languageCode;
    
    if (locale == 'ko') {
      final period = time.period == DayPeriod.am ? '오전' : '오후';
      return '$period $hour:$minute';
    } else if (locale == 'ja') {
      final period = time.period == DayPeriod.am ? '午前' : '午後';
      return '$period $hour:$minute';
    } else if (locale == 'zh') {
      final period = time.period == DayPeriod.am ? '上午' : '下午';
      return '$period $hour:$minute';
    } else {
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('settings')),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      const SizedBox(height: 16),
                      
                      // 알림 섹션
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.get('notifications'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      // 웹에서는 알림 기능 제한 안내
                      if (kIsWeb)
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: Text(l10n.get('daily_notification')),
                          subtitle: Text(l10n.get('notification_web_unavailable')),
                        )
                      else ...[                
                        SwitchListTile(
                          title: Text(l10n.get('daily_notification')),
                          subtitle: Text(
                            _notificationsEnabled
                                ? _formatTime(_notificationTime, l10n)
                                : l10n.get('notification_off'),
                          ),
                          value: _notificationsEnabled,
                          onChanged: (value) => _toggleNotifications(context, value),
                          secondary: Icon(
                            _notificationsEnabled
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                          ),
                        ),
                        
                        ListTile(
                          leading: const Icon(Icons.access_time),
                          title: Text(l10n.get('notification_time')),
                          subtitle: Text(_formatTime(_notificationTime, l10n)),
                          trailing: const Icon(Icons.chevron_right),
                          enabled: _notificationsEnabled,
                          onTap: _notificationsEnabled ? () => _selectTime(context) : null,
                        ),
                        
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: Text(l10n.get('notification_language')),
                          subtitle: Text(_notificationUseEnglish ? 'English' : l10n.get('local_language')),
                          trailing: const Icon(Icons.chevron_right),
                          enabled: _notificationsEnabled,
                          onTap: _notificationsEnabled ? () => _showLanguageDialog(context) : null,
                        ),
                      ],
                      
                      const Divider(height: 32),
                      
                      // 프리미엄 섹션 (웹이 아닌 경우만)
                      if (!kIsWeb) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            l10n.get('premium'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        if (_iapService.isPremium)
                          ListTile(
                            leading: Icon(
                              Icons.workspace_premium,
                              color: Colors.amber[700],
                            ),
                            title: Text(l10n.get('remove_ads')),
                            subtitle: Text(l10n.get('already_premium')),
                            trailing: const Icon(Icons.check_circle, color: Colors.green),
                          )
                        else
                          ListTile(
                            leading: const Icon(Icons.remove_circle_outline),
                            title: Text(l10n.get('remove_ads')),
                            subtitle: Text(
                              _iapService.getRemoveAdsPrice() ?? l10n.get('remove_ads_desc'),
                            ),
                            trailing: _isPurchasing 
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.chevron_right),
                            onTap: _isPurchasing ? null : () => _purchaseRemoveAds(context),
                          ),
                        
                        ListTile(
                          leading: const Icon(Icons.restore),
                          title: Text(l10n.get('restore_purchases')),
                          subtitle: Text(l10n.get('restore_purchases_desc')),
                          onTap: () => _restorePurchases(context),
                        ),
                        
                        const Divider(height: 32),
                      ],
                      
                      // 언어 설정 섹션
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.get('language'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(l10n.get('app_language')),
                        trailing: DropdownButton<String>(
                          value: Localizations.localeOf(context).languageCode,
                          underline: const SizedBox(),
                          items: AppLocalizations.supportedLanguageCodes.map((langCode) {
                            final testLocale = Locale(langCode);
                            final testL10n = AppLocalizations(testLocale);
                            return DropdownMenuItem<String>(
                              value: langCode,
                              child: Text(
                                '${testL10n.languageName} (${langCode.toUpperCase()})',
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newLangCode) {
                            if (newLangCode != null) {
                              _changeLanguage(context, newLangCode);
                            }
                          },
                        ),
                      ),
                      
                      const Divider(height: 32),
                      
                      // 앱 정보 섹션
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.get('app_info'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text(l10n.get('version')),
                        subtitle: const Text('1.0.0'),
                      ),
                      
                      ListTile(
                        leading: const Icon(Icons.format_quote),
                        title: Text(l10n.get('quote_data')),
                        subtitle: Text('27,664 ${l10n.get('quotes_available')}'),
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'QuoteSpace',
                            applicationVersion: '1.0.0',
                            applicationLegalese: '© 2024 QuoteSpace',
                            children: const [
                              SizedBox(height: 16),
                              Text(
                                '27,664 quotes in 10 categories.\n\n'
                                'Categories: Happiness, Inspiration, Love, Success, Truth, Poetry, Life & Death, Romance, Science, Time',
                              ),
                            ],
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                // 배너 광고 (프리미엄이 아닌 경우)
                if (!kIsWeb && _adService.shouldShowAds)
                  const BannerAdWidget(),
              ],
            ),
    );
  }

  Future<void> _purchaseRemoveAds(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    setState(() => _isPurchasing = true);
    
    try {
      final success = await _iapService.purchaseRemoveAds();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('purchase_failed'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('purchase_failed'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _restorePurchases(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.get('restoring'))),
    );
    
    await _iapService.restorePurchases();
    
    if (mounted && _iapService.isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('purchase_success'))),
      );
    }
  }
}
