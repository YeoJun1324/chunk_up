import 'package:flutter/material.dart';
import 'immutable_form_state.dart';

/// 불변성 패턴을 적용한 폼 위젯
///
/// StatefulWidget에서 불변성 패턴을 사용하는 방법을 보여줍니다.
/// 상태 변경 시 항상 새 ImmutableFormState 객체를 생성하여 불변성을 유지합니다.
class ImmutableFormWidget extends StatefulWidget {
  // 폼 제출 시 콜백
  final Function(String name, String email, String password) onSubmit;

  const ImmutableFormWidget({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<ImmutableFormWidget> createState() => _ImmutableFormWidgetState();
}

class _ImmutableFormWidgetState extends State<ImmutableFormWidget> {
  // 불변 상태 객체
  ImmutableFormState _state = ImmutableFormState.initial();

  // 불변 상태를 업데이트하기 위한 메서드
  void _updateState(ImmutableFormState newState) {
    setState(() {
      _state = newState;
    });
  }

  // 이름 변경 핸들러
  void _onNameChanged(String value) {
    final newState = _state.copyWith(name: value).validateName();
    _updateState(newState);
  }

  // 이메일 변경 핸들러
  void _onEmailChanged(String value) {
    final newState = _state.copyWith(email: value).validateEmail();
    _updateState(newState);
  }

  // 비밀번호 변경 핸들러
  void _onPasswordChanged(String value) {
    final newState = _state.copyWith(password: value).validatePassword();
    _updateState(newState);
  }

  // 폼 제출 핸들러
  Future<void> _onSubmit() async {
    // 모든 필드 유효성 검사
    final validatedState = _state.validateAll();
    
    if (!validatedState.isValid) {
      _updateState(validatedState.withError('모든 필드를 올바르게 입력해주세요.'));
      return;
    }

    // 제출 중 상태로 변경
    _updateState(validatedState.submitting());

    try {
      // 부모 위젯의 onSubmit 콜백 호출 (실제 제출 로직)
      await Future.delayed(const Duration(seconds: 1)); // 네트워크 요청 시뮬레이션
      widget.onSubmit(_state.name, _state.email, _state.password);
      
      // 제출 완료 상태로 변경
      _updateState(_state.submitted());
    } catch (e) {
      // 오류 발생 시 오류 메시지와 함께 상태 업데이트
      _updateState(_state.withError('제출 중 오류가 발생했습니다: $e'));
    }
  }

  // 폼 초기화 핸들러
  void _onReset() {
    _updateState(_state.reset());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '불변성 패턴 예제 폼',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '이 폼은 모든 상태 변경에서 불변성 패턴을 사용합니다.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            // 이름 입력 필드
            TextField(
              decoration: InputDecoration(
                labelText: '이름',
                errorText: _state.isNameValid || _state.name.isEmpty ? null : '유효한 이름을 입력해주세요.',
                border: const OutlineInputBorder(),
              ),
              onChanged: _onNameChanged,
              enabled: !_state.isSubmitting && !_state.isSubmitted,
            ),
            const SizedBox(height: 16),
            
            // 이메일 입력 필드
            TextField(
              decoration: InputDecoration(
                labelText: '이메일',
                errorText: _state.isEmailValid || _state.email.isEmpty ? null : '유효한 이메일을 입력해주세요.',
                border: const OutlineInputBorder(),
              ),
              onChanged: _onEmailChanged,
              enabled: !_state.isSubmitting && !_state.isSubmitted,
            ),
            const SizedBox(height: 16),
            
            // 비밀번호 입력 필드
            TextField(
              decoration: InputDecoration(
                labelText: '비밀번호',
                errorText: _state.isPasswordValid || _state.password.isEmpty ? null : '비밀번호는 6자 이상이어야 합니다.',
                border: const OutlineInputBorder(),
              ),
              onChanged: _onPasswordChanged,
              obscureText: true,
              enabled: !_state.isSubmitting && !_state.isSubmitted,
            ),
            const SizedBox(height: 16),
            
            // 에러 메시지
            if (_state.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade50,
                width: double.infinity,
                child: Text(
                  _state.errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 폼 상태 표시
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('이름 유효함: ${_state.isNameValid}'),
                  Text('이메일 유효함: ${_state.isEmailValid}'),
                  Text('비밀번호 유효함: ${_state.isPasswordValid}'),
                  Text('제출 가능: ${_state.isSubmittable}'),
                  Text('제출 중: ${_state.isSubmitting}'),
                  Text('제출 완료: ${_state.isSubmitted}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 버튼 행
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 초기화 버튼
                OutlinedButton(
                  onPressed: _state.isSubmitting ? null : _onReset,
                  child: const Text('초기화'),
                ),
                const SizedBox(width: 16),
                
                // 제출 버튼
                ElevatedButton(
                  onPressed: _state.isSubmittable ? _onSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: _state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('제출'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}