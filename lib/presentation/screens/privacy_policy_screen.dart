import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보 처리방침'),
        elevation: 0,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '개인정보 처리방침',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('최종 업데이트: 2024년 5월 15일'),
              SizedBox(height: 16),
              PrivacyPolicyContent(),
            ],
          ),
        ),
      ),
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
          '1. 개요',
          '본 개인정보 처리방침은 청크업(Chunk Up) 애플리케이션(이하 "앱")을 사용하는 과정에서 수집되는 개인정보의 처리에 관한 사항을 규정합니다. 본 앱은 사용자의 개인정보 보호를 중요하게 생각하며, 개인정보 보호법 등 관련 법령을 준수하고 있습니다.',
        ),
        _buildSection(
          '2. 수집하는 개인정보 항목 및 수집 방법',
          '''앱은 다음과 같은 개인정보를 수집할 수 있습니다:

1) 필수적으로 수집하는 정보
   - 기기 정보: 기기 모델, 운영 체제 버전, 앱 버전 등 기술적 정보
   - 앱 사용 기록: 학습 진행 상황, 단어장 및 학습 데이터

2) 선택적으로 수집하는 정보
   - 알림 설정: 학습 알림을 위한 정보
   - 음성 인식: TTS(Text-to-Speech) 기능 사용 시 관련 정보

3) 자동으로 생성되는 정보
   - 앱 사용 로그, 오류 기록 등 기술적 데이터

수집 방법: 앱 설치 및 이용 과정에서 자동으로 생성되거나, 사용자가 앱 내 기능을 사용할 때 직접 입력하는 방식으로 수집됩니다.''',
        ),
        _buildSection(
          '3. 개인정보의 이용 목적',
          '''수집한 개인정보는 다음 목적으로만 이용됩니다:

1) 앱의 기본 기능 제공
   - 단어장 및 학습 데이터 저장 및 관리
   - 학습 진행 상황 분석 및 제공

2) 앱 품질 향상
   - 오류 분석 및 개선
   - 사용자 경험 개선을 위한 데이터 분석

3) 알림 서비스 제공
   - 학습 알림 및 기타 서비스 관련 알림
   
4) 통계 작성 및 학술 연구
   - 개인을 식별할 수 없는 형태로 가공된 통계 데이터 활용''',
        ),
        _buildSection(
          '4. 개인정보의 보유 및 이용 기간',
          '''앱에서 수집한 개인정보는 다음과 같은 기간 동안 보유 및 이용됩니다:

1) 앱 사용 기간
   - 앱을 설치하고 사용하는 동안 개인정보를 보유 및 이용합니다.

2) 앱 삭제 시
   - 앱을 삭제하면 기기에 저장된 모든 데이터는 즉시 삭제됩니다.
   - 백업 데이터는 사용자가 직접 설정한 경우에만 존재하며, 사용자 계정에서 관리됩니다.

3) 법적 의무 준수
   - 관련 법령에 따른 보존 의무가 있는 경우, 해당 기간 동안 필요한 정보를 보관할 수 있습니다.''',
        ),
        _buildSection(
          '5. 개인정보의 제3자 제공',
          '앱은 원칙적으로 사용자의 개인정보를 외부에 제공하지 않습니다. 다만, 아래와 같은 경우 예외적으로 제공될 수 있습니다:\n\n'
          '1) 사용자가 명시적으로 동의한 경우\n'
          '2) 법령에 의거하여 제공이 요구되는 경우\n'
          '3) 통계 작성, 학술 연구 등의 목적으로 특정 개인을 식별할 수 없는 형태로 가공하여 제공하는 경우',
        ),
        _buildSection(
          '6. 개인정보의 파기',
          '''개인정보의 수집 및 이용 목적이 달성되면 다음과 같이 파기합니다:

1) 파기 절차
   - 앱 내에서 수집된 개인정보는 목적이 달성된 후 별도의 DB로 옮겨져 내부 규정 및 관련 법령에 따라 일정 기간 저장된 후 파기됩니다.
   - 앱 삭제 시 기기에 저장된 데이터는 즉시 파기됩니다.

2) 파기 방법
   - 전자적 파일 형태로 저장된 개인정보는 복구 불가능한 방법으로 영구 삭제됩니다.''',
        ),
        _buildSection(
          '7. 사용자의 권리와 행사 방법',
          '''사용자는 언제든지 자신의 개인정보에 대해 다음과 같은 권리를 행사할 수 있습니다:

1) 개인정보 열람 요구
2) 개인정보 정정 및 삭제 요구
3) 개인정보 처리정지 요구

위 권리 행사는 앱 내 설정 메뉴 또는 개발자 이메일(support@chunkup.com)로 연락하여 요청할 수 있습니다. 요청이 있는 경우 지체 없이 필요한 조치를 취하겠습니다.''',
        ),
        _buildSection(
          '8. 개인정보 자동 수집 장치의 설치/운영 및 거부에 관한 사항',
          '''앱은 사용자에게 맞춤형 서비스를 제공하기 위해 쿠키 또는 유사한 기술을 사용할 수 있습니다:

1) 자동 수집 장치의 설치/운영
   - 앱 성능 개선 및 사용자 경험 향상을 위한 분석 도구
   - 학습 진행 상황 추적을 위한 로컬 저장소

2) 거부 방법
   - 기기 설정에서 앱의 저장소 접근 권한을 제한할 수 있습니다
   - 앱 내 설정에서 데이터 수집 옵션을 조정할 수 있습니다''',
        ),
        _buildSection(
          '9. 기타 개인정보 처리에 관한 사항',
          '''1) 개인정보 보호 책임자
   - 성명: [책임자명]
   - 직위: 개인정보 보호 책임자
   - 연락처: privacy@chunkup.com

2) 개인정보 안전성 확보 조치
   - 앱은 개인정보의 안전성 확보를 위해 기술적, 관리적 조치를 취하고 있습니다.
   - 데이터 암호화, 접근 제어, 보안 업데이트 등을 통해 개인정보를 보호합니다.

3) 변경 사항 고지
   - 본 개인정보 처리방침이 변경되는 경우, 앱 내 공지사항을 통해 변경 사항을 안내드립니다.''',
        ),
        _buildSection(
          '10. 개정 이력',
          '- 2024년 5월 15일: 최초 제정',
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