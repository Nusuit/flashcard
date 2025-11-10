import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/knowledge.dart';
import '../models/quiz_question.dart';
import '../core/storage_manager.dart';
import '../core/llm_question_generator.dart';
import '../providers/app_state_provider.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  final StorageManager _storage = StorageManager();
  List<Knowledge> _knowledgeItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKnowledge();
  }

  Future<void> _loadKnowledge() async {
    setState(() => _isLoading = true);
    
    try {
      final items = await _storage.getAllKnowledge();
      setState(() {
        _knowledgeItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading knowledge: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Notes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _knowledgeItems.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadKnowledge,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _knowledgeItems.length,
                    itemBuilder: (context, index) {
                      final knowledge = _knowledgeItems[index];
                      return _KnowledgeCard(
                        knowledge: knowledge,
                        onTap: () => _showKnowledgeDetail(knowledge),
                        onDelete: () => _deleteKnowledge(knowledge.id!),
                        onEdit: () => _showAddEditDialog(knowledge),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(null),
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No knowledge notes yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add study material to generate quiz questions',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddEditDialog(null),
            icon: const Icon(Icons.add),
            label: const Text('Add Note'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditDialog(Knowledge? knowledge) async {
    final result = await showDialog<Knowledge>(
      context: context,
      builder: (context) => _KnowledgeDialog(knowledge: knowledge),
    );

    if (result != null) {
      try {
        if (knowledge == null) {
          await _storage.insertKnowledge(result);
        } else {
          await _storage.updateKnowledge(result);
        }
        _loadKnowledge();
        // Refresh dashboard statistics
        if (!mounted) return;
        Provider.of<AppStateProvider>(context, listen: false).refreshDashboard();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(knowledge == null ? 'Note added!' : 'Note updated!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteKnowledge(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('This will also delete all generated questions. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.deleteKnowledge(id);
      _loadKnowledge();
      // Refresh dashboard statistics
      if (!mounted) return;
      Provider.of<AppStateProvider>(context, listen: false).refreshDashboard();
    }
  }

  void _showKnowledgeDetail(Knowledge knowledge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KnowledgeDetailScreen(knowledge: knowledge),
      ),
    ).then((_) => _loadKnowledge());
  }
}

class _KnowledgeCard extends StatelessWidget {
  final Knowledge knowledge;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _KnowledgeCard({
    required this.knowledge,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.amber,
          child: Icon(Icons.lightbulb, color: Colors.white),
        ),
        title: Text(
          knowledge.topic,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              knowledge.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) {
            if (value == 'view') onTap();
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
        ),
        onTap: onTap,
      ),
    );
  }
}

class _KnowledgeDialog extends StatefulWidget {
  final Knowledge? knowledge;

  const _KnowledgeDialog({this.knowledge});

  @override
  State<_KnowledgeDialog> createState() => _KnowledgeDialogState();
}

class _KnowledgeDialogState extends State<_KnowledgeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _topicController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: widget.knowledge?.topic);
    _contentController = TextEditingController(text: widget.knowledge?.content);
  }

  @override
  void dispose() {
    _topicController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.knowledge == null ? 'Add Note' : 'Edit Note'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., JavaScript, Math, Physics',
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  hintText: 'Paste your study notes here...',
                ),
                maxLines: 8,
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;

    final knowledge = Knowledge(
      id: widget.knowledge?.id,
      topic: _topicController.text.trim(),
      content: _contentController.text.trim(),
    );

    Navigator.pop(context, knowledge);
  }
}

class KnowledgeDetailScreen extends StatefulWidget {
  final Knowledge knowledge;

  const KnowledgeDetailScreen({super.key, required this.knowledge});

  @override
  State<KnowledgeDetailScreen> createState() => _KnowledgeDetailScreenState();
}

class _KnowledgeDetailScreenState extends State<KnowledgeDetailScreen> {
  final StorageManager _storage = StorageManager();
  List<QuizQuestion> _questions = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    
    try {
      final questions = await _storage.getQuestionsByKnowledgeId(widget.knowledge.id!);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateQuestions() async {
    setState(() => _isGenerating = true);

    try {
      final generator = LLMQuestionGenerator();
      
      // Check if Ollama is available
      final isAvailable = await generator.isAvailable();
      if (!isAvailable) {
        throw Exception('Ollama is not running. Please start Ollama first.');
      }

      // Generate questions
      final newQuestions = await generator.generateQuestions(
        knowledge: widget.knowledge,
        numberOfQuestions: 3,
      );

      // Save questions
      await _storage.insertQuizQuestions(newQuestions);
      
      await _loadQuestions();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generated ${newQuestions.length} questions!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.knowledge.topic),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Content card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.knowledge.content),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Generate button
            FilledButton.icon(
              onPressed: _isGenerating ? null : _generateQuestions,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Questions with AI'),
            ),
            const SizedBox(height: 24),

            // Questions section
            Text(
              'Generated Questions (${_questions.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_questions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.quiz_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No questions yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use AI to generate quiz questions',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_questions.length, (index) {
                final question = _questions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(question.question),
                    subtitle: Text(
                      'Type: ${question.questionType.name}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Answer:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(question.answer),
                                ],
                              ),
                            ),
                            if (question.options != null) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Options:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              ...question.options!.map(
                                (opt) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text('• $opt'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
