// lib/presentation/widgets/safe_state_mixin.dart
import 'package:flutter/material.dart';

/// Safe setState mixin that prevents setState calls on disposed widgets
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  /// Safe setState that only calls setState if the widget is still mounted
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  /// Safe delayed setState for asynchronous operations
  void safeSetStateDelayed(VoidCallback fn, {Duration delay = Duration.zero}) {
    Future.delayed(delay, () {
      if (mounted) {
        setState(fn);
      }
    });
  }

  /// Safe setState with try-catch for additional error protection
  void safeTrySetState(VoidCallback fn) {
    try {
      if (mounted) {
        setState(fn);
      }
    } catch (e) {
      // Log error if needed, but don't crash the app
      debugPrint('SafeStateMixin: setState error caught: $e');
    }
  }
}