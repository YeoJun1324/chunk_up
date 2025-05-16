import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chunk_up/presentation/screens/riverpod_examples_screen.dart';

/// Riverpod을 사용한 애플리케이션 예제
void main() {
  runApp(
    // ProviderScope: Riverpod 사용을 위한 필수 위젯
    const ProviderScope(
      child: RiverpodExampleApp(),
    )
  );
}

/// Riverpod Provider를 앱에 적용하는 유틸리티 위젯
///
/// 기존 Provider 기반 앱에 Riverpod을 점진적으로 도입할 때 사용합니다.
/// 이 위젯은 기존 앱 위에 ProviderScope를 래핑하여 Riverpod을 사용 가능하게 합니다.
class RiverpodContainer extends StatelessWidget {
  final Widget child;

  const RiverpodContainer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(child: child);
  }
}

/// Riverpod 예제 앱
class RiverpodExampleApp extends StatelessWidget {
  const RiverpodExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riverpod Example',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const RiverpodExamplesScreen(),
    );
  }
}