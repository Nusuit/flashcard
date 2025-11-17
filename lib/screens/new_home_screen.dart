import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../models/knowledge.dart';
import '../models/quiz_question.dart';
import '../widgets/create_knowledge_dialog.dart';
import '../widgets/flashcard_overlay.dart';
import '../widgets/review_analytics_dialog.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/quiz_popup.dart';
import '../core/quiz_scheduler.dart';
import '../core/quiz_queue_builder.dart';
import '../core/quiz_event_bus.dart';
import '../core/storage_manager.dart';
import 'knowledge_detail_screen.dart';
import 'dart:async';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  Knowledge? _selectedKnowledge;
  Knowledge? _selectedDashboardKnowledge; // For dashboard dropdown filter
  bool _showOverlay = false;
  QuizQuestion? _currentQuiz;
  Knowledge? _currentQuizKnowledge;
  final QuizScheduler _quizScheduler = QuizScheduler();
  final StorageManager _storageManager = StorageManager();
  StreamSubscription<QuizEvent>? _quizEventSubscription;
  int? _currentQueueItemId; // Track queue item ID for SM-2 updates
  final ScrollController _knowledgeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Listen to quiz events via EventBus (with error handling)
    _quizEventSubscription = _quizScheduler.eventBus.stream.listen(
      (event) {
        debugPrint('>>> EVENT BUS: Received event type: ${event.type}');
        if (event.type == QuizEventType.quizReady && mounted) {
          debugPrint('>>> EVENT: QuizReady received');
          debugPrint('>>> EVENT DATA: ${event.data?.keys}');
          final question = event.data?['question'] as QuizQuestion?;
          final knowledge = event.data?['knowledge'] as Knowledge?;
          final queueId = event.data?['queueItemId'] as int?;
          debugPrint('>>> QUESTION: ${question?.question}');
          debugPrint('>>> KNOWLEDGE: ${knowledge?.topic}');
          debugPrint('>>> QUEUE_ID: $queueId');
          setState(() {
            _currentQuiz = question;
            _currentQuizKnowledge = knowledge;
            _currentQueueItemId = queueId;
            debugPrint(
                '>>> STATE UPDATED: currentQuiz=${_currentQuiz != null}, knowledge=${_currentQuizKnowledge != null}');
          });
        }
      },
      onError: (error) {
        debugPrint('!!! EVENT BUS ERROR: $error');
      },
    );

    // Add scroll listener for knowledge list pagination
    _knowledgeScrollController.addListener(() {
      if (_knowledgeScrollController.position.pixels >=
          _knowledgeScrollController.position.maxScrollExtent * 0.8) {
        // Load more when scrolled to 80% of the list
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        appState.loadKnowledgeList();
      }
    });

    // Start scheduler with 30-minute interval
    _quizScheduler.start();
  }

  @override
  void dispose() {
    _quizEventSubscription?.cancel();
    _quizScheduler.stop();
    _knowledgeScrollController.dispose();
    super.dispose();
  }

  void _onQuizAnswered(bool isCorrect, int score) async {
    if (_currentQuiz == null) return;

    // Update question statistics
    final updatedQuestion = _currentQuiz!.copyWith(
      timesShown: _currentQuiz!.timesShown + 1,
      timesCorrect: _currentQuiz!.timesCorrect + (isCorrect ? 1 : 0),
      lastShown: DateTime.now(),
    );

    await _storageManager.updateQuizQuestion(updatedQuestion);

    // Update quiz queue with SM-2 algorithm (non-blocking)
    if (_currentQueueItemId != null) {
      QuizQueueBuilder()
          .updateAfterAnswer(_currentQueueItemId!, score, isCorrect);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(context),
          // Main content
          Expanded(
            child: Stack(
              children: [
                _buildMainContent(context),
                // Overlay widget
                if (_showOverlay && _selectedKnowledge != null)
                  FlashcardOverlay(
                    item: _selectedKnowledge!,
                    onDismiss: () {
                      setState(() {
                        _showOverlay = false;
                      });
                    },
                    mode: OverlayMode.transparent,
                  ),
                // Quiz popup at top-right
                if (_currentQuiz != null && _currentQuizKnowledge != null)
                  QuizPopup(
                    question: _currentQuiz!,
                    knowledgeContent: _currentQuizKnowledge!.content,
                    onClose: () {
                      setState(() {
                        _currentQuiz = null;
                        _currentQuizKnowledge = null;
                      });
                    },
                    onAnswered: _onQuizAnswered,
                  ),
                // Chat bubble at bottom-right
                const ChatBubble(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 224,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_stories,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Knop',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Knowledge Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Kiến thức',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  color: theme.colorScheme.primary,
                  onPressed: () => _showCreateKnowledgeDialog(context),
                  tooltip: 'Tạo tri thức mới',
                ),
              ],
            ),
          ),

          // Knowledge list
          Expanded(
            child: Consumer<AppStateProvider>(
              builder: (context, appState, _) {
                final knowledgeList = appState.knowledgeListItems;
                final isLoading = appState.isLoadingKnowledge;

                if (knowledgeList.isEmpty && !isLoading) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có tri thức nào',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _knowledgeScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: knowledgeList.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading indicator at the end
                    if (index == knowledgeList.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    final knowledge = knowledgeList[index];
                    final isSelected = _selectedKnowledge?.id == knowledge.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lightbulb,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          knowledge.topic,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: knowledge.description.isNotEmpty
                            ? Text(
                                knowledge.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                        selected: isSelected,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedKnowledge = knowledge;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KnowledgeDetailScreen(
                                knowledge: knowledge,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Settings button
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: const Icon(Icons.settings, size: 20),
            title: const Text(
              'Cài đặt',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              // Navigate to settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Dashboard',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () => _showKnowledgeSelectionDialog(
                              isForDashboard: true),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedDashboardKnowledge?.topic ??
                                      'Toàn bộ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chào mừng trở lại! Hãy theo dõi tiến độ học tập của bạn.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showKnowledgeSelectionDialog(isForQuiz: true),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Bắt đầu học'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Statistics cards
          FutureBuilder<Map<String, dynamic>>(
            future: appState.storage.getStatistics(),
            builder: (context, snapshot) {
              final stats = snapshot.data ??
                  {'total': 0, 'correct': 0, 'accuracy': '0.0'};

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Tổng Câu Hỏi',
                      stats['total'].toString(),
                      Icons.quiz,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Trả Lời Đúng',
                      stats['correct'].toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Độ Chính Xác',
                      '${stats['accuracy']}%',
                      Icons.trending_up,
                      Colors.orange,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // Recent Knowledge Activity
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildRecentKnowledgeCard(context, appState),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildProgressChart(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentKnowledgeCard(
    BuildContext context,
    AppStateProvider appState,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Hoạt Động Gần Đây',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showReviewAnalyticsDialog(context),
                  icon: const Icon(Icons.analytics, size: 18),
                  label: const Text('Xem thống kê'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final knowledgeList = appState.knowledgeListItems;
                final recentList = knowledgeList.take(5).toList();

                if (recentList.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Chưa có hoạt động nào'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentList.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final knowledge = recentList[index];
                    final lastModified =
                        knowledge.lastModified ?? knowledge.createdAt;

                    return Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lightbulb,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                knowledge.topic,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cập nhật: ${DateFormat('HH:mm:ss dd/MM/yyyy').format(lastModified)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (knowledge.reminderTime != null)
                          Chip(
                            label: const Text(
                              'Có nhắc nhở',
                              style: TextStyle(fontSize: 11),
                            ),
                            backgroundColor: Colors.orange.withOpacity(0.1),
                            side: BorderSide.none,
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiến Độ Học Tập',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'T2',
                            'T3',
                            'T4',
                            'T5',
                            'T6',
                            'T7',
                            'CN'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                days[value.toInt()],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 30),
                        const FlSpot(1, 45),
                        const FlSpot(2, 40),
                        const FlSpot(3, 60),
                        const FlSpot(4, 55),
                        const FlSpot(5, 70),
                        const FlSpot(6, 85),
                      ],
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: theme.colorScheme.primary,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.2),
                            theme.colorScheme.secondary.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateKnowledgeDialog(BuildContext context) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    final result = await showDialog<Knowledge>(
      context: context,
      builder: (context) => const CreateKnowledgeDialog(),
    );

    if (result != null) {
      await appState.storage.insertKnowledge(result);
      await appState.refreshDashboard();

      if (mounted) {
        setState(() {
          _selectedKnowledge = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo tri thức mới thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Show knowledge selection dialog for dashboard filter or quiz
  Future<void> _showKnowledgeSelectionDialog({
    bool isForDashboard = false,
    bool isForQuiz = false,
  }) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final knowledgeList = appState.knowledgeListItems;

    if (knowledgeList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có tri thức nào. Vui lòng tạo tri thức trước!'),
        ),
      );
      return;
    }

    final selected = await showDialog<Knowledge?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isForQuiz ? 'Chọn tri thức để học' : 'Lọc theo tri thức'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isForDashboard)
                ListTile(
                  leading: const Icon(Icons.select_all),
                  title: const Text('Toàn bộ'),
                  onTap: () => Navigator.pop(context, null),
                ),
              ...knowledgeList.map((knowledge) => ListTile(
                    leading: const Icon(Icons.lightbulb),
                    title: Text(knowledge.topic),
                    subtitle: knowledge.description.isNotEmpty
                        ? Text(
                            knowledge.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, knowledge),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (isForDashboard) {
      setState(() {
        _selectedDashboardKnowledge = selected;
      });
    } else if (isForQuiz) {
      if (selected != null) {
        // Trigger quiz for selected knowledge
        debugPrint(
            '=== QUIZ START: User selected knowledge: ${selected.id} (${selected.topic}) ===');
        debugPrint('Current quiz state before trigger: $_currentQuiz');
        await QuizScheduler().triggerQuiz(knowledgeId: selected.id);
        debugPrint('After triggerQuiz() call, current quiz: $_currentQuiz');
        debugPrint('Current quiz knowledge: $_currentQuizKnowledge');
        debugPrint('=== QUIZ TRIGGER COMPLETED ===');
      } else {
        // Trigger random quiz
        debugPrint('=== QUIZ START: Random quiz requested ===');
        await QuizScheduler().triggerQuiz();
        debugPrint('=== QUIZ TRIGGER COMPLETED ===');
      }
    }
  }

  Future<void> _showReviewAnalyticsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const ReviewAnalyticsDialog(),
    );
  }
}
