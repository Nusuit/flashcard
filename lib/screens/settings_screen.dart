import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/app_settings.dart';
import '../core/reminder_engine.dart';
import '../core/llm_question_generator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ReminderEngine _reminderEngine = ReminderEngine();
  bool _ollamaAvailable = false;
  List<String> _availableModels = [];
  bool _checkingOllama = false;

  @override
  void initState() {
    super.initState();
    _checkOllamaStatus();
  }

  Future<void> _checkOllamaStatus() async {
    setState(() => _checkingOllama = true);
    
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final generator = LLMQuestionGenerator(
      endpoint: appState.settings.ollamaEndpoint,
      model: appState.settings.ollamaModel,
    );

    final isAvailable = await generator.isAvailable();
    List<String> models = [];
    
    if (isAvailable) {
      models = await generator.getAvailableModels();
    }

    setState(() {
      _ollamaAvailable = isAvailable;
      _availableModels = models;
      _checkingOllama = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final settings = appState.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Reminder Settings
          _SectionHeader(title: 'Reminder Settings'),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Reminder Interval'),
            subtitle: Text('${settings.reminderIntervalHours} hours'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showIntervalDialog(context, appState),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Active Hours'),
            subtitle: Text('${settings.activeHoursStart}:00 - ${settings.activeHoursEnd}:00'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showActiveHoursDialog(context, appState),
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Questions per Session'),
            subtitle: Text('${settings.questionsPerSession} questions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showQuestionsDialog(context, appState),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Quiz Mode'),
            subtitle: Text(_getQuizModeText(settings.quizMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showQuizModeDialog(context, appState),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Test Notification'),
            subtitle: const Text('Show a sample quiz reminder'),
            trailing: const Icon(Icons.send),
            onTap: () => _testNotification(),
          ),

          const Divider(),

          // LLM Settings
          _SectionHeader(title: 'AI Settings'),
          ListTile(
            leading: Icon(
              Icons.smart_toy,
              color: _ollamaAvailable ? Colors.green : Colors.red,
            ),
            title: const Text('Ollama Status'),
            subtitle: Text(
              _checkingOllama
                  ? 'Checking...'
                  : _ollamaAvailable
                      ? 'Connected'
                      : 'Not available',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _checkOllamaStatus,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Ollama Endpoint'),
            subtitle: Text(settings.ollamaEndpoint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showEndpointDialog(context, appState),
          ),
          if (_availableModels.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.memory),
              title: const Text('AI Model'),
              subtitle: Text(settings.ollamaModel),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showModelDialog(context, appState),
            ),

          const Divider(),

          // Appearance
          _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            secondary: Icon(
              settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle dark theme'),
            value: settings.isDarkMode,
            onChanged: (value) => appState.toggleDarkMode(),
          ),

          const Divider(),

          // About
          _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('GitHub'),
            subtitle: const Text('View source code'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // Open GitHub link
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Clear All Data',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Delete all vocabulary and knowledge'),
            onTap: () => _showClearDataDialog(context),
          ),
        ],
      ),
    );
  }

  String _getQuizModeText(QuizMode mode) {
    switch (mode) {
      case QuizMode.language:
        return 'Language only';
      case QuizMode.knowledge:
        return 'Knowledge only';
      case QuizMode.both:
        return 'Language & Knowledge';
    }
  }

  Future<void> _showIntervalDialog(BuildContext context, AppStateProvider appState) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Reminder Interval'),
        children: [1, 2, 3].map((hours) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, hours),
            child: Text('$hours hour${hours > 1 ? "s" : ""}'),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      final newSettings = appState.settings.copyWith(reminderIntervalHours: result);
      await appState.updateSettings(newSettings);
      await _reminderEngine.scheduleReminders(newSettings);
    }
  }

  Future<void> _showActiveHoursDialog(BuildContext context, AppStateProvider appState) async {
    int startHour = appState.settings.activeHoursStart;
    int endHour = appState.settings.activeHoursEnd;

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Active Hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Start Hour'),
                trailing: DropdownButton<int>(
                  value: startHour,
                  items: List.generate(24, (i) => i).map((hour) {
                    return DropdownMenuItem(
                      value: hour,
                      child: Text('${hour.toString().padLeft(2, '0')}:00'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && value < endHour) {
                      setState(() => startHour = value);
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('End Hour'),
                trailing: DropdownButton<int>(
                  value: endHour,
                  items: List.generate(24, (i) => i).map((hour) {
                    return DropdownMenuItem(
                      value: hour,
                      child: Text('${hour.toString().padLeft(2, '0')}:00'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && value > startHour) {
                      setState(() => endHour = value);
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'start': startHour,
                'end': endHour,
              }),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final newSettings = appState.settings.copyWith(
        activeHoursStart: result['start'],
        activeHoursEnd: result['end'],
      );
      await appState.updateSettings(newSettings);
      await _reminderEngine.scheduleReminders(newSettings);
    }
  }

  Future<void> _showQuestionsDialog(BuildContext context, AppStateProvider appState) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Questions per Session'),
        children: [1, 2, 3, 5, 10].map((count) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, count),
            child: Text('$count question${count > 1 ? "s" : ""}'),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      final newSettings = appState.settings.copyWith(questionsPerSession: result);
      await appState.updateSettings(newSettings);
    }
  }

  Future<void> _showQuizModeDialog(BuildContext context, AppStateProvider appState) async {
    final result = await showDialog<QuizMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Quiz Mode'),
        children: QuizMode.values.map((mode) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, mode),
            child: Text(_getQuizModeText(mode)),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      final newSettings = appState.settings.copyWith(quizMode: result);
      await appState.updateSettings(newSettings);
    }
  }

  Future<void> _showEndpointDialog(BuildContext context, AppStateProvider appState) async {
    final controller = TextEditingController(text: appState.settings.ollamaEndpoint);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ollama Endpoint'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Endpoint URL',
            hintText: 'http://localhost:11434',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final newSettings = appState.settings.copyWith(ollamaEndpoint: result);
      await appState.updateSettings(newSettings);
      _checkOllamaStatus();
    }
  }

  Future<void> _showModelDialog(BuildContext context, AppStateProvider appState) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select AI Model'),
        children: _availableModels.map((model) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, model),
            child: Text(model),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      final newSettings = appState.settings.copyWith(ollamaModel: result);
      await appState.updateSettings(newSettings);
    }
  }

  Future<void> _testNotification() async {
    await _reminderEngine.showQuizNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification sent! Check your notification tray.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showClearDataDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all vocabulary, knowledge notes, and quiz history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear data
      // TODO: Implement clear all data
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
