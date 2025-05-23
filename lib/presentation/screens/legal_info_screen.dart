import 'package:flutter/material.dart';
import 'package:chunk_up/presentation/screens/terms_and_privacy_screen.dart';

class LegalInfoScreen extends StatelessWidget {
  const LegalInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용약관'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이용약관',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '청크업(Chunk Up) 앱의 사용과 관련된 이용약관 및 개인정보처리방침을 확인하세요.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            _buildLegalInfoItem(
              context,
              '이용약관 및 개인정보처리방침',
              '앱 서비스 이용 약관 및 개인정보 수집·이용 정책을 확인합니다',
              Icons.description_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsAndPrivacyScreen(),
                ),
              ),
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
}