import 'package:flutter/material.dart';

class TermsAndPrivacyScreen extends StatefulWidget {
  const TermsAndPrivacyScreen({Key? key}) : super(key: key);

  @override
  State<TermsAndPrivacyScreen> createState() => _TermsAndPrivacyScreenState();
}

class _TermsAndPrivacyScreenState extends State<TermsAndPrivacyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용약관'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '이용약관'),
            Tab(text: '개인정보처리방침'),
          ],
          labelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.white, // 선택된 탭은 항상 흰색으로
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : Colors.grey[400], // 선택되지 않은 탭은 회색으로
          indicatorColor: Colors.orange,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // 이용약관 탭
          SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이용약관',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text('최종 업데이트: 2024년 5월 16일'),
                SizedBox(height: 16),
                TermsOfServiceContent(),
              ],
            ),
          ),
          // 개인정보처리방침 탭
          SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '개인정보처리방침',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text('최종 업데이트: 2024년 5월 16일'),
                SizedBox(height: 16),
                PrivacyPolicyContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TermsOfServiceContent extends StatelessWidget {
  const TermsOfServiceContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          '제1조 (목적)',
          '이 약관은 청크업(Chunk Up) 애플리케이션(이하 "앱")을 제공하는 회사(이하 "회사")와 앱을 이용하는 사용자(이하 "사용자") 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.',
        ),
        _buildSection(
          '제2조 (용어의 정의)',
          '''이 약관에서 사용하는 용어의 정의는 다음과 같습니다:

1. "앱"이란 회사가 제공하는 '청크업(Chunk Up)' 애플리케이션을 의미합니다.
2. "사용자"란 앱을 설치하고 이용하는 모든 자연인 또는 법인을 의미합니다.
3. "콘텐츠"란 앱을 통해 제공되는 모든 정보, 데이터, 텍스트, 이미지, 소리, 동영상 등을 의미합니다.
4. "단어장"이란 사용자가 앱 내에서 생성하고 관리하는 어휘 학습 리스트를 의미합니다.
5. "청크"란 어휘를 맥락화하여 학습할 수 있도록 구성된 텍스트 단위를 의미합니다.''',
        ),
        _buildSection(
          '제3조 (약관의 게시 및 변경)',
          '''1. 회사는 이 약관의 내용을 사용자가 쉽게 알 수 있도록 앱 내 또는 회사 웹사이트에 게시합니다.
          
2. 회사는 필요한 경우 「약관의 규제에 관한 법률」, 「정보통신망 이용촉진 및 정보보호 등에 관한 법률」, 「개인정보 보호법」 등 관련 법령을 위반하지 않는 범위에서 이 약관을 변경할 수 있습니다.

3. 회사가 약관을 변경하는 경우에는 적용일자 및 변경사유를 명시하여 변경 약관 적용일로부터 최소 7일 전부터 앱 내 공지사항을 통해 고지합니다. 단, 사용자에게 불리한 약관 변경의 경우에는 최소 30일 전부터 고지합니다.

4. 변경된 약관은 공지된 적용일자부터 효력이 발생하며, 사용자가 약관 변경 공지 후에도 앱을 계속 이용하는 경우 변경된 약관에 동의한 것으로 간주합니다.''',
        ),
        _buildSection(
          '제4조 (서비스의 내용)',
          '''회사가 제공하는 서비스의 내용은 다음과 같습니다:

1. 단어장 생성 및 관리 서비스
2. 어휘 학습 및 복습 기능 제공
3. 맥락화된 어휘 학습을 위한 청크 생성 및 관리
4. 학습 진행 상황 분석 및 통계 제공
5. 그 외 어학 학습과 관련하여 회사가 제공하는 부가 서비스''',
        ),
        _buildSection(
          '제5조 (서비스 이용)',
          '''1. 앱 서비스 이용은 회사의 업무상 또는 기술상 특별한 지장이 없는 한 연중무휴, 1일 24시간 제공됩니다.

2. 회사는 앱 서비스를 일정 범위로 분할하여 각 범위별로 이용 가능 시간을 별도로 정할 수 있습니다. 이 경우 그 내용을 사용자에게 공지합니다.

3. 회사는 다음 각 호에 해당하는 경우 서비스의 전부 또는 일부를 제한하거나 중지할 수 있습니다:
   a. 서비스용 설비의 점검, 교체, 고장, 통신 두절 등의 사유가 발생한 경우
   b. 천재지변, 국가비상사태, 정전, 서비스 설비의 장애 등 불가항력적 사유가 발생한 경우
   c. 서비스 이용의 폭주 등으로 인하여 서비스 이용에 지장이 있는 경우
   d. 기타 회사의 업무상 또는 기술상 서비스 제공이 곤란한 경우

4. 제3항에 의한 서비스 중단의 경우 회사는 제7조에 정한 방법으로 사용자에게 통지합니다. 다만, 회사가 통제할 수 없는 사유로 인한 서비스 중단으로 인하여 사전 통지가 불가능한 경우에는 예외로 합니다.''',
        ),
        _buildSection(
          '제6조 (회원가입 및 계정)',
          '''1. 앱은 기본적으로 계정 생성 없이 사용할 수 있습니다. 다만, 회사가 제공하는 특정 서비스를 이용하기 위해서는 회원가입이 필요할 수 있습니다.

2. 회원가입이 필요한 경우, 사용자는 회사가 요청하는 정보를 정확하게 제공해야 합니다.

3. 사용자는 자신의 계정 정보를 안전하게 관리할 책임이 있으며, 계정 정보 유출로 인한 피해는 사용자 본인이 책임을 부담합니다. 단, 회사의 고의 또는 과실로 인한 경우는 예외로 합니다.

4. 사용자는 계정 정보가 도용되거나 제3자가 무단으로 사용하고 있음을 인지한 경우 즉시 회사에 통지하고 회사의 안내에 따라야 합니다.''',
        ),
        _buildSection(
          '제7조 (사용자에 대한 통지)',
          '''1. 회사가 사용자에 대한 통지를 하는 경우, 앱 내 공지사항 게시, 푸시 알림, 이메일 등의 방법으로 할 수 있습니다.

2. 회사는 불특정 다수 사용자에 대한 통지의 경우, 앱 내 공지사항에 게시함으로써 개별 통지에 갈음할 수 있습니다.

3. 사용자는 회사의 통지사항을 수시로 확인하여야 하며, 미확인으로 인한 불이익에 대해서는 회사의 고의 또는 중과실이 없는 한 책임을 지지 않습니다.''',
        ),
        _buildSection(
          '제8조 (지식재산권 및 콘텐츠 이용)',
          '''1. 회사가 제공하는 앱 및 콘텐츠에 대한 저작권, 특허권, 상표권 등 모든 지식재산권은 회사 또는 해당 권리자에게 귀속됩니다.

2. 사용자는 회사가 제공하는 서비스를 이용하여 얻은 정보를 회사의 사전 승낙 없이 복제, 전송, 출판, 배포, 방송 등 기타 방법에 의하여 영리 목적으로 이용하거나 제3자에게 이용하게 할 수 없습니다.

3. 사용자가 앱 내에서 생성한 단어장, 청크 등의 콘텐츠에 대한 저작권은 원칙적으로 사용자 본인에게 있습니다.

4. 사용자는 자신이 생성한 콘텐츠를 앱 내에서 관리할 수 있으며, 언제든지 삭제할 수 있습니다.

5. 사용자는 자신이 앱에 게시한 콘텐츠에 대해 회사가 서비스 운영, 개선 및 홍보 등의 목적으로 사용하는 것을 허락합니다. 단, 회사는 사용자의 콘텐츠를 외부에 공개할 경우 사용자의 별도 동의를 받아야 합니다.''',
        ),
        _buildSection(
          '제9조 (권리 및 의무)',
          '''1. 회사의 권리 및 의무
   a. 회사는 안정적인 서비스 제공을 위해 최선을 다합니다.
   b. 회사는 서비스 이용과 관련하여 사용자로부터 제기된 의견이나 불만이 정당하다고 인정할 경우 이를 처리하여야 합니다.
   c. 회사는 개인정보 보호 법령이 정하는 바에 따라 사용자의 개인정보를 보호하기 위한 조치를 취합니다.
   d. 회사는 서비스의 제공에 필요한 경우 정기점검을 실시할 수 있으며, 이는 사전에 공지합니다.

2. 사용자의 권리 및 의무
   a. 사용자는 본 약관 및 관련 법령을 준수하여야 합니다.
   b. 사용자는 회사의 동의 없이 서비스를 이용하여 영업활동을 할 수 없습니다.
   c. 사용자는 다음 각 호에 해당하는 행위를 해서는 안 됩니다:
      - 타인의 저작권을 침해하는 행위
      - 앱의 운영을 방해하는 행위
      - 타인의 명예를 훼손하거나 불이익을 주는 행위
      - 앱을 이용하여 법령에 위반되는 행위를 하는 경우
      - 기타 본 약관에서 금지하는 행위
   d. 사용자는 자신의 데이터를 백업하는 것에 대한 책임이 있습니다.''',
        ),
        _buildSection(
          '제10조 (연락처)',
          '''회사 연락처 및 문의처는 다음과 같습니다:

이메일: chunk_up@naver.com''',
        ),
        _buildSection(
          '제11조 (기타)',
          '''1. 본 약관에 명시되지 않은 사항은 관련 법령 및 회사가 정한 서비스의 세부이용지침 등의 규정에 따릅니다.

2. 회사는 필요한 경우 서비스 내의 개별 서비스에 대한 세부이용지침을 정할 수 있으며, 해당 내용은 앱 내에 게시합니다.

3. 본 약관의 시행일은 2024년 5월 16일입니다.''',
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class PrivacyPolicyContent extends StatelessWidget {
  const PrivacyPolicyContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          '1. 개인정보 수집 항목 및 이용 목적',
          '''Chunk Up('https://github.com/YeoJun1324/chunk_up')은 다음의 목적을 위해 필요한 최소한의 개인정보를 수집합니다.

- 앱 사용 기록 및 학습 데이터: 사용자 맞춤형 학습 경험 제공 및 서비스 개선
- 단말기 정보 (OS 버전, 모델명): 서비스 최적화 및 버그 수정''',
        ),
        _buildSection(
          '2. 개인정보의 보유 및 이용 기간',
          '''사용자의 개인정보는 서비스 이용 종료 시 또는 사용자가 개인정보 삭제를 요청할 경우 지체 없이 파기됩니다. 단, 다음의 정보에 대해서는 아래의 이유로 명시한 기간 동안 보존합니다.

- 관련 법령에 의한 보존 필요성이 있는 경우: 관계 법령에서 정한 기간''',
        ),
        _buildSection(
          '3. 개인정보의 파기 절차 및 방법',
          '''사용자의 개인정보는 목적이 달성된 후 별도의 데이터베이스로 옮겨져(종이의 경우 별도의 서류함) 내부 방침 및 기타 관련 법령에 따라 일정 기간 저장된 후 파기됩니다. 이때 데이터베이스로 옮겨진 개인정보는 법률에 의한 경우를 제외하고 다른 목적으로 이용되지 않습니다.''',
        ),
        _buildSection(
          '4. 사용자 권리와 행사 방법',
          '''사용자는 개인정보 열람, 정정, 삭제, 처리정지 요구 등의 권리를 행사할 수 있으며, 이를 위해 앱 내 설정 메뉴를 이용하거나 연락처로 요청할 수 있습니다.''',
        ),
        _buildSection(
          '5. 개인정보의 안전성 확보 조치',
          '''Chunk Up은 사용자의 개인정보를 안전하게 처리하기 위해 다음과 같은 기술적, 관리적 조치를 취하고 있습니다:
- 중요 데이터의 암호화
- 접근 제어 시스템 구축
- 개인정보 위험 요소 모니터링''',
        ),
        _buildSection(
          '6. 제3자 정보 제공',
          '''Chunk Up은 사용자의 개인정보를 제3자에게 제공하지 않습니다. 단, 다음의 경우는 예외로 합니다:
- 사용자의 명시적 동의가 있는 경우
- 법령에 의한 경우''',
        ),
        _buildSection(
          '7. 개인정보 자동 수집 장치의 설치/운영 및 거부에 관한 사항',
          '''Chunk Up은 사용자 경험 향상을 위해 기기 내 로컬 저장소(Shared Preferences, 캐시 등)를 사용합니다. 사용자는 앱 설정을 통해 이를 제한할 수 있습니다.''',
        ),
        _buildSection(
          '8. 개인정보 보호책임자 및 데이터 삭제 요청',
          '''개인정보 보호에 관한 문의사항은 아래 연락처로 문의해 주시기 바랍니다.
- 이메일: chunk_up@naver.com

사용자는 위 이메일로 계정 및 관련 데이터 삭제를 요청할 수 있습니다. 요청 시 다음 정보를 포함해 주세요:
1. 제목에 "데이터 삭제 요청" 포함
2. 사용 중인 기기 모델명
3. 앱 설치일(대략적인 날짜)

요청을 받은 후 영업일 기준 7일 이내에 처리하겠습니다.''',
        ),
        _buildSection(
          '9. 개인정보처리방침 변경',
          '''이 개인정보처리방침은 법령, 정책 또는 보안 기술의 변경에 따라 변경될 수 있습니다. 변경 사항은 앱 또는 웹사이트를 통해 공지됩니다.

시행일자: 2024년 5월 16일''',
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}