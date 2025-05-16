import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Freezed 패키지 도입 도움말 화면
class FreezedHelpScreen extends StatelessWidget {
  const FreezedHelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Freezed 패키지 도입 가이드'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildStepsCard(context),
            const SizedBox(height: 24),
            _buildCodeExampleCard(context),
            const SizedBox(height: 24),
            _buildAdditionalResourcesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Freezed 패키지란?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Freezed는 Flutter 및 Dart 애플리케이션에서 불변성(immutability)을 쉽게 구현할 수 있게 해주는 코드 생성 패키지입니다. '
              '복잡한 코드를 직접 작성하지 않고도 불변 객체, toString(), 동등성 검사, 복사 메서드 등을 자동으로 생성할 수 있습니다.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              '주요 특징:',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text('• 불변 객체 생성\n• 자동 생성된 copyWith() 메서드\n• 유니온 타입 및 패턴 매칭\n• JSON 직렬화 통합\n• 코드 간소화'),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Freezed 코드 생성하기',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '이 앱에는 이미 Freezed 패키지가 설정되어 있으며, 아래 명령어를 실행하여 코드를 생성할 수 있습니다:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'flutter pub run build_runner build --delete-conflicting-outputs',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(
                        text: 'flutter pub run build_runner build --delete-conflicting-outputs',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('명령어가 클립보드에 복사되었습니다')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '코드 생성이 완료되면 다음 파일들이 생성됩니다:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '• lib/domain/models/freezed/word.freezed.dart\n'
              '• lib/domain/models/freezed/word.g.dart\n'
              '• lib/domain/models/freezed/chunk.freezed.dart\n'
              '• lib/domain/models/freezed/chunk.g.dart\n'
              '• lib/presentation/providers/riverpod/word_list_state.freezed.dart\n'
              '• lib/presentation/providers/riverpod/word_list_state.g.dart',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeExampleCard(BuildContext context) {
    const codeExample = '''
// 불변 클래스 정의 예시
@freezed
class Word with _\$Word {
  const Word._(); // 커스텀 메서드를 위한 생성자
  
  const factory Word({
    required String english,
    required String korean,
    @Default(false) bool isInChunk,
    @Default(0.0) double learningProgress,
  }) = _Word;
  
  factory Word.fromJson(Map<String, dynamic> json) => _\$WordFromJson(json);
  
  // 커스텀 메서드 추가
  int get progressPercent => (learningProgress * 100).toInt();
}

// 사용 예시
final word = Word(english: 'hello', korean: '안녕하세요');
final updatedWord = word.copyWith(learningProgress: 0.5);
print(updatedWord.progressPercent); // 50 출력
''';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Freezed 사용 예시',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      codeExample,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: codeExample));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('코드 예시가 클립보드에 복사되었습니다')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalResourcesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '추가 리소스',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '• Freezed 패키지: https://pub.dev/packages/freezed\n'
              '• JSON Serializable: https://pub.dev/packages/json_serializable\n'
              '• Riverpod: https://pub.dev/packages/flutter_riverpod\n'
              '• 불변성 패턴: https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            SizedBox(height: 16),
            Text(
              '코드 생성이 완료되면 Riverpod 예제 기능을 완전히 사용할 수 있습니다.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}