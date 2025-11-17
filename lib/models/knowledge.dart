/// Represents a custom knowledge note
class Knowledge {
  final int? id;
  final String topic;
  final String content;
  final String description;
  final DateTime createdAt;
  final DateTime? reminderTime;
  final List<String> pdfFiles;
  final DateTime? lastModified;
  final String mode; // 'vocabulary' or 'normal'

  Knowledge({
    this.id,
    required this.topic,
    required this.content,
    this.description = '',
    DateTime? createdAt,
    this.reminderTime,
    List<String>? pdfFiles,
    this.lastModified,
    this.mode = 'normal',
  }) : createdAt = createdAt ?? DateTime.now(),
       pdfFiles = pdfFiles ?? [];

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'content': content,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'reminder_time': reminderTime?.toIso8601String(),
      'pdf_files': pdfFiles.join(','),
      'last_modified': (lastModified ?? DateTime.now()).toIso8601String(),
      'mode': mode,
    };
  }

  /// Create from database Map
  factory Knowledge.fromMap(Map<String, dynamic> map) {
    final pdfFilesStr = map['pdf_files'] as String? ?? '';
    return Knowledge(
      id: map['id'] as int?,
      topic: map['topic'] as String,
      content: map['content'] as String,
      description: map['description'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      reminderTime: map['reminder_time'] != null 
          ? DateTime.parse(map['reminder_time'] as String)
          : null,
      pdfFiles: pdfFilesStr.isEmpty ? [] : pdfFilesStr.split(','),
      lastModified: map['last_modified'] != null
          ? DateTime.parse(map['last_modified'] as String)
          : null,
      mode: map['mode'] as String? ?? 'normal',
    );
  }

  /// Create a copy with updated fields
  Knowledge copyWith({
    int? id,
    String? topic,
    String? content,
    String? description,
    DateTime? createdAt,
    DateTime? reminderTime,
    List<String>? pdfFiles,
    DateTime? lastModified,
    String? mode,
  }) {
    return Knowledge(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      content: content ?? this.content,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      reminderTime: reminderTime ?? this.reminderTime,
      pdfFiles: pdfFiles ?? this.pdfFiles,
      lastModified: lastModified ?? this.lastModified,
      mode: mode ?? this.mode,
    );
  }

  @override
  String toString() {
    return 'Knowledge(id: $id, topic: $topic)';
  }
}
