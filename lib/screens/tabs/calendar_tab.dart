import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.primaryColor,
            tabs: const [
              Tab(text: "CALENDAR"),
              Tab(text: "EXAMS"),
              Tab(text: "EVENTS"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 1. Monthly Calendar Grid
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTableCalendar(theme),
                      const Divider(),
                      _buildScheduleList(theme),
                    ],
                  ),
                ),

                // 2. Exams View
                _buildExamsList(theme),

                // 3. Events View
                _buildEventsList(theme),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTableCalendar(ThemeData theme) {
    return TableCalendar(
      firstDay: DateTime.utc(2025, 1, 1),
      lastDay: DateTime.utc(2026, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.3), shape: BoxShape.circle),
        selectedDecoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
        markerDecoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle),
      ),
      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
    );
  }

  Widget _buildScheduleList(ThemeData theme) {
    final dayName = DateFormat('EEEE').format(_selectedDay ?? DateTime.now());
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Schedule for $dayName", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('classes').doc('BTECH_3').collection('timetable').doc(dayName).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              if (!snapshot.data!.exists) return const Text("No classes scheduled.");
              
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final keys = data.keys.toList()..sort();

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  final period = keys[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(period.replaceAll('p', ''))),
                      title: Text(data[period]),
                      subtitle: Text("Period $period"),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExamsList(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').doc('BTECH_3').collection('exams').orderBy('date').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            return Card(
              child: ListTile(
                leading: const Icon(Icons.assignment),
                title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat('MMM d, y').format(date)),
                trailing: Text("${data['totalMarks']} M", style: GoogleFonts.orbitron()),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventsList(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').orderBy('date').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(DateFormat('d').format(date))),
                title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['description'] ?? ''),
              ),
            );
          },
        );
      },
    );
  }
}
