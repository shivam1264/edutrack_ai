import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/timetable_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/timetable_service.dart';
import '../../utils/app_theme.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  late String _selectedDay;

  @override
  void initState() {
    super.initState();
    // Default to today or Monday
    int weekday = DateTime.now().weekday;
    if (weekday >= 1 && weekday <= 6) {
      _selectedDay = _days[weekday - 1];
    } else {
      _selectedDay = 'Monday'; // Default for Sunday
    }
  }

  @override
  Widget build(BuildContext context) {
    final classId = context.read<AuthProvider>().user?.classId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Timetable'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildDaysSelector(),
          Expanded(
            child: FutureBuilder<TimetableModel?>(
              future: TimetableService().getTimetable(classId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('No timetable found.', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)));
                }

                final timetable = snapshot.data!;
                final periods = timetable.weeklySchedule[_selectedDay] ?? [];

                if (periods.isEmpty) {
                  return const Center(child: Text('No classes scheduled.', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)));
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    children: periods.map((period) {
                      return _TimetableItem(
                        time: period.startTimeStr,
                        subject: period.subject,
                        room: period.room ?? 'TBA',
                        icon: _getIconForSubject(period.subject),
                        color: _getColorForSubject(period.subject),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _days.map((day) {
          // Mock date calculation for UI
          final offset = _days.indexOf(day) - _days.indexOf(_selectedDay);
          final dateStr = DateFormat('dd').format(DateTime.now().add(Duration(days: offset)));

          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: _DayItem(
              day: day.substring(0, 3),
              date: dateStr,
              isSelected: _selectedDay == day,
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math': return Icons.calculate;
      case 'science': return Icons.science;
      case 'english': return Icons.book;
      case 'history': return Icons.history_edu;
      case 'computer': return Icons.computer;
      default: return Icons.library_books;
    }
  }

  Color _getColorForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math': return Colors.blue;
      case 'science': return Colors.green;
      case 'english': return Colors.orange;
      case 'history': return Colors.purple;
      case 'computer': return Colors.teal;
      default: return AppTheme.primary;
    }
  }
}

class _DayItem extends StatelessWidget {
  final String day;
  final String date;
  final bool isSelected;

  const _DayItem({required this.day, required this.date, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimetableItem extends StatelessWidget {
  final String time;
  final String subject;
  final String room;
  final IconData icon;
  final Color color;

  const _TimetableItem({
    required this.time,
    required this.subject,
    required this.room,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              time,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(room, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
