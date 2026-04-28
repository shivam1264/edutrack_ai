import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/assignment_model.dart';
import '../../models/quiz_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/assignment_service.dart';
import '../../services/quiz_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../assignments/submit_assignment_screen.dart';
import '../quiz/take_quiz_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = context.read<AuthProvider>().user;
    final classId = user?.classId ?? '';
    final studentId = user?.uid ?? '';

    List<NotificationItem> notifications = [];

    // Load overdue assignments
    try {
      final assignments = await AssignmentService().getAssignmentsByClass(classId);
      final submissions = await AssignmentService().getStudentSubmissions(studentId);
      final submissionMap = {for (var sub in submissions) sub.assignmentId: sub};

      for (final assignment in assignments) {
        // Overdue assignments
        if (assignment.isOverdue && submissionMap[assignment.id] == null) {
          final daysOverdue = DateTime.now().difference(assignment.dueDate).inDays;
          notifications.add(NotificationItem(
            id: 'overdue_${assignment.id}',
            title: 'Assignment Overdue',
            message: '"${assignment.title}" was due ${daysOverdue == 0 ? 'today' : '$daysOverdue day${daysOverdue > 1 ? 's' : ''} ago'}',
            subject: assignment.subject,
            type: NotificationType.urgent,
            timestamp: assignment.dueDate,
            data: assignment,
            dataType: DataType.assignment,
          ));
        }
        // Due today/tomorrow
        else if (!assignment.isOverdue && submissionMap[assignment.id] == null) {
          final daysRemaining = assignment.dueDate.difference(DateTime.now()).inDays;
          if (daysRemaining <= 1) {
            notifications.add(NotificationItem(
              id: 'due_${assignment.id}',
              title: daysRemaining == 0 ? 'Assignment Due Today' : 'Assignment Due Tomorrow',
              message: '"${assignment.title}" in ${assignment.subject}',
              subject: assignment.subject,
              type: NotificationType.warning,
              timestamp: assignment.dueDate,
              data: assignment,
              dataType: DataType.assignment,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Assignment notifications error: $e');
    }

    // Load upcoming quizzes
    try {
      final quizzes = await QuizService().getQuizzesByClass(classId);
      final quizResults = await QuizService().getStudentResults(studentId);
      final resultMap = {for (var r in quizResults) r.quizId: r};

      for (final quiz in quizzes) {
        if (!resultMap.containsKey(quiz.id) && quiz.isUpcoming) {
          final hoursUntil = quiz.startTime.difference(DateTime.now()).inHours;
          if (hoursUntil <= 24) {
            notifications.add(NotificationItem(
              id: 'quiz_${quiz.id}',
              title: 'Quiz Starting Soon',
              message: '"${quiz.title}" starts in ${hoursUntil < 1 ? 'less than an hour' : '$hoursUntil hours'}',
              subject: quiz.subject,
              type: NotificationType.info,
              timestamp: quiz.startTime,
              data: quiz,
              dataType: DataType.quiz,
            ));
          }
        }
        // Live quizzes
        else if (!resultMap.containsKey(quiz.id) && quiz.isActive) {
          notifications.add(NotificationItem(
            id: 'live_${quiz.id}',
            title: '🔴 LIVE QUIZ!',
            message: '"${quiz.title}" is happening now!',
            subject: quiz.subject,
            type: NotificationType.urgent,
            timestamp: quiz.startTime,
            data: quiz,
            dataType: DataType.quiz,
          ));
        }
      }
    } catch (e) {
      debugPrint('Quiz notifications error: $e');
    }

    // Sort by timestamp (most recent/urgent first)
    notifications.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.length;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() => _notifications.clear());
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 80,
                        color: AppTheme.textHint.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'re all caught up!',
                        style: TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.urgent:
        icon = Icons.warning_rounded;
        color = Colors.red;
        break;
      case NotificationType.warning:
        icon = Icons.access_time_filled;
        color = Colors.orange;
        break;
      case NotificationType.info:
        icon = Icons.info;
        color = Colors.blue;
        break;
    }

    switch (notification.dataType) {
      case DataType.assignment:
        icon = Icons.assignment;
        break;
      case DataType.quiz:
        icon = Icons.quiz;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _markAsRead(notification.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PremiumCard(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () => _handleNotificationTap(notification),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, hh:mm a').format(notification.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(NotificationItem notification) async {
    switch (notification.dataType) {
      case DataType.assignment:
        final assignment = notification.data as AssignmentModel;
        final submissions = await AssignmentService().getStudentSubmissions(
          context.read<AuthProvider>().user?.uid ?? '',
        );
        final submission = submissions.firstWhere(
          (s) => s.assignmentId == assignment.id,
          orElse: () => SubmissionModel(
            id: '',
            assignmentId: '',
            studentId: '',
            submittedAt: DateTime.now(),
            status: AssignmentStatus.pending,
          ),
        );
        
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubmitAssignmentScreen(
              assignment: assignment,
              existingSubmission: submission.id.isNotEmpty ? submission : null,
            ),
          ),
        );
        break;

      case DataType.quiz:
        final quiz = notification.data as QuizModel;
        if (quiz.isActive) {
          final taken = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TakeQuizScreen(quiz: quiz)),
          );
          if (taken == true) {
            _markAsRead(notification.id);
            _loadNotifications();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(quiz.isUpcoming ? 'Quiz has not started yet.' : 'Quiz has ended.'),
              backgroundColor: quiz.isUpcoming ? AppTheme.accent : AppTheme.danger,
            ),
          );
        }
        break;
    }
  }
}

enum NotificationType { urgent, warning, info }
enum DataType { assignment, quiz }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String subject;
  final NotificationType type;
  final DateTime timestamp;
  final dynamic data;
  final DataType dataType;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.subject,
    required this.type,
    required this.timestamp,
    required this.data,
    required this.dataType,
  });
}

class QuizReviewScreen extends StatelessWidget {
  final dynamic quiz;
  final dynamic result;
  const QuizReviewScreen({super.key, required this.quiz, required this.result});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(quiz.title)));
}
