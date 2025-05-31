// lib/presentation/screens/series_editor_dialog.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/domain/models/series.dart';
import 'package:uuid/uuid.dart';
import '../widgets/labeled_border_container.dart';

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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.series == null ? Icons.add_circle : Icons.edit,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.series == null ? '시리즈 추가' : '시리즈 편집',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LabeledTextField(
                        label: '시리즈 이름',
                        hint: '예: 셜록 홈즈',
                        isRequired: true,
                        controller: _nameController,
                        focusedBorderColor: Theme.of(context).primaryColor,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '시리즈 이름을 입력하세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      LabeledTextField(
                        label: '시리즈 설명',
                        hint: '시리즈에 대한 간단한 설명',
                        isRequired: true,
                        controller: _descriptionController,
                        maxLines: 3,
                        focusedBorderColor: Theme.of(context).primaryColor,
                        textAlign: TextAlign.justify,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '시리즈 설명을 입력하세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      LabeledTextField(
                        label: '장르',
                        hint: '예: 추리, SF, 판타지',
                        controller: _genreController,
                        focusedBorderColor: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 4),
                      LabeledTextField(
                        label: '세계관',
                        hint: '예: 19세기 런던, 현대 도시',
                        controller: _worldSettingController,
                        focusedBorderColor: Theme.of(context).primaryColor,
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('저장'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}