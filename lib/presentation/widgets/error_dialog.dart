// lib/presentation/widgets/error_dialog.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/infrastructure/error/error_service.dart';  // ErrorType import

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final ErrorType type;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getIconForErrorType(),
            color: _getColorForErrorType(),
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (type == ErrorType.network)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                '인터넷 연결을 확인하고 다시 시도해주세요.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
        ],
      ),
      actions: [
        if (type == ErrorType.network)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 재시도 로직 구현
            },
            child: const Text('재시도'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    );
  }

  IconData _getIconForErrorType() {
    switch (type) {
      case ErrorType.api:
        return Icons.cloud_off;
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.timeout:
        return Icons.hourglass_empty;
      case ErrorType.critical:
        return Icons.error;
      default:
        return Icons.warning;
    }
  }

  Color _getColorForErrorType() {
    switch (type) {
      case ErrorType.critical:
        return Colors.red;
      case ErrorType.api:
      case ErrorType.network:
      case ErrorType.timeout:
        return Colors.orange;
      default:
        return Colors.amber;
    }
  }
}