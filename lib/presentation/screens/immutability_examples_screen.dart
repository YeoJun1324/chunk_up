import 'package:flutter/material.dart';
import 'package:chunk_up/presentation/widgets/immutable_pattern/immutable_form_widget.dart';
import 'package:chunk_up/presentation/widgets/immutable_pattern/immutable_list_widget.dart';
import 'package:chunk_up/presentation/widgets/immutable_pattern/immutable_component_communication.dart';

/// 불변성 패턴 예제 화면
///
/// 다양한 불변성 패턴 구현 예제를 보여주는 화면입니다.
class ImmutabilityExamplesScreen extends StatelessWidget {
  const ImmutabilityExamplesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('불변성 패턴 예제'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 소개
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '불변성 패턴 구현 예제',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '이 화면은 Flutter에서 불변성 패턴을 구현하는 다양한 예제를 보여줍니다. '
                      '불변성 패턴은 상태 관리를 예측 가능하고 안정적으로 만드는 중요한 디자인 패턴입니다. '
                      '아래의 예제들을 통해 다양한 상황에서 불변성 패턴을 어떻게 구현할 수 있는지 확인하세요.',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 불변성 폼 위젯 섹션
              _buildSectionTitle('1. 불변성 폼 패턴'),
              const SizedBox(height: 8),
              const Text(
                '폼 상태 관리에 불변성 패턴을 적용한 예제입니다. 입력 필드 값 변경, 유효성 검사, 제출 과정에서 '
                '항상 새로운 상태 객체를 생성하여 불변성을 유지합니다.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 480, // 고정 높이 설정
                child: ImmutableFormWidget(
                  onSubmit: (name, email, password) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('폼 제출 완료: $name, $email'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // 불변성 리스트 위젯 섹션
              _buildSectionTitle('2. 불변성 리스트 패턴'),
              const SizedBox(height: 8),
              const Text(
                '리스트 상태 관리에 불변성 패턴을 적용한 예제입니다. 아이템 추가, 삭제, 상태 변경 시 '
                '항상 새로운 상태 객체를 생성하여 불변성을 유지합니다.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400, // 고정 높이 설정
                child: ImmutableListWidget(),
              ),
              const SizedBox(height: 32),

              // 컴포넌트 통신 예제 섹션
              _buildSectionTitle('3. 컴포넌트 간 통신 패턴'),
              const SizedBox(height: 8),
              const Text(
                '부모 위젯과 자식 컴포넌트 간의 통신에 불변성 패턴을 적용한 예제입니다. '
                '데이터 모델의 불변성을 유지하면서 컴포넌트 간 상태를 공유하고 업데이트합니다.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400, // 고정 높이 설정
                child: ImmutableParentWidget(),
              ),
              const SizedBox(height: 32),

              // 결론
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '불변성 패턴의 이점',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• 예측 가능한 상태 관리: 상태 변화를 추적하기 쉽습니다.\n'
                      '• 버그 감소: "변경하면 안 되는" 객체를 실수로 변경하는 문제를 방지합니다.\n'
                      '• 참조 동등성: 객체가 변경되었는지 쉽게 확인할 수 있습니다.\n'
                      '• 동시성 안전: 여러 스레드에서 안전하게 객체를 공유할 수 있습니다.\n'
                      '• 쉬운 실행 취소/다시 실행: 이전 상태를 저장하고 복원하기 쉽습니다.',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}