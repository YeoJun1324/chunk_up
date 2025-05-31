// lib/presentation/screens/character_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/domain/models/character.dart';
import 'package:chunk_up/presentation/widgets/labeled_border_container.dart';
import 'package:uuid/uuid.dart';

class CharacterDetailScreen extends StatefulWidget {
  final Character? character;
  final String seriesId;
  final String seriesName;
  final Function(Character) onSave;

  const CharacterDetailScreen({
    Key? key,
    this.character,
    required this.seriesId,
    required this.seriesName,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CharacterDetailScreen> createState() => _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends State<CharacterDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _personalityController;
  late List<String> _catchPhrases;
  late List<String> _tags;
  final TextEditingController _catchPhraseController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.character?.name ?? '');
    _descriptionController = TextEditingController(text: widget.character?.description ?? '');
    _personalityController = TextEditingController(text: widget.character?.personality ?? '');
    _catchPhrases = List<String>.from(widget.character?.catchPhrases ?? []);
    _tags = List<String>.from(widget.character?.tags ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _personalityController.dispose();
    _catchPhraseController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final character = Character(
        id: widget.character?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        seriesId: widget.seriesId,
        seriesName: widget.seriesName,
        description: _descriptionController.text.trim(),
        personality: _personalityController.text.trim(),
        catchPhrases: _catchPhrases,
        tags: _tags,
      );
      
      widget.onSave(character);
      Navigator.pop(context);
    }
  }

  void _addCatchPhrase() {
    final phrase = _catchPhraseController.text.trim();
    if (phrase.isNotEmpty && !_catchPhrases.contains(phrase)) {
      setState(() {
        _catchPhrases.add(phrase);
        _catchPhraseController.clear();
      });
    }
  }

  void _removeCatchPhrase(String phrase) {
    setState(() {
      _catchPhrases.remove(phrase);
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.character == null ? '새 캐릭터 추가' : '캐릭터 편집',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('저장'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 시리즈 정보
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '시리즈',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.seriesName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 기본 정보
              Text(
                '기본 정보',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              LabeledTextField(
                label: '캐릭터 이름',
                hint: '예: 셜록 홈즈',
                controller: _nameController,
                isRequired: true,
                borderColor: Colors.grey.shade300,
                focusedBorderColor: Colors.grey.shade400,
                labelColor: Colors.black87,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '캐릭터 이름을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              LabeledTextField(
                label: '캐릭터 설명',
                hint: '캐릭터의 특징, 배경 등을 설명하세요',
                controller: _descriptionController,
                isRequired: true,
                maxLines: 4,
                borderColor: Colors.grey.shade300,
                focusedBorderColor: Colors.grey.shade400,
                labelColor: Colors.black87,
                textAlign: TextAlign.justify,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '캐릭터 설명을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              LabeledTextField(
                label: '성격',
                hint: '캐릭터의 성격 특성을 설명하세요',
                controller: _personalityController,
                maxLines: 3,
                borderColor: Colors.grey.shade300,
                focusedBorderColor: Colors.grey.shade400,
                labelColor: Colors.black87,
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 24),
              
              // 대표 대사
              Text(
                '대표 대사',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              LabeledBorderContainer(
                label: '대표 대사 추가',
                borderColor: Colors.grey.shade300,
                focusedBorderColor: Colors.grey.shade400,
                labelColor: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _catchPhraseController,
                              decoration: InputDecoration(
                                hintText: '캐릭터의 대표적인 대사를 입력하세요',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onSubmitted: (_) => _addCatchPhrase(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: Colors.orange,
                            onPressed: _addCatchPhrase,
                            tooltip: '추가',
                          ),
                        ],
                      ),
                      if (_catchPhrases.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _catchPhrases.map((phrase) => IntrinsicWidth(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width - 80,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.format_quote, size: 16, color: Colors.blue[700]),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      phrase,
                                      style: TextStyle(color: Colors.blue[700]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _removeCatchPhrase(phrase),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // 태그
              Text(
                '태그',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              LabeledBorderContainer(
                label: '태그 추가',
                borderColor: Colors.grey.shade300,
                focusedBorderColor: Colors.grey.shade400,
                labelColor: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tagController,
                              decoration: InputDecoration(
                                hintText: '태그 입력 (예: 탐정, 주인공)',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onSubmitted: (_) => _addTag(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: Colors.orange,
                            onPressed: _addTag,
                            tooltip: '추가',
                          ),
                        ],
                      ),
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tags.map((tag) => IntrinsicWidth(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width - 80,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.label_outline, size: 16, color: Colors.orange[700]),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      tag,
                                      style: TextStyle(color: Colors.orange[700]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _removeTag(tag),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}