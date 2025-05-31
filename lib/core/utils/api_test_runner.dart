// lib/core/utils/api_test_runner.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/core/utils/api_key_tester.dart';
import 'package:chunk_up/core/utils/api_test.dart';

/// API 테스트 실행기 위젯
class ApiTestRunner extends StatefulWidget {
  const ApiTestRunner({Key? key}) : super(key: key);

  @override
  State<ApiTestRunner> createState() => _ApiTestRunnerState();
}

class _ApiTestRunnerState extends State<ApiTestRunner> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = false;
  String _testResult = '';
  bool _success = false;

  @override
  void initState() {
    super.initState();
    // API 키는 환경 변수나 보안 저장소에서 가져와야 합니다
    _apiKeyController.text = "";
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testApiKey() async {
    setState(() {
      _isLoading = true;
      _testResult = '';
      _success = false;
    });

    try {
      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty) {
        setState(() {
          _testResult = '❌ API 키를 입력하세요.';
          _isLoading = false;
        });
        return;
      }

      final result = await ApiKeyTester.testApiKey(apiKey);
      
      if (result['success'] == true) {
        setState(() {
          _testResult = '✅ API 연결 성공!\n\n📋 응답:\n${result['response']['content'][0]['text']}';
          _success = true;
        });
      } else {
        final errorMessage = result['error'] ?? '알 수 없는 오류';
        final statusCode = result['status_code'] != null ? '상태 코드: ${result['status_code']}' : '';
        
        setState(() {
          _testResult = '❌ API 연결 실패\n\n${statusCode}\n$errorMessage';
          _success = false;
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ 테스트 중 오류 발생: $e';
        _success = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAllApis() async {
    setState(() {
      _isLoading = true;
      _testResult = '🔍 모든 API 소스 테스트 중...';
      _success = false;
    });

    try {
      // ApiTest 클래스의 testAllApiKeys 메서드 호출
      await ApiTest.testAllApiKeys();
      
      setState(() {
        _testResult = '✅ API 테스트 완료! 자세한 결과는 콘솔 로그를 확인하세요.';
        _success = true;
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ API 테스트 중 오류 발생: $e';
        _success = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 테스트'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API 키',
                hintText: 'Claude API 키를 입력하세요',
                border: OutlineInputBorder(),
              ),
              obscureText: false,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testApiKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('API 키 테스트'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAllApis,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('모든 API 소스 테스트'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _success ? Colors.green : Colors.grey,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResult.isEmpty ? '테스트 결과가 여기에 표시됩니다.' : _testResult,
                    style: TextStyle(
                      color: _success ? Colors.green : null,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}