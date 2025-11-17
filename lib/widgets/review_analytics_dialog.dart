import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/knowledge.dart';
import '../models/quiz_history.dart';

class ReviewAnalyticsDialog extends StatefulWidget {
  const ReviewAnalyticsDialog({super.key});

  @override
  State<ReviewAnalyticsDialog> createState() => _ReviewAnalyticsDialogState();
}

class _ReviewAnalyticsDialogState extends State<ReviewAnalyticsDialog> {
  List<Knowledge> _allKnowledge = [];
  List<QuizHistory> _quizHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final storage = appState.storage;

    try {
      final knowledge = await storage.getAllKnowledge();
      final history = await storage.getRecentHistory(limit: 1000);

      setState(() {
        _allKnowledge = knowledge;
        _quizHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Dialog(
        backgroundColor: const Color(0xFFF0F8FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 600,
          height: 400,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Calculate statistics
    final totalQuestions = _calculateTotalQuestions(_allKnowledge);
    final answeredCount = _quizHistory.length;
    final accuracy = answeredCount > 0
        ? (_calculateCorrectCount(_quizHistory) / answeredCount * 100)
        : 0.0;
    final masteredItems = _getMasteredItems(_allKnowledge, _quizHistory);

    return Dialog(
      backgroundColor: const Color(0xFFF0F8FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF87CEEB).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Color(0xFF87CEEB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '📊 Thống Kê Học Tập',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.quiz,
                    iconColor: const Color(0xFF87CEEB),
                    label: 'Tổng Câu Hỏi',
                    value: totalQuestions.toString(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                    label: 'Đã Trả Lời',
                    value: answeredCount.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.percent,
                    iconColor: Colors.orange,
                    label: 'Độ Chính Xác',
                    value: '${accuracy.toStringAsFixed(1)}%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    label: 'Đã Thành Thạo',
                    value: masteredItems.length.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mastered Items List
            const Text(
              '⭐ Danh Sách Đã Thành Thạo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (masteredItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Chưa có nội dung nào được đánh dấu thành thạo',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: masteredItems.length,
                  itemBuilder: (context, index) {
                    final item = masteredItems[index];
                    return _buildMasteredItemCard(item);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasteredItemCard(Knowledge item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.topic,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.star,
            color: Colors.amber,
            size: 20,
          ),
        ],
      ),
    );
  }

  int _calculateTotalQuestions(List<Knowledge> knowledgeList) {
    int total = 0;
    for (var knowledge in knowledgeList) {
      // Each flashcard in knowledge content is a question
      if (knowledge.content.isNotEmpty) {
        final lines = knowledge.content.split('\n');
        for (var line in lines) {
          if (line.contains('=')) {
            total++;
          }
        }
      }
    }
    return total;
  }

  int _calculateCorrectCount(List<QuizHistory> historyList) {
    return historyList.where((history) => history.wasCorrect).length;
  }

  List<Knowledge> _getMasteredItems(
    List<Knowledge> knowledgeList,
    List<QuizHistory> historyList,
  ) {
    // Consider an item mastered if it has been answered correctly multiple times
    final correctAnswers = <int, int>{};

    for (var history in historyList) {
      if (history.wasCorrect) {
        correctAnswers[history.itemId] =
            (correctAnswers[history.itemId] ?? 0) + 1;
      }
    }

    // Filter items with at least 3 correct answers
    return knowledgeList.where((item) {
      final correctCount = correctAnswers[item.id ?? -1] ?? 0;
      return correctCount >= 3;
    }).toList();
  }
}
