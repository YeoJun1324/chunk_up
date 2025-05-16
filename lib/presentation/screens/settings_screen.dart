// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/presentation/providers/theme_notifier.dart'; // 테마 관리 프로바이더 추가
import 'package:chunk_up/data/datasources/remote/api_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chunk_up/core/theme/app_theme.dart'; // 앱 테마 정의 추가
import 'import_screen.dart';
import 'help_screen.dart';
import 'legal_info_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Preferences
  bool _darkMode = false;
  String _interfaceLanguage = 'ko';
  bool _showTranslation = true;
  bool _highlightWords = true;
  int _maxReviewStage = 4; // 최대 복습 단계 (기본값: 4)

  // Subscriptions
  bool _isPremium = false;
  int _remainingFreeCredits = 5;

  // App info
  String _appVersion = '';
  final String _developerEmail = 'duwns051004@gmail.com';

  // 기타 설정 필드

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // ThemeNotifier의 현재 테마 가져오기
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    setState(() {
      _darkMode = isDarkMode;
      _interfaceLanguage = prefs.getString('interfaceLanguage') ?? 'ko';
      _showTranslation = prefs.getBool('showTranslation') ?? true;
      _highlightWords = prefs.getBool('highlightWords') ?? true;
      _isPremium = prefs.getBool('isPremium') ?? false;
      _remainingFreeCredits = prefs.getInt('remainingFreeCredits') ?? 5;
      _maxReviewStage = prefs.getInt('maxReviewStage') ?? 4; // 최대 복습 단계 로드
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setString('interfaceLanguage', _interfaceLanguage);
    await prefs.setBool('showTranslation', _showTranslation);
    await prefs.setBool('highlightWords', _highlightWords);
    await prefs.setInt('maxReviewStage', _maxReviewStage); // 최대 복습 단계 저장
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }


  Future<void> _showResetConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('모든 데이터 초기화'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('정말로 모든 데이터를 초기화하시겠습니까?'),
                Text('이 작업은 되돌릴 수 없으며, 모든 단어장과 단락 데이터가 삭제됩니다.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                '초기화',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                await _resetAllData();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('모든 데이터가 초기화되었습니다.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetAllData() async {
    final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);
    await wordListNotifier.resetAllData();
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _developerEmail,
      queryParameters: {
        'subject': '[ChunkUp] 문의하기',
        'body': '앱 버전: $_appVersion\n\n문의 내용을 작성해주세요.',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이메일 앱을 열 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri privacyPolicyUri = Uri.parse('https://www.chunkup.app/privacy-policy');

    if (await canLaunchUrl(privacyPolicyUri)) {
      await launchUrl(privacyPolicyUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('웹 브라우저를 열 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchTermsOfService() async {
    final Uri tosUri = Uri.parse('https://www.chunkup.app/terms-of-service');

    if (await canLaunchUrl(tosUri)) {
      await launchUrl(tosUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('웹 브라우저를 열 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chunk Up Premium'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade300, Colors.orange.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 48,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '모든 기능 무제한 이용',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '프리미엄 혜택:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPremiumFeature(
                  icon: Icons.all_inclusive,
                  title: '무제한 단락 생성',
                  description: '단어를 원하는 만큼 문맥화 할 수 있습니다.',
                ),
                _buildPremiumFeature(
                  icon: Icons.analytics,
                  title: '학습 분석 기능',
                  description: '단어 학습 진행 상황을 자세히 분석합니다.',
                ),
                _buildPremiumFeature(
                  icon: Icons.tune,
                  title: '고급 단락 설정',
                  description: '더 세밀한 단락 생성 옵션을 제공합니다.',
                ),
                _buildPremiumFeature(
                  icon: Icons.cloud_done,
                  title: '클라우드 백업',
                  description: '데이터를 안전하게 백업하고 복원할 수 있습니다.',
                ),
                _buildPremiumFeature(
                  icon: Icons.ad_units_outlined,
                  title: '광고 제거',
                  description: '모든 광고가 제거됩니다.',
                ),
                const SizedBox(height: 16),
                const Text(
                  '월 2,990원',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '연 결제시 25% 할인',
                  style: TextStyle(
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('나중에'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('구독 기능은 현재 개발 중입니다.'),
                  ),
                );
              },
              child: const Text('구독하기'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 현재 테마 모드 확인 (다크 모드 여부)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: isDarkMode ? AppTheme.darkBackground : null,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // Profile section
            Builder(
              builder: (context) {
                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.orange.shade900.withOpacity(0.2) : Colors.orange.shade50,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.orange.shade200,
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '게스트 사용자',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _isPremium
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.workspace_premium,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Premium',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/subscription');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Premium 업그레이드'),
                            ),
                      if (!_isPremium)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '무료 크레딧: $_remainingFreeCredits개 남음',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // General settings
            const ListTile(
              title: Text(
                '일반 설정',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('다크 모드'),
              subtitle: const Text('어두운 테마 사용'),
              value: _darkMode,
              onChanged: (bool value) {
                // ThemeNotifier를 통해 테마 변경
                final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

                if (value) {
                  themeNotifier.setDarkMode();
                } else {
                  themeNotifier.setLightMode();
                }

                setState(() {
                  _darkMode = value;
                });

                // 사용자에게 변경 알림
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value ? '다크 모드가 활성화되었습니다.' : '라이트 모드가 활성화되었습니다.'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              secondary: const Icon(Icons.dark_mode),
            ),

            // 복습 관련 설정
            const Divider(),
            const ListTile(
              title: Text(
                '복습 설정',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            // 복습 단계 선택
            ListTile(
              title: const Text('복습 알림 최대 단계'),
              subtitle: _maxReviewStage == 0
                ? const Text('복습 알림이 꺼져 있습니다')
                : Text('학습 이후 최대 ${_maxReviewStage}번 복습을 진행합니다'),
              leading: const Icon(Icons.notifications_active),
              trailing: DropdownButton<int>(
                value: _maxReviewStage,
                items: [0, 1, 2, 3, 4].map((stage) {
                  String description;
                  switch (stage) {
                    case 0:
                      description = '꺼짐';
                      break;
                    case 1:
                      description = '1단계 (1일)';
                      break;
                    case 2:
                      description = '2단계 (7일)';
                      break;
                    case 3:
                      description = '3단계 (16일)';
                      break;
                    case 4:
                      description = '4단계 (35일)';
                      break;
                    default:
                      description = '${stage}단계';
                  }
                  return DropdownMenuItem<int>(
                    value: stage,
                    child: Text(description),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value != null) {
                    setState(() {
                      _maxReviewStage = value;
                    });
                    await _saveSettings();

                    // 사용자에게 변경 알림
                    if (mounted) {
                      final message = value == 0
                        ? '복습 알림이 비활성화되었습니다.'
                        : '복습 최대 단계가 ${value}단계로 설정되었습니다.';

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          duration: const Duration(seconds: 2),
                          backgroundColor: value == 0 ? Colors.orange : Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),
            ),


            // Data management
            const Divider(),
            const ListTile(
              title: Text(
                '데이터 관리',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              title: const Text('캐릭터 관리'),
              subtitle: const Text('커스텀 캐릭터 생성 및 관리'),
              leading: const Icon(Icons.person_outline),
              onTap: () {
                Navigator.pushNamed(context, '/character_management');
              },
            ),
            ListTile(
              title: const Text('엑셀에서 단어장 가져오기'),
              subtitle: const Text('기존 단어장 데이터 불러오기'),
              leading: const Icon(Icons.file_download),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('데이터 초기화'),
              subtitle: const Text('모든 단어장과 단락 데이터를 삭제합니다'),
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              onTap: _showResetConfirmationDialog,
            ),

            // AI 모델 섹션
            const Divider(),
            const ListTile(
              title: Text(
                'AI 모델',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              title: const Text('AI 모델 성능 테스트'),
              subtitle: const Text('Basic/Premium 모델 속도와 품질 비교'),
              leading: const Icon(Icons.speed),
              onTap: () {
                Navigator.pushNamed(context, '/model_test');
              },
            ),

            // About and Help
            const Divider(),
            const ListTile(
              title: Text(
                '앱 정보',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              title: const Text('앱 사용 설명서'),
              leading: const Icon(Icons.help_outline),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('앱 버전'),
              subtitle: Text(_appVersion),
              leading: const Icon(Icons.info_outline),
            ),
            ListTile(
              title: const Text('개발자에게 문의하기'),
              leading: const Icon(Icons.email_outlined),
              onTap: _launchEmail,
            ),
            ListTile(
              title: const Text('이용약관'),
              subtitle: const Text('이용약관 및 개인정보처리방침'),
              leading: const Icon(Icons.assignment_outlined),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LegalInfoScreen(),
                  ),
                );
              },
            ),

            // Credits and acknowledgments
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Powered by',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Claude 3.7 Sonnet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Anthropic',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '© 2025 ChunkUp. All rights reserved.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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
}