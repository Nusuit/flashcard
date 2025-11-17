import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import '../models/knowledge.dart';

class CreateKnowledgeDialog extends StatefulWidget {
  final Knowledge? knowledge;

  const CreateKnowledgeDialog({super.key, this.knowledge});

  @override
  State<CreateKnowledgeDialog> createState() => _CreateKnowledgeDialogState();
}

class _CreateKnowledgeDialogState extends State<CreateKnowledgeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime? _reminderTime;
  String _selectedMode = 'normal'; // 'vocabulary' or 'normal'

  @override
  void initState() {
    super.initState();
    if (widget.knowledge != null) {
      _topicController.text = widget.knowledge!.topic;
      _descriptionController.text = widget.knowledge!.description;
      _contentController.text = widget.knowledge!.content;
      _reminderTime = widget.knowledge!.reminderTime;
      _selectedMode = widget.knowledge!.mode;
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderTime ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _reminderTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _importFromPdf() async {
    try {
      // Pick PDF file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Load PDF document
      final PdfDocument document =
          PdfDocument(inputBytes: file.readAsBytesSync());

      // Extract text from all pages
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      String extractedText = extractor.extractText();

      // Close document
      document.dispose();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Update content field
        setState(() {
          _contentController.text = extractedText;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Đã import ${extractedText.split('\\n').length} dòng từ PDF'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đọc PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final knowledge = Knowledge(
        id: widget.knowledge?.id,
        topic: _topicController.text.trim(),
        description: _descriptionController.text.trim(),
        content: _contentController.text.trim(),
        reminderTime: _reminderTime,
        createdAt: widget.knowledge?.createdAt ?? DateTime.now(),
        lastModified: DateTime.now(),
        mode: _selectedMode,
      );
      Navigator.of(context).pop(knowledge);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '💡',
                      style: TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.knowledge == null
                          ? 'Tạo Trí Thức Mới'
                          : 'Chỉnh Sửa Trí Thức',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thêm kiến thức mới vào chủ đề học tập của bạn',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // Topic field
                Row(
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Text(
                      'Tên Trí Thức *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _topicController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên trí thức...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên tri thức';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mode selector
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loại Tri Thức',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Từ vựng'),
                              subtitle: const Text('Có giải nghĩa'),
                              value: 'vocabulary',
                              groupValue: _selectedMode,
                              onChanged: (value) {
                                setState(() {
                                  _selectedMode = value!;
                                });
                              },
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Thông thường'),
                              subtitle: const Text('Không bắt buộc nghĩa'),
                              value: 'normal',
                              groupValue: _selectedMode,
                              onChanged: (value) {
                                setState(() {
                                  _selectedMode = value!;
                                });
                              },
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description field
                Row(
                  children: [
                    const Text('📋', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Text(
                      'Mô Tả',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Thêm mô tả...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Content field
                Row(
                  children: [
                    const Text('📄', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Text(
                      'Nội Dung *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _importFromPdf,
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Import PDF'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF87CEEB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kiến thức',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _contentController,
                            decoration: InputDecoration(
                              hintText: 'Nhập kiến thức...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            maxLines: 6,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập nội dung';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giải nghĩa',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            decoration: InputDecoration(
                              hintText: 'Nhập giải nghĩa...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            maxLines: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Reminder time
                InkWell(
                  onTap: _selectDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.alarm, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hẹn Giờ Nhắc Nhở',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _reminderTime != null
                                    ? DateFormat('dd/MM/yyyy HH:mm')
                                        .format(_reminderTime!)
                                    : 'Chưa đặt giờ',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        if (_reminderTime != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _reminderTime = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check),
                      label: Text(
                        widget.knowledge == null ? 'Tạo Mới' : 'Cập Nhật',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
