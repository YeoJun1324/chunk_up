import 'package:flutter/material.dart';
import 'package:chunk_up/core/services/prompt_template_service.dart';
import 'package:chunk_up/core/constants/prompt_templates.dart';
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
      debugPrint('Error loading templates: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setActiveTemplate(String templateId) async {
    await _templateService.setActiveTemplate(templateId);
    setState(() {
      _activeTemplateId = templateId;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('템플릿이 활성화되었습니다'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteTemplate(String templateId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('템플릿 삭제'),
        content: Text('이 템플릿을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _templateService.deleteTemplate(templateId);
      await _loadTemplates();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('템플릿이 삭제되었습니다'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _duplicateTemplate(String templateId) async {
    final nameController = TextEditingController();
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('템플릿 복제'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: '새 템플릿 이름',
            hintText: '복제된 템플릿의 이름을 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text('복제'),
          ),
        ],
      ),
    );
    
    if (newName != null && newName.isNotEmpty) {
      await _templateService.duplicateTemplate(templateId, newName);
      await _loadTemplates();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('템플릿이 복제되었습니다'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _showTemplateStatistics() async {
    final stats = await _templateService.getTemplateStatistics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('템플릿 통계'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatItem('총 템플릿 수', '${stats['totalTemplates']}개'),
              _buildStatItem('총 생성된 프롬프트', '${stats['totalPrompts']}개'),
              _buildStatItem('평균 품질 점수', '${stats['averageQualityScore'].toStringAsFixed(1)}점'),
              SizedBox(height: 16),
              Text('출력 형식 분포', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(stats['outputFormatDistribution'] as Map<String, int>).entries.map(
                (e) => _buildStatItem(e.key, '${e.value}개'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프롬프트 템플릿 관리'),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: _showTemplateStatistics,
            tooltip: '통계 보기',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // TODO: 템플릿 생성 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('템플릿 생성 기능은 준비 중입니다')),
              );
            },
            tooltip: '새 템플릿',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('템플릿이 없습니다', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    final isActive = template.id == _activeTemplateId;
                    
                    return Card(
                      elevation: isActive ? 4 : 1,
                      color: isActive ? Colors.orange.shade50 : null,
                      margin: EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: Icon(
                          _getIconForOutputFormat(template.outputFormat),
                          color: isActive ? Colors.orange : Colors.grey,
                        ),
                        title: Text(
                          template.name,
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(template.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isActive)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '활성',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'activate':
                                    _setActiveTemplate(template.id);
                                    break;
                                  case 'duplicate':
                                    _duplicateTemplate(template.id);
                                    break;
                                  case 'export':
                                    // TODO: 템플릿 내보내기
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('내보내기 기능은 준비 중입니다')),
                                    );
                                    break;
                                  case 'delete':
                                    _deleteTemplate(template.id);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                if (!isActive)
                                  PopupMenuItem(
                                    value: 'activate',
                                    child: ListTile(
                                      leading: Icon(Icons.check_circle_outline),
                                      title: Text('활성화'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                PopupMenuItem(
                                  value: 'duplicate',
                                  child: ListTile(
                                    leading: Icon(Icons.copy),
                                    title: Text('복제'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'export',
                                  child: ListTile(
                                    leading: Icon(Icons.download),
                                    title: Text('내보내기'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                if (template.id != 'default_narrative')
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete, color: Colors.red),
                                      title: Text('삭제', style: TextStyle(color: Colors.red)),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('출력 형식', _getOutputFormatName(template.outputFormat)),
                                _buildInfoRow('버전', 'v${template.version}'),
                                _buildInfoRow('생성일', _formatDate(template.createdAt)),
                                if (template.updatedAt != null)
                                  _buildInfoRow('수정일', _formatDate(template.updatedAt!)),
                                SizedBox(height: 16),
                                Text('섹션:', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                ...template.sections.entries.map((entry) => 
                                  Padding(
                                    padding: EdgeInsets.only(left: 16, bottom: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        Text(
                                          entry.value,
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
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