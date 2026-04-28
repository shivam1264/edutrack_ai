import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/assignment_model.dart';
import '../../models/quiz_model.dart';
import '../../models/note_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/assignment_service.dart';
import '../../services/quiz_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../assignments/submit_assignment_screen.dart';
import '../quiz/take_quiz_screen.dart';
import '../quiz/quiz_review_screen.dart';
import 'note_detail_screen.dart';

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};
  List<CalendarEvent> _selectedEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    final user = context.read<AuthProvider>().user;
    final classId = user?.classId ?? '';
    final studentId = user?.uid ?? '';

    // Load assignments
    final assignments = await AssignmentService().getAssignmentsByClass(classId);
    final submissions = await AssignmentService().getStudentSubmissions(studentId);
    final submissionMap = {for (var sub in submissions) sub.assignmentId: sub};

    // Load quizzes
    final quizzes = await QuizService().getQuizzesByClass(classId);
    final quizResults = await QuizService().getStudentResults(studentId);
    final resultMap = {for (var r in quizResults) r.quizId: r};

    // Load notes
    final notesSnapshot = await FirebaseFirestore.instance
        .collection('notes')
        .where('class_id', isEqualTo: classId)
        .get();
    final notes = notesSnapshot.docs
        .map((d) => NoteModel.fromMap(d.id, d.data()))
        .toList();

    final Map<DateTime, List<CalendarEvent>> events = {};

    // Add assignments
    for (final assignment in assignments) {
      final date = DateTime(assignment.dueDate.year, assignment.dueDate.month, assignment.dueDate.day);
      final sub = submissionMap[assignment.id];
      
      events.putIfAbsent(date, () => []).add(CalendarEvent(
        id: assignment.id,
        title: assignment.title,
        subject: assignment.subject,
        type: EventType.assignment,
        dateTime: assignment.dueDate,
        status: sub?.status == AssignmentStatus.graded ? 'graded' 
            : sub != null ? 'submitted' 
            : assignment.isOverdue ? 'overdue' : 'pending',
        data: assignment,
      ));
    }

    // Add quizzes
    for (final quiz in quizzes) {
      final date = DateTime(quiz.startTime.year, quiz.startTime.month, quiz.startTime.day);
      final hasTaken = resultMap.containsKey(quiz.id);
      
      events.putIfAbsent(date, () => []).add(CalendarEvent(
        id: quiz.id,
        title: quiz.title,
        subject: quiz.subject,
        type: EventType.quiz,
        dateTime: quiz.startTime,
        status: hasTaken ? 'completed' 
            : quiz.isActive ? 'active' 
            : quiz.isUpcoming ? 'upcoming' : 'expired',
        data: quiz,
      ));
    }

    // Add notes
    for (final note in notes) {
      final date = DateTime(note.createdAt.year, note.createdAt.month, note.createdAt.day);
      
      events.putIfAbsent(date, () => []).add(CalendarEvent(
        id: note.id,
        title: note.title,
        subject: note.subject,
        type: EventType.notes,
        dateTime: note.createdAt,
        status: 'available',
        data: note,
      ));
    }

    if (mounted) {
      setState(() {
        _events = events;
        _selectedEvents = _getEventsForDay(_selectedDay!);
        _isLoading = false;
      });
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Academic Calendar', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Legend
                _buildLegend(),
                
                // Calendar
                PremiumCard(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  child: TableCalendar<CalendarEvent>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 3,
                      markerSize: 8,
                      markerDecoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      weekendTextStyle: const TextStyle(color: Colors.red),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: true,
                      formatButtonDecoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      formatButtonTextStyle: const TextStyle(color: AppTheme.primary),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _selectedEvents = _getEventsForDay(selectedDay);
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return const SizedBox();
                        
                        return Positioned(
                          bottom: 1,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: events.take(3).map((e) {
                              Color color;
                              switch (e.type) {
                                case EventType.assignment:
                                  color = Colors.red;
                                  break;
                                case EventType.quiz:
                                  color = Colors.blue;
                                  break;
                                case EventType.notes:
                                  color = Colors.green;
                                  break;
                              }
                              return Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Selected Day Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Events for ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_selectedEvents.length} Events',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Selected Day Events
                Expanded(
                  child: _selectedEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 64,
                                color: AppTheme.textHint.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No events for this date',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _selectedEvents.length,
                          itemBuilder: (context, index) {
                            final event = _selectedEvents[index];
                            return _buildEventCard(event);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(color: Colors.red, label: 'Assignment'),
          const SizedBox(width: 16),
          _LegendItem(color: Colors.blue, label: 'Quiz'),
          const SizedBox(width: 16),
          _LegendItem(color: Colors.green, label: 'Notes'),
        ],
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    IconData icon;
    Color color;
    String subtitle;

    switch (event.type) {
      case EventType.assignment:
        icon = Icons.assignment;
        color = Colors.red;
        subtitle = 'Due: ${DateFormat('hh:mm a').format(event.dateTime)}';
        if (event.status == 'overdue') subtitle += ' (Overdue)';
        if (event.status == 'submitted') subtitle = 'Submitted';
        if (event.status == 'graded') subtitle = 'Graded';
        break;
      case EventType.quiz:
        icon = Icons.quiz;
        color = Colors.blue;
        subtitle = 'Starts: ${DateFormat('hh:mm a').format(event.dateTime)}';
        if (event.status == 'active') subtitle = 'LIVE NOW!';
        if (event.status == 'completed') subtitle = 'Completed';
        if (event.status == 'expired') subtitle = 'Expired';
        break;
      case EventType.notes:
        icon = Icons.note;
        color = Colors.green;
        subtitle = 'Added: ${DateFormat('hh:mm a').format(event.dateTime)}';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: () => _openEventDetail(event),
          borderRadius: BorderRadius.circular(16),
          child: Row(
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
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.subject,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEventDetail(CalendarEvent event) async {
    switch (event.type) {
      case EventType.assignment:
        final assignment = event.data as AssignmentModel;
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

      case EventType.quiz:
        final quiz = event.data as QuizModel;
        final userId = context.read<AuthProvider>().user?.uid ?? '';
        final result = await QuizService().getStudentResult(
          quizId: quiz.id,
          studentId: userId,
        );
        
        if (!mounted) return;
        
        if (result != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizReviewScreen(quiz: quiz, result: result),
            ),
          );
        } else if (quiz.isActive) {
          final taken = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TakeQuizScreen(quiz: quiz)),
          );
          if (taken == true) _loadEvents();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(quiz.isUpcoming ? 'Quiz has not started yet.' : 'Quiz has ended.'),
              backgroundColor: quiz.isUpcoming ? AppTheme.accent : AppTheme.danger,
            ),
          );
        }
        break;

      case EventType.notes:
        final note = event.data as NoteModel;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
        );
        break;
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

enum EventType { assignment, quiz, notes }

class CalendarEvent {
  final String id;
  final String title;
  final String subject;
  final EventType type;
  final DateTime dateTime;
  final String status;
  final dynamic data;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.dateTime,
    required this.status,
    required this.data,
  });
}
