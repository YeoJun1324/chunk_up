import 'package:flutter/material.dart';
import 'package:chunk_up/presentation/screens/privacy_policy_screen.dart';
import 'package:chunk_up/presentation/screens/terms_of_service_screen.dart';

class LegalInfoScreen extends StatelessWidget {
  const LegalInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('법적 정보'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '법적 정보',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '청크업(Chunk Up) 앱의 사용과 관련된 법적 정보를 확인하세요.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            _buildLegalInfoItem(
              context,
              '개인정보 처리방침',
              '개인정보 수집, 이용, 보호에 관한 정책을 확인합니다',
              Icons.privacy_tip_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              ),
            ),
            const Divider(),
            _buildLegalInfoItem(
              context,
              '이용약관',
              '앱 서비스 이용에 관한 약관을 확인합니다',
              Icons.description_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              ),
            ),
            const Divider(),
            _buildLegalInfoItem(
              context,
              '오픈소스 라이선스',
              '사용된 오픈소스 라이브러리 및 라이선스를 확인합니다',
              Icons.source_outlined,
              () => showLicensePage(
                context: context,
                applicationName: '청크업(Chunk Up)',
                applicationVersion: '1.0.0',
                applicationIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 48,
                    height: 48,
                  ),
                ),
              ),
            ),
            const Divider(),
            _buildLegalInfoItem(
              context,
              '문의하기',
              '법적 정보에 관한 문의사항이 있으면 연락주세요',
              Icons.email_outlined,
              () => _showContactDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalInfoItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      leading: Icon(
        icon,
        size: 28,
        color: Theme.of(context).primaryColor,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문의하기'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('법적 정보 관련 문의사항은 아래 이메일로 연락해주세요:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, size: 20),
                SizedBox(width: 8),
                Text(
                  'legal@chunkup.com',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.support_agent, size: 20),
                SizedBox(width: 8),
                Text(
                  'support@chunkup.com',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}