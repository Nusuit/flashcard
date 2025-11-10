import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../core/flashcard_engine.dart';
import '../core/reminder_engine.dart';
import 'vocabulary_screen.dart';
import 'knowledge_screen.dart';
import 'settings_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const VocabularyScreen(),
    const KnowledgeScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Vocabulary',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Knowledge',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎴 Knop Flashcard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              appState.settings.isDarkMode 
                  ? Icons.light_mode 
                  : Icons.dark_mode,
            ),
            onPressed: () => appState.toggleDarkMode(),
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: appState.refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ready to practice your flashcards?',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _startQuiz(context),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Quiz Now'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Statistics cards
              Text(
                'Statistics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatisticsGrid(context, appState),
              const SizedBox(height: 24),

              // Library overview
              Text(
                'Your Library',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildLibraryCards(context, appState),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startQuiz(context),
        icon: const Icon(Icons.quiz),
        label: const Text('Quick Quiz'),
      ),
    );
  }

  Widget _buildStatisticsGrid(BuildContext context, AppStateProvider appState) {
    final stats = appState.statistics;
    final total = stats['total'] ?? 0;
    final correct = stats['correct'] ?? 0;
    final accuracy = stats['accuracy'] ?? '0.0';

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.quiz,
            title: 'Total Quizzes',
            value: total.toString(),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle,
            title: 'Correct',
            value: correct.toString(),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up,
            title: 'Accuracy',
            value: '$accuracy%',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildLibraryCards(BuildContext context, AppStateProvider appState) {
    final counts = appState.counts;
    
    return Column(
      children: [
        _LibraryCard(
          icon: Icons.book,
          title: 'Vocabulary',
          count: counts['vocabulary'] ?? 0,
          color: Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VocabularyScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _LibraryCard(
          icon: Icons.lightbulb,
          title: 'Knowledge Notes',
          count: counts['knowledge'] ?? 0,
          color: Colors.amber,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KnowledgeScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _LibraryCard(
          icon: Icons.question_answer,
          title: 'Quiz Questions',
          count: counts['questions'] ?? 0,
          color: Colors.teal,
          onTap: () {},
        ),
      ],
    );
  }

  Future<void> _startQuiz(BuildContext context) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    
    // Check if there's any content
    if (appState.totalItems == 0) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add some vocabulary or knowledge notes first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to quiz screen
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(settings: appState.settings),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _LibraryCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count items',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
