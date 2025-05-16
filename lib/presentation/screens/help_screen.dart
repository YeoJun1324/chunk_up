// lib/screens/help_screen.dart
import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('도움말'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpHeader(context),
              const Divider(),
              _buildHelpSection(
                context,
                'ChunkUp 활용 가이드',
                [
                  '💡 좋아하는 캐릭터를 선택하세요: 셜록 홈즈, 해리 포터 같은 캐릭터들을 활용하면 더 몰입감 있는 학습이 가능합니다.',
                  '💡 학습 목표에 맞춰 세부 사항을 입력하세요: 특정 문법(과거완료, 관계대명사 등)이나 비즈니스 영어 등 원하는 내용을 세부 사항에 입력하면 맞춤형 단락이 생성됩니다.',
                  '💡 머릿속으로 장면을 상상하며 학습하세요: 문장을 읽을 때 마치 영화의 한 장면처럼 상상하면 단어가 더 오래 기억에 남습니다.',
                  '💡 규칙적인 복습을 활용하세요: 망각 곡선에 맞춰 설정된 복습 알림을 통해 학습 효율을 최대화할 수 있습니다.',
                  '💡 테스트 결과를 활용하세요: 테스트 후 자동으로 생성되는 오답 노트를 통해 취약한 단어를 집중적으로 학습하세요.',
                ],
              ),
              const Divider(),
              _buildHelpSection(
                context,
                '단어장 관리',
                [
                  '1. 단어장 화면에서 우측 하단 (+) 버튼으로 새 단어장을 추가할 수 있습니다.',
                  '2. 단어장을 선택하면 내부 단어 목록과 생성된 단락을 볼 수 있습니다.',
                  '3. 단어장 내부에서 우측 상단 (+) 버튼으로 새 단어를 추가할 수 있습니다.',
                  '4. 테스트 후에는 자동으로 "오답 노트" 단어장이 생성되어 틀린 단어들을 쉽게 관리할 수 있습니다.',
                ],
              ),
              const Divider(),
              _buildHelpSection(
                context,
                'Chunk 생성',
                [
                  '1. 하단 메뉴의 중앙 (+) 버튼을 눌러 Chunk 생성 화면으로 이동합니다.',
                  '2. 단어장과 사용할 단어를 선택합니다. (필수)',
                  '3. 캐릭터, 시나리오, 세부 사항을 입력하면 더 맞춤화된 단락을 생성할 수 있습니다.',
                  '4. 모든 필수 항목을 입력한 후 하단의 "Chunk Up!" 버튼을 누르면 AI가 단락을 생성합니다.',
                  '5. 단어를 문맥 속에서 자연스럽게 배울 수 있는 흥미로운 이야기가 생성됩니다.',
                ],
              ),
              const Divider(),
              _buildHelpSection(
                context,
                '테스트',
                [
                  '1. 테스트 탭에서 테스트할 단어장과 단락, 테스트 유형을 선택합니다.',
                  '2. 단락 테스트는 문맥 속에서 빈칸 채우기, 단어 테스트는 단어와 뜻 매칭하기입니다.',
                  '3. 복합 테스트는 두 유형을 모두 포함합니다.',
                  '4. 테스트 완료 후 결과 화면에서 "틀린 단어를 오답 노트에 추가하기" 버튼을 눌러 오답 노트를 생성할 수 있습니다.',
                  '5. 오답 노트에 추가된 단어는 자동으로 "오답 노트" 단어장에 저장되어 후속 학습에 활용할 수 있습니다.',
                ],
              ),
              const Divider(),
              _buildHelpSection(
                context,
                '캐릭터 관리',
                [
                  '1. 설정 > 캐릭터 관리에서 커스텀 캐릭터를 추가하고 관리할 수 있습니다.',
                  '2. 캐릭터 추가 시 이름, 출처, 세부 설정을 입력합니다.',
                  '3. 추가한 캐릭터는 Chunk 생성 시 선택할 수 있습니다.',
                  '4. 좋아하는 캐릭터를 활용하면 학습에 더 몰입하게 되어 단어 기억력이 향상됩니다.',
                ],
              ),
              const Divider(),
              _buildHelpSection(
                context,
                '학습',
                [
                  '1. 홈 화면에서 "학습하기" 버튼을 눌러 학습할 단락을 선택할 수 있습니다.',
                  '2. 선택한 단락을 한 문장씩 TTS로 들으며 학습할 수 있습니다.',
                  '3. 단어 해설을 확인하며 효과적으로 학습할 수 있습니다.',
                  '4. 망각 곡선에 따라 복습 알림이 설정되어 효율적인 학습을 도와줍니다.',
                  '5. 학습 이력 화면에서 지난 학습 내역과 예정된 복습 일정을 확인할 수 있습니다.',
                ],
              ),
              _buildHelpSection(
                context,
                '오답 노트',
                [
                  '1. 테스트 완료 후 결과 화면에서 "틀린 단어를 오답 노트에 추가하기" 버튼을 통해 오답 노트를 생성합니다.',
                  '2. 자동으로 생성된 "오답 노트" 단어장에서 틀린 단어들을 확인할 수 있습니다.',
                  '3. 오답 노트에 있는 단어들로 새로운 Chunk를 생성하여 집중적으로 학습할 수 있습니다.',
                  '4. 테스트를 여러 번 진행해도 중복 없이 틀린 단어들이 계속 오답 노트에 추가됩니다.',
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '영어 단어 학습의 혁신, ChunkUp',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                ? Colors.orange.shade900.withOpacity(0.3)
                : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.orange.shade700
                  : Colors.orange.shade200
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '더 이상 깜지쓰기는 그만! 진짜 영어 학습의 시작',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.orange
                      : Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '기존 방식의 한계:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '- 단어의 뜻만 외우는 깜지쓰기 방식',
                  style: TextStyle(
                    height: 1.5,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  ),
                ),
                Text(
                  '- 지루하고 기억에 남지 않는 예문',
                  style: TextStyle(
                    height: 1.5,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  ),
                ),
                Text(
                  '- 단어는 알아도 실제 문장에서 당황하는 상황',
                  style: TextStyle(
                    height: 1.5,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ChunkUp의 혁신:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '- 좋아하는 캐릭터와 함께하는 몰입형 학습',
                  style: TextStyle(
                    height: 1.5,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  ),
                ),
                Text(
                  '- 필요한 단어만 골라서 효율적인 학습',
                  style: TextStyle(
                    height: 1.5,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  ),
                ),
                Text(
                  '- 머릿속에 그려지는 생생한 장면으로 기억력 향상',
                  style: TextStyle(
                    height: 1.5,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  ),
                ),
                Text(
                  '- 실제 문맥 속에서 단어의 자연스러운 사용법 학습',
                  style: TextStyle(
                    height: 1.5,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  ),
                ),
                Text(
                  '- 틀린 단어는 자동으로 오답 노트에 추가되어 효율적인 복습',
                  style: TextStyle(
                    height: 1.5,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context, String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              ),
            ),
          )),
        ],
      ),
    );
  }
}