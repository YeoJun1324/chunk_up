// lib/presentation/screens/series_editor_dialog.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/domain/models/series.dart';
import 'package:uuid/uuid.dart';

class SeriesEditorDialog extends StatefulWidget {
  final Series? series;
  final Function(Series) onSave;

  const SeriesEditorDialog({
    Key? key,
    this.series,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SeriesEditorDialog> createState() => _SeriesEditorDialogState();
}

class _SeriesEditorDialogState extends State<SeriesEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _genreController;
  late TextEditingController _worldSettingController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.series?.name ?? '');
    _descriptionController = TextEditingController(text: widget.series?.description ?? '');
    _genreController = TextEditingController(text: widget.series?.settings.genre ?? '');
    _worldSettingController = TextEditingController(text: widget.series?.settings.worldSetting ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _genreController.dispose();
    _worldSettingController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final series = Series(
        id: widget.series?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        characterIds: widget.series?.characterIds ?? [],
        relationshipIds: widget.series?.relationshipIds ?? [],
        settings: SeriesSettings(
          genre: _genreController.text.trim(),
          worldSetting: _worldSettingController.text.trim(),
          customSettings: widget.series?.settings.customSettings ?? {},
        ),
        createdAt: widget.series?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      widget.onSave(series);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.series == null ? '시리즈 추가' : '시리즈 편집'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '시리즈 이름',
                  hintText: '예: 역전재판',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '시리즈 이름을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '시리즈 설명',
                  hintText: '시리즈에 대한 간단한 설명',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '시리즈 설명을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _genreController,
                decoration: const InputDecoration(
                  labelText: '장르 (선택사항)',
                  hintText: '예: 법정 드라마, SF 스릴러',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _worldSettingController,
                decoration: const InputDecoration(
                  labelText: '세계관 (선택사항)',
                  hintText: '예: 현대 일본, 미래 도시',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('저장'),
        ),
      ],
    );
  }
}