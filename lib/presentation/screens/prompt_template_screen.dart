import 'package:flutter/material.dart';
import 'package:chunk_up/domain/services/prompt/prompt_template_service.dart';
import 'package:chunk_up/core/constants/prompt_templates.dart';
import 'package:chunk_up/core/constants/prompt_config.dart';
import 'package:chunk_up/presentation/widgets/labeled_border_container.dart';

/// 프롬프트 템플릿 관리 화면
class PromptTemplateScreen extends StatefulWidget {
  const PromptTemplateScreen({super.key});

  @override
  State<PromptTemplateScreen> createState() => _PromptTemplateScreenState();
}

class _PromptTemplateScreenState extends State<PromptTemplateScreen> {
  final PromptTemplateService _templateService = PromptTemplateService();
  List<CustomPromptTemplate> _templates = [];
  String? _activeTemplateId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    
    try {
      // 기본 템플릿 초기화
      await _templateService.initializeDefaultTemplates();
      
      // 템플릿 목록 로드
      final templates = await _templateService.getTemplates();
      final activeId = await _templateService.getActiveTemplateId();
      
      setState(() {
        _templates = templates;
        _activeTemplateId = activeId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('템플릿 로드 실패: $e')),
        );
      }
    }
  }

  Future<void> _setActiveTemplate(String templateId) async {
    try {
      await _templateService.setActiveTemplate(templateId);
      setState(() {
        _activeTemplateId = templateId;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('템플릿이 활성화되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('템플릿 활성화 실패: $e')),
        );
      }
    }
  }

  Future<void> _deleteTemplate(String templateId) async {
    // 기본 템플릿은 삭제 불가
    final template = _templates.firstWhere((t) => t.id == templateId);
    if (template.id == 'default') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기본 템플릿은 삭제할 수 없습니다')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('템플릿 삭제'),
        content: Text('${template.name} 템플릿을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _templateService.deleteTemplate(templateId);
        await _loadTemplates();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('템플릿이 삭제되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('템플릿 삭제 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프롬프트 템플릿 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: 템플릿 추가 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('템플릿 추가 기능은 준비 중입니다')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                final isActive = template.id == _activeTemplateId;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isActive ? 4 : 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive ? Colors.blue : Colors.grey,
                      child: Icon(
                        _getIconForOutputFormat(template.outputFormat),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      template.name,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template.description),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getOutputFormatName(template.outputFormat),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '버전 ${template.version}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(template.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '활성',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'activate':
                                _setActiveTemplate(template.id);
                                break;
                              case 'edit':
                                // TODO: 편집 화면으로 이동
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('템플릿 편집 기능은 준비 중입니다'),
                                  ),
                                );
                                break;
                              case 'duplicate':
                                // TODO: 복제 기능
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('템플릿 복제 기능은 준비 중입니다'),
                                  ),
                                );
                                break;
                              case 'delete':
                                _deleteTemplate(template.id);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            if (!isActive)
                              const PopupMenuItem(
                                value: 'activate',
                                child: Text('활성화'),
                              ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('편집'),
                            ),
                            const PopupMenuItem(
                              value: 'duplicate',
                              child: Text('복제'),
                            ),
                            if (template.id != 'default')
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  '삭제',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(template.name),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LabeledBorderContainer(
                                  label: '설명',
                                  child: Text(template.description),
                                ),
                                const SizedBox(height: 16),
                                LabeledBorderContainer(
                                  label: '출력 형식',
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getIconForOutputFormat(template.outputFormat),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(_getOutputFormatName(template.outputFormat)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                LabeledBorderContainer(
                                  label: '섹션',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: template.sections.entries.map((entry) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.key,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              entry.value,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Text(
                                      '생성일: ${_formatDate(template.createdAt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (template.updatedAt != null) ...[
                                      const SizedBox(width: 16),
                                      Text(
                                        '수정일: ${_formatDate(template.updatedAt!)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('닫기'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  IconData _getIconForOutputFormat(OutputFormat format) {
    switch (format) {
      case OutputFormat.dialogue:
        return Icons.chat;
      case OutputFormat.monologue:
        return Icons.person;
      case OutputFormat.narrative:
        return Icons.book;
      case OutputFormat.thought:
        return Icons.psychology;
      case OutputFormat.letter:
        return Icons.email;
      case OutputFormat.description:
        return Icons.landscape;
    }
  }

  String _getOutputFormatName(OutputFormat format) {
    switch (format) {
      case OutputFormat.dialogue:
        return '대화문';
      case OutputFormat.monologue:
        return '독백';
      case OutputFormat.narrative:
        return '나레이션';
      case OutputFormat.thought:
        return '내적 독백';
      case OutputFormat.letter:
        return '편지/일기';
      case OutputFormat.description:
        return '상황 묘사';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}