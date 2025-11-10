import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vocabulary.dart';
import '../core/storage_manager.dart';
import '../providers/app_state_provider.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final StorageManager _storage = StorageManager();
  List<Vocabulary> _vocabularies = [];
  bool _isLoading = true;
  String? _filterLanguage;

  @override
  void initState() {
    super.initState();
    _loadVocabularies();
  }

  Future<void> _loadVocabularies() async {
    setState(() => _isLoading = true);
    
    try {
      final vocabs = await _storage.getAllVocabulary(language: _filterLanguage);
      setState(() {
        _vocabularies = vocabs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading vocabulary: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterLanguage = value == 'all' ? null : value;
              });
              _loadVocabularies();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Languages')),
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'cn', child: Text('Chinese')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vocabularies.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadVocabularies,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vocabularies.length,
                    itemBuilder: (context, index) {
                      final vocab = _vocabularies[index];
                      return _VocabularyCard(
                        vocabulary: vocab,
                        onDelete: () => _deleteVocabulary(vocab.id!),
                        onEdit: () => _showAddEditDialog(vocab),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(null),
        icon: const Icon(Icons.add),
        label: const Text('Add Word'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No vocabulary yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first word to start learning',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddEditDialog(null),
            icon: const Icon(Icons.add),
            label: const Text('Add Word'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditDialog(Vocabulary? vocab) async {
    final result = await showDialog<Vocabulary>(
      context: context,
      builder: (context) => _VocabularyDialog(vocabulary: vocab),
    );

    if (result != null) {
      try {
        if (vocab == null) {
          await _storage.insertVocabulary(result);
        } else {
          await _storage.updateVocabulary(result);
        }
        _loadVocabularies();
        // Refresh dashboard statistics
        if (!mounted) return;
        Provider.of<AppStateProvider>(context, listen: false).refreshDashboard();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vocab == null ? 'Word added!' : 'Word updated!'),
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

  Future<void> _deleteVocabulary(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Word'),
        content: const Text('Are you sure you want to delete this word?'),
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
      await _storage.deleteVocabulary(id);
      _loadVocabularies();
      // Refresh dashboard statistics
      if (!mounted) return;
      Provider.of<AppStateProvider>(context, listen: false).refreshDashboard();
    }
  }
}

class _VocabularyCard extends StatelessWidget {
  final Vocabulary vocabulary;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _VocabularyCard({
    required this.vocabulary,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: vocabulary.language == 'en' 
              ? Colors.blue 
              : Colors.red,
          child: Text(
            vocabulary.language.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              vocabulary.word,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (vocabulary.pinyin != null) ...[
              const SizedBox(width: 8),
              Text(
                '(${vocabulary.pinyin})',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(vocabulary.meaningVi),
            if (vocabulary.timesShown > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Accuracy: ${(vocabulary.successRate * 100).toStringAsFixed(0)}% (${vocabulary.timesCorrect}/${vocabulary.timesShown})',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
        ),
      ),
    );
  }
}

class _VocabularyDialog extends StatefulWidget {
  final Vocabulary? vocabulary;

  const _VocabularyDialog({this.vocabulary});

  @override
  State<_VocabularyDialog> createState() => _VocabularyDialogState();
}

class _VocabularyDialogState extends State<_VocabularyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _wordController;
  late TextEditingController _pinyinController;
  late TextEditingController _meaningController;
  late TextEditingController _exampleController;
  late String _language;

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.vocabulary?.word);
    _pinyinController = TextEditingController(text: widget.vocabulary?.pinyin);
    _meaningController = TextEditingController(text: widget.vocabulary?.meaningVi);
    _exampleController = TextEditingController(text: widget.vocabulary?.exampleSentence);
    _language = widget.vocabulary?.language ?? 'en';
  }

  @override
  void dispose() {
    _wordController.dispose();
    _pinyinController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.vocabulary == null ? 'Add Word' : 'Edit Word'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'en', label: Text('English')),
                  ButtonSegment(value: 'cn', label: Text('Chinese')),
                ],
                selected: {_language},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _language = newSelection.first);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _wordController,
                decoration: InputDecoration(
                  labelText: _language == 'en' ? 'English Word' : 'Chinese Character',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
              if (_language == 'cn') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pinyinController,
                  decoration: const InputDecoration(
                    labelText: 'Pinyin',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _meaningController,
                decoration: const InputDecoration(
                  labelText: 'Vietnamese Meaning',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _exampleController,
                decoration: const InputDecoration(
                  labelText: 'Example Sentence (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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

    final vocab = Vocabulary(
      id: widget.vocabulary?.id,
      language: _language,
      word: _wordController.text.trim(),
      pinyin: _language == 'cn' ? _pinyinController.text.trim() : null,
      meaningVi: _meaningController.text.trim(),
      exampleSentence: _exampleController.text.trim(),
      timesCorrect: widget.vocabulary?.timesCorrect ?? 0,
      timesShown: widget.vocabulary?.timesShown ?? 0,
      lastShown: widget.vocabulary?.lastShown,
    );

    Navigator.pop(context, vocab);
  }
}
