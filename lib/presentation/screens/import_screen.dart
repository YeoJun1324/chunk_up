// lib/screens/import_screen.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/data/services/excel_import_service.dart';
import 'package:chunk_up/data/services/csv_import_service.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isLoading = false;
  String _fileName = '';
  PlatformFile? _selectedFile;
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickExcelFile() async {
    try {
      // 가능한 모든 옵션 지정
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: '엑셀 파일 선택',
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
        withData: true,
        withReadStream: false,
        lockParentWindow: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _fileName = _selectedFile!.name;
        });
      }
    } catch (e) {
      print('파일 선택 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('파일 선택 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importExcel() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('엑셀 파일을 먼저 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = _selectedFile!.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('파일 데이터를 읽을 수 없습니다.');
      }

      // 파일 정보 로깅
      print('처리 중인 파일: ${_selectedFile!.name}, 크기: ${bytes.length} 바이트');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('엑셀 파일 분석 중...'),
          duration: Duration(seconds: 1),
        ),
      );

      final wordLists = await ExcelImportService.importFromExcelBytes(
        bytes,
        defaultName: _fileName.replaceAll('.xlsx', '').replaceAll('.xls', ''),
      );

      // Excel 파싱에 실패했거나 단어가 없는 경우 CSV로 시도
      if (wordLists.isEmpty) {
        print('Excel 파싱 실패, CSV로 시도합니다');

        // Excel 파일을 CSV로 변환 시도
        final csvContent = CsvImportService.tryConvertExcelToCsv(bytes);

        if (csvContent != null) {
          final csvWordList = await CsvImportService.importFromCsvString(
            csvContent,
            _fileName.replaceAll('.xlsx', '').replaceAll('.xls', ''),
          );

          if (csvWordList != null) {
            // CSV 방식으로 단어장 추가 성공
            final notifier = Provider.of<WordListNotifier>(context, listen: false);
            final success = await CsvImportService.addWordListToNotifier(notifier, csvWordList);

            if (success) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('CSV 모드로 "${csvWordList.name}" 단어장에 ${csvWordList.words.length}개의 단어가 추가되었습니다.'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 5),
                  ),
                );
                Navigator.pop(context);
              }
              return;
            }
          }
        }

        // 모든 방법 실패 시 오류 메시지
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('엑셀 파일을 CSV로도 처리할 수 없습니다. 파일 형식을 확인해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (wordLists.isNotEmpty) {
        final notifier = Provider.of<WordListNotifier>(context, listen: false);

        // 진행 상태 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('단어장 추가 중...'),
            duration: Duration(seconds: 1),
          ),
        );

        final addedCount = await ExcelImportService.addWordListsToNotifier(notifier, wordLists);

        int totalWords = 0;
        for (var list in wordLists) {
          totalWords += list.words.length;
        }

        if (mounted) {
          // 시트별로 단어장 정보 표시
          String detailMessage = wordLists.map((list) =>
          '• ${list.name}: ${list.words.length}개 단어'
          ).join('\n');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$addedCount개의 단어장에 총 $totalWords개의 단어가 추가되었습니다.'),
                  const SizedBox(height: 4),
                  Text(
                    detailMessage,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('엑셀 파일에서 단어를 가져오지 못했습니다. 파일 형식을 확인해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('가져오기 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어장 가져오기'),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('엑셀 파일을 처리하고 있습니다...'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '엑셀 파일에서 단어장 가져오기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '엑셀 파일은 첫 번째 열에 영어 단어, 두 번째 열에 한국어 의미가 있어야 합니다.\n'
                    '첫 번째 행이 헤더인 경우 자동으로 감지됩니다.\n'
                    '각 시트는 별도의 단어장으로 가져와집니다.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // 파일 선택 버튼
              Center(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_upload),
                      label: const Text('엑셀 파일 선택'),
                      onPressed: _pickExcelFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_fileName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Icon(Icons.description, color: Colors.green, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              _fileName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '크기: ${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 가져오기 참고사항
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          '가져오기 참고사항',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 파일의 각 시트는 별도의 단어장으로 생성됩니다.\n'
                          '• 영어와 한국어가 모두 입력된 행만 가져옵니다.\n'
                          '• 이미 같은 이름의 단어장이 있으면 이름 뒤에 번호가 추가됩니다.\n'
                          '• 대용량 파일의 경우 처리에 시간이 다소 걸릴 수 있습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 가져오기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedFile != null ? _importExcel : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('가져오기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}