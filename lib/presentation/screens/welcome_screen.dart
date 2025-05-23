import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chunk_up/presentation/widgets/privacy_policy_dialog.dart';
import 'package:chunk_up/presentation/widgets/terms_of_service_dialog.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _agreedToPrivacyPolicy = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _checkPreviousAgreements();
  }

  Future<void> _checkPreviousAgreements() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _agreedToPrivacyPolicy = prefs.getBool('agreed_to_privacy_policy') ?? false;
      _agreedToTerms = prefs.getBool('agreed_to_terms') ?? false;
    });
  }

  Future<void> _saveAgreement(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _showPrivacyPolicyDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const PrivacyPolicyDialog(),
    );

    if (result == true) {
      setState(() {
        _agreedToPrivacyPolicy = true;
      });
      await _saveAgreement('agreed_to_privacy_policy', true);
    }
  }

  Future<void> _showTermsOfServiceDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const TermsOfServiceDialog(),
    );

    if (result == true) {
      setState(() {
        _agreedToTerms = true;
      });
      await _saveAgreement('agreed_to_terms', true);
    }
  }

  void _navigateToMainApp() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade300,
              Colors.orange.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // 앱 로고
              Image.asset(
                'assets/icons/app_icon.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 24),
              
              // 앱 이름
              const Text(
                'Chunk Up',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              // 앱 설명
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  '맥락으로 배우는 단어 학습 앱',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // 동의 체크박스
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    _buildAgreementRow(
                      'privacy_policy',
                      '개인정보 처리방침에 동의합니다',
                      _agreedToPrivacyPolicy,
                      _showPrivacyPolicyDialog,
                    ),
                    const SizedBox(height: 12),
                    _buildAgreementRow(
                      'terms',
                      '이용약관에 동의합니다',
                      _agreedToTerms,
                      _showTermsOfServiceDialog,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 시작하기 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_agreedToPrivacyPolicy && _agreedToTerms)
                        ? _navigateToMainApp
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '시작하기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgreementRow(
    String key,
    String text,
    bool isChecked,
    VoidCallback onTap,
  ) {
    return Row(
      children: [
        Checkbox(
          value: isChecked,
          onChanged: (bool? value) {
            if (value == true) {
              onTap();
            } else {
              // 체크 해제는 허용하지 않음
            }
          },
          activeColor: Colors.white,
          checkColor: Colors.orange.shade700,
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}