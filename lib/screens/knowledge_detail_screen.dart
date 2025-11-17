import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import '../models/knowledge.dart';
import '../providers/app_state_provider.dart';
import '../core/quiz_scheduler.dart';

class KnowledgeDetailScreen extends StatefulWidget {
  final Knowledge knowledge;

  const KnowledgeDetailScreen({
    super.key,
    required this.knowledge,
  });

  @override
  State<KnowledgeDetailScreen> createState() => _KnowledgeDetailScreenState();
}

class _KnowledgeDetailScreenState extends State<KnowledgeDetailScreen> {
  late Knowledge _knowledge;

  @override
  void initState() {
    super.initState();
    _knowledge = widget.knowledge;
  }

  /// Parse vocabulary content into word-meaning pairs
  List<Map<String, String>> _parseVocabularyContent(String content) {
    final lines = content.split('\n');
    final List<Map<String, String>> items = [];

    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      // Try to split by | and "Nghĩa là:"
      if (line.contains('|')) {
        final parts = line.split('|');
        if (parts.length >= 2) {
          final word = parts[0].trim();
          final meaning = parts[1]
              .trim()
              .replaceFirst(RegExp(r'^Nghĩa là:\s*', caseSensitive: false), '');
          items.add({'word': word, 'meaning': meaning});
        }
      } else {
        // Fallback for old format with colon
        final parts = line.split(':');
        if (parts.length >= 2) {
          items.add({'word': parts[0].trim(), 'meaning': parts[1].trim()});
        }
      }
    }

    return items;
  }

  Future<void> _editReminderTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _knowledge.reminderTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(_knowledge.reminderTime ?? DateTime.now()),
      );

      if (time != null) {
        final newReminderTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          _knowledge = _knowledge.copyWith(
            reminderTime: newReminderTime,
            lastModified: DateTime.now(),
          );
        });

        // Update in database
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        await appState.storage.updateKnowledge(_knowledge);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Đã cập nhật nhắc nhở: ${DateFormat('dd/MM/yyyy HH:mm').format(newReminderTime)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _parseVocabularyContent(_knowledge.content);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: Column(
        children: [
          // Custom Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                Text(
                  _knowledge.topic,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Start learning button
                FilledButton.icon(
                  onPressed: () {
                    QuizScheduler().triggerQuiz(knowledgeId: _knowledge.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Đang tạo quiz cho "${_knowledge.topic}"...'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context); // Back to home to see popup
                  },
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label:
                      const Text('Bắt đầu học', style: TextStyle(fontSize: 14)),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
                // Reminder button
                OutlinedButton.icon(
                  onPressed: _editReminderTime,
                  icon: const Icon(Icons.alarm, size: 20),
                  label: Text(
                    _knowledge.reminderTime != null
                        ? DateFormat('HH:mm dd/MM')
                            .format(_knowledge.reminderTime!)
                        : 'Chưa đặt',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
                // PDF Attach icon
                IconButton(
                  icon: const Icon(Icons.attach_file, size: 20),
                  onPressed: _importPdfToKnowledge,
                  tooltip: 'Thêm PDF',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                // PDF Preview icon
                if (_knowledge.pdfFiles.isNotEmpty)
                  IconButton(
                    icon: Badge(
                      label: Text('${_knowledge.pdfFiles.length}'),
                      child: const Icon(Icons.picture_as_pdf, size: 20),
                    ),
                    onPressed: _showPdfListPopup,
                    tooltip: 'Xem PDF (${_knowledge.pdfFiles.length})',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                const SizedBox(width: 12),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xóa tri thức'),
                        content:
                            const Text('Bạn có chắc muốn xóa tri thức này?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      final appState =
                          Provider.of<AppStateProvider>(context, listen: false);
                      await appState.storage.deleteKnowledge(_knowledge.id!);
                      await appState.refreshDashboard();
                      // Reload knowledge list
                      appState.loadKnowledgeList(isInitial: true);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã xóa tri thức'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                const SizedBox(width: 8),
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () {
                    // TODO: Implement edit knowledge
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chức năng sửa đang được phát triển'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Sửa',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Row(
                    children: [
                      const Text(
                        'Nội dung',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () {
                          // TODO: Add flashcard
                        },
                        child: const Text('Thêm kiến thức'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Flashcard content
                  if (items.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            _knowledge.content,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  else
                    ...items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                // Left side - Kiến thức
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Kiến thức',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item['word'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Divider
                                Container(
                                  width: 1,
                                  height: 80,
                                  color: Colors.grey.shade200,
                                ),
                                // Right side - Giải nghĩa
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Giải nghĩa',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item['meaning'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importPdfToKnowledge() async {
    try {
      // Pick PDF file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final newPdfFiles = <String>[];
      final extractedTexts = <String>[];

      for (var file in result.files) {
        if (file.path == null) continue;

        final filePath = file.path!;
        newPdfFiles.add(filePath);

        // Extract text from PDF
        try {
          final pdfFile = File(filePath);
          final PdfDocument document =
              PdfDocument(inputBytes: pdfFile.readAsBytesSync());
          final PdfTextExtractor extractor = PdfTextExtractor(document);
          final text = extractor.extractText();
          extractedTexts.add(text);
          document.dispose();
        } catch (e) {
          print('Error extracting text from $filePath: $e');
        }
      }

      // Update knowledge with new PDF files
      final updatedPdfFiles = [..._knowledge.pdfFiles, ...newPdfFiles];

      // Append extracted text to content if any
      String updatedContent = _knowledge.content;
      if (extractedTexts.isNotEmpty) {
        final combinedText = extractedTexts.join('\n\n');
        if (updatedContent.isNotEmpty) {
          updatedContent += '\n\n--- PDF Content ---\n\n$combinedText';
        } else {
          updatedContent = combinedText;
        }
      }

      final updatedKnowledge = _knowledge.copyWith(
        pdfFiles: updatedPdfFiles,
        content: updatedContent,
        lastModified: DateTime.now(),
      );

      // Save to database
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      await appState.storage.updateKnowledge(updatedKnowledge);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        setState(() {
          _knowledge = updatedKnowledge;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã import ${newPdfFiles.length} file PDF'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi import PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Shows a popup dialog displaying all PDF files attached to this knowledge.
  ///
  /// Displays a scrollable list of PDFs with:
  /// - File name and path
  /// - Remove button for each PDF
  ///
  /// The dialog is dismissible and updates state when PDFs are removed.
  void _showPdfListPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text('File PDF đã import'),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _importPdfToKnowledge();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm'),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: _knowledge.pdfFiles.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Chưa có file PDF nào',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _knowledge.pdfFiles.length,
                  itemBuilder: (context, index) {
                    final pdfPath = _knowledge.pdfFiles[index];
                    final fileName = pdfPath.split(Platform.pathSeparator).last;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  pdfPath,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _removePdfFile(pdfPath);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _removePdfFile(String pdfPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa file PDF'),
        content: Text(
            'Bạn có chắc muốn xóa file "${pdfPath.split(Platform.pathSeparator).last}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final updatedPdfFiles =
          _knowledge.pdfFiles.where((path) => path != pdfPath).toList();
      final updatedKnowledge = _knowledge.copyWith(
        pdfFiles: updatedPdfFiles,
        lastModified: DateTime.now(),
      );

      final appState = Provider.of<AppStateProvider>(context, listen: false);
      await appState.storage.updateKnowledge(updatedKnowledge);

      setState(() {
        _knowledge = updatedKnowledge;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa file PDF'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
