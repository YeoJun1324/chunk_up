import 'package:flutter/foundation.dart';

/// Base class for services that need cleanup
abstract class DisposableService {
  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  @mustCallSuper
  Future<void> dispose() async {
    if (_isDisposed) return;
    
    await onDispose();
    _isDisposed = true;
  }

  /// Override this method to implement cleanup logic
  Future<void> onDispose();

  /// Check if service is disposed before performing operations
  void checkDisposed() {
    if (_isDisposed) {
      throw StateError('Service has been disposed');
    }
  }
}

/// Mixin for services that use timers or streams
mixin AutoDisposeMixin on DisposableService {
  final List<VoidCallback> _disposables = [];

  void addDisposable(VoidCallback callback) {
    _disposables.add(callback);
  }

  @override
  Future<void> onDispose() async {
    for (final disposable in _disposables) {
      disposable();
    }
    _disposables.clear();
  }
}