// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chunk_up/main.dart';
import 'package:chunk_up/presentation/providers/theme_notifier.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/presentation/providers/folder_notifier.dart';
import 'package:chunk_up/main_riverpod.dart';
import 'package:chunk_up/di/dependency_injection.dart';
import 'test_utils/mock_service_locator.dart';

/// Test wrapper to provide necessary dependencies
Widget createTestableApp() {
  // Use mocked services via getIt service locator
  return RiverpodContainer(
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => getIt<WordListNotifier>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<FolderNotifier>(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeNotifier(),
        ),
      ],
      child: const ChunkVocabApp(hasApiKey: true),
    ),
  );
}

void main() {
  setUp(() async {
    // 테스트 전에 목 서비스 로케이터 설정
    await setupTestServiceLocator();
  });

  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(createTestableApp());

    // Verify that the app initializes without errors
    expect(find.byType(ChunkVocabApp), findsOneWidget);

    // Check for basic app elements
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}