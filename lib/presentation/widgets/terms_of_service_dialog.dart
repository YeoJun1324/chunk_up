import 'package:flutter/material.dart';
import 'package:chunk_up/presentation/screens/terms_of_service_screen.dart';

class TermsOfServiceDialog extends StatelessWidget {
  const TermsOfServiceDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('이용약관 동의'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '청크업(Chunk Up) 앱을 사용하기 위해서는 이용약관에 동의해야 합니다.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '주요 내용:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint('앱 및 콘텐츠에 대한 지식재산권은 회사에 귀속됩니다.'),
            _buildBulletPoint('사용자는 앱을 불법적인 목적으로 사용할 수 없습니다.'),
            _buildBulletPoint('사용자가 생성한 콘텐츠의 저작권은 사용자에게 있습니다.'),
            _buildBulletPoint('앱 서비스는 기술적 문제로 일시 중단될 수 있습니다.'),
            _buildBulletPoint('무료로 제공되는 서비스의 손해에 대해 회사는 책임을 지지 않습니다.'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsOfServiceScreen(),
                  ),
                );
              },
              child: const Text(
                '전체 이용약관 보기',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('동의하지 않음'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('동의함'),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}