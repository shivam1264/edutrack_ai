import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import '../assignments/assignment_audit_screen.dart';
import '../assignments/create_assignment_screen.dart';
import '../assignments/submission_list_screen.dart';
import '../quiz/create_quiz_screen.dart';
import '../quiz/teacher_quizzes_screen.dart';
import '../teacher/upload_notes_screen.dart';

class TeacherCalendarScreen extends StatefulWidget {
  final String? classId;
  
  const TeacherCalendarScreen({super.key, this.classId});

  @override
  State<TeacherCalendarScreen> createState() => _TeacherCalendarScreenState();
}

class _TeacherCalendarScreenState extends State<TeacherCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<TeacherCalendarEvent>> _events = {};
  List<TeacherCalendarEvent> _selectedEvents = [];
  bool _isLoading = true;
  String? _selectedClassId;
  List<String> _teacherClasses = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedClassId = widget.classId;
    _loadTeacherClasses();
  }

  Future<void> _loadTeacherClasses() async {
    final user = context.read<AuthProvider>().user;
    final classes = user?.assignedClasses ?? [];
    
    setState(() {
      _teacherClasses = classes;
      if (_selectedClassId == null && classes.isNotEmpty) {
        _selectedClassId = classes.first;
      }
    });
    
    if (_selectedClassId != null) {
      await _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    if (_selectedClassId == null) return;
    
    setState(() => _isLoading = true);

    final Map<DateTime, List<TeacherCalendarEvent>> events = {};

    // Load assignments for this class
    try {
      final assignments = await AssignmentService().getAssignmentsByClass(_selectedClassId!);

      for (final assignment in assignments) {
        final date = DateTime(assignment.dueDate.year, assignment.dueDate.month, assignment.dueDate.day);
        
        events.putIfAbsent(date, () => []).add(TeacherCalendarEvent(
          id: assignment.id,
          title: assignment.title,
          subject: assignment.subject,
          type: EventType.assignment,
          dateTime: assignment.dueDate,
          status: assignment.isOverdue ? 'overdue' : 'active',
          data: assignment,
          classId: _selectedClassId!,
        ));
      }
    } catch (e) {
      debugPrint('Assignment load error: $e');
    }

    // Load quizzes for this class
    try {
      final quizzes = await QuizService().getQuizzesByClass(_selectedClassId!);

      for (final quiz in quizzes) {
        final date = DateTime(quiz.startTime.year, quiz.startTime.month, quiz.startTime.day);
        
        events.putIfAbsent(date, () => []).add(TeacherCalendarEvent(
          id: quiz.id,
          title: quiz.title,
          subject: quiz.subject,
          type: EventType.quiz,
          dateTime: quiz.startTime,
          status: quiz.isActive ? 'active' : quiz.isUpcoming ? 'upcoming' : 'expired',
          data: quiz,
          classId: _selectedClassId!,
        ));
      }
    } catch (e) {
      debugPrint('Quiz load error: $e');
    }

    // Load notes for this class
    try {
      final notesSnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .where('class_id', isEqualTo: _selectedClassId!)
          .get();

      for (final doc in notesSnapshot.docs) {
        final note = NoteModel.fromMap(doc.id, doc.data());
        final date = DateTime(note.createdAt.year, note.createdAt.month, note.createdAt.day);
        
        events.putIfAbsent(date, () => []).add(TeacherCalendarEvent(
          id: note.id,
          title: note.title,
          subject: note.subject,
          type: EventType.notes,
          dateTime: note.createdAt,
          status: 'available',
          data: note,
          classId: _selectedClassId!,
        ));
      }
    } catch (e) {
      debugPrint('Notes load error: $e');
    }

    if (mounted) {
      setState(() {
        _events = events;
        _selectedEvents = _getEventsForDay(_selectedDay!);
        _isLoading = false;
      });
    }
  }

  List<TeacherCalendarEvent> _getEventsForDay(DateTime day) {
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
          // Class selector dropdown
          if (_teacherClasses.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.class_),
              tooltip: 'Select Class',
              onSelected: (classId) {
                setState(() => _selectedClassId = classId);
                _loadEvents();
              },
              itemBuilder: (context) => _teacherClasses.map((classId) {
                return PopupMenuItem(
                  value: classId,
                  child: Text('Class $classId'),
                );
              }).toList(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick add buttons
          FloatingActionButton.small(
            heroTag: 'add_note',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UploadNotesScreen(classId: _selectedClassId ?? ''),
                ),
              ).then((_) => _loadEvents());
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.note_add, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'add_quiz',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateQuizScreen(classId: _selectedClassId ?? ''),
                ),
              ).then((_) => _loadEvents());
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.quiz, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'add_assignment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateAssignmentScreen(classId: _selectedClassId ?? ''),
                ),
              ).then((_) => _loadEvents());
            },
            backgroundColor: Colors.red,
            icon: const Icon(Icons.assignment_add, color: Colors.white),
            label: const Text('Add', style: TextStyle(color: Colors.white)),
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
                  child: TableCalendar<TeacherCalendarEvent>(
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
                              const Text(
                                'No events for this date',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add assignment, quiz, or notes',
                                style: TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 14,
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

  Widget _buildEventCard(TeacherCalendarEvent event) {
    IconData icon;
    Color color;
    String subtitle;
    String actionLabel;

    switch (event.type) {
      case EventType.assignment:
        icon = Icons.assignment;
        color = Colors.red;
        subtitle = 'Due: ${DateFormat('hh:mm a').format(event.dateTime)}';
        if (event.status == 'overdue') subtitle += ' (Overdue)';
        actionLabel = 'View Submissions';
        break;
      case EventType.quiz:
        icon = Icons.quiz;
        color = Colors.blue;
        subtitle = 'Starts: ${DateFormat('hh:mm a').format(event.dateTime)}';
        if (event.status == 'active') subtitle = '🔴 LIVE NOW!';
        actionLabel = 'View Results';
        break;
      case EventType.notes:
        icon = Icons.note;
        color = Colors.green;
        subtitle = 'Added: ${DateFormat('hh:mm a').format(event.dateTime)}';
        actionLabel = 'View';
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
              ElevatedButton(
                onPressed: () => _openEventDetail(event),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.withOpacity(0.1),
                  foregroundColor: color,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEventDetail(TeacherCalendarEvent event) async {
    switch (event.type) {
      case EventType.assignment:
        final assignment = event.data as AssignmentModel;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubmissionListScreen(assignment: assignment),
          ),
        );
        break;

      case EventType.quiz:
        final quiz = event.data as QuizModel;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherQuizzesScreen(classId: event.classId),
          ),
        );
        break;

      case EventType.notes:
        final note = event.data as NoteModel;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UploadNotesScreen(classId: event.classId),
          ),
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

class TeacherCalendarEvent {
  final String id;
  final String title;
  final String subject;
  final EventType type;
  final DateTime dateTime;
  final String status;
  final dynamic data;
  final String classId;

  TeacherCalendarEvent({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.dateTime,
    required this.status,
    required this.data,
    required this.classId,
  });
}
