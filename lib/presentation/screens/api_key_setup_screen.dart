// lib/screens/api_key_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/infrastructure/error/error_service.dart';
import 'package:chunk_up/di/service_locator.dart';
import 'package:chunk_up/domain/services/api_service_interface.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeySetupScreen extends StatefulWidget {
  final bool isInitialSetup;

  const ApiKeySetupScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  State<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends State<ApiKeySetupScreen> {
  final ErrorService _errorService = ErrorService();
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSaveApiKey() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _errorService.handleErrorWithContext(
        context: context,
        operation: 'validateAndSaveApiKey',
        action: () async {
          final apiKey = _apiKeyController.text.trim();
          final apiService = GetIt.instance<ApiServiceInterface>();
          
          // API 키 설정 및 테스트
          await apiService.setApiKey(apiKey);
          await apiService.testApiConnection();
          
          // 보안 저장소에 저장
          const storage = FlutterSecureStorage();
          await storage.write(key: 'anthropic_api_key', value: apiKey);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('API 키가 저장되었습니다.'),
                backgroundColor: Colors.green,
              ),
            );

            if (widget.isInitialSetup) {
              Navigator.pushReplacementNamed(context, '/');
            } else {
              Navigator.pop(context);
            }
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claude API 키 설정'),
        automaticallyImplyLeading: !widget.isInitialSetup,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Claude API 키 입력',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ChunkUp은 Claude AI를 사용하여 단락을 생성합니다. '
                    'Anthropic에서 API 키를 발급받아 입력해주세요.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _apiKeyController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'API 키',
                  hintText: 'sk-ant-api...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'API 키를 입력해주세요.';
                  }
                  if (!value.startsWith('sk-ant-api')) {
                    return '올바른 Claude API 키 형식이 아닙니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'API 키는 기기에 안전하게 저장되며, 외부로 전송되지 않습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  // Anthropic 콘솔 페이지 열기
                  // URL launcher 구현 필요
                },
                child: const Text(
                  'API 키 발급받기 →',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _validateAndSaveApiKey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  '저장하기',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              if (!widget.isInitialSetup)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}