import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:camp_x/services/google_calendar_service.dart';
import 'package:provider/provider.dart';
import 'package:camp_x/utils/user_provider.dart';
import 'package:camp_x/services/instructor_service.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Google Calendar integration
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  final InstructorService _instructorService = InstructorService();
  bool _isLinked = false;
  String? _linkedEmail;
  bool _isSyncing = false;
  String? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _checkLinkStatus();
  }

  Future<void> _checkLinkStatus() async {
    final isLinked = await _calendarService.isLinked();
    final lastSync = await _calendarService.getLastSyncTime();
    setState(() {
      _isLinked = isLinked;
      _linkedEmail = _calendarService.getLinkedEmail();
      _lastSyncTime = lastSync;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DefaultTabController(
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
                        _buildGoogleCalendarCard(theme),
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
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget? _buildFab(BuildContext context) {
    final Map<String, dynamic>? user = context.watch<UserProvider>().user;
    if (user == null || user['role'] != 'instructor') return null;

    return FloatingActionButton.extended(
      onPressed: () => _showAddOptions(context),
      label: const Text("Add New"),
      icon: const Icon(Icons.add),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text("Add Event"),
            onTap: () {
              Navigator.pop(context);
              _showAddEventDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text("Add Exam"),
            onTap: () {
              Navigator.pop(context);
              _showAddExamDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Campus Event"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
            const SizedBox(height: 16),
            ListTile(
              title: Text("Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2027),
                );
                if (date != null) selectedDate = date;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              final result = await _instructorService.addEvent(
                title: titleController.text.trim(),
                description: descController.text.trim(),
                date: selectedDate,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showAddExamDialog(BuildContext context) {
    final nameController = TextEditingController();
    final marksController = TextEditingController(text: "100");
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Exam Date"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Exam Name")),
            TextField(controller: marksController, decoration: const InputDecoration(labelText: "Total Marks"), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            ListTile(
              title: Text("Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2027),
                );
                if (date != null) selectedDate = date;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final result = await _instructorService.addExam(
                classId: 'BTECH_3',
                name: nameController.text.trim(),
                date: selectedDate,
                totalMarks: int.tryParse(marksController.text) ?? 100,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCalendar(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(context.read<UserProvider>().user?['uid'])
          .collection('attendance')
          .snapshots(),
      builder: (context, snapshot) {
        Map<DateTime, String> attendanceData = {};
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final dateStr = doc.id; // YYYY-MM-DD
            try {
              final date = DateTime.parse(dateStr);
              // Store simpler status: P, A, L
              // Logic: If ANY period is Absent -> A. If no Absent but ANY Late -> L. Else P.
              final data = doc.data() as Map<String, dynamic>;
              String status = 'P'; // Default to Present
              
              bool hasAbsent = false;
              bool hasLate = false;
              
              for (var value in data.values) {
                if (value == 'A') {
                  hasAbsent = true;
                  break; // Found absent, no need to check further
                } else if (value == 'L') {
                  hasLate = true;
                }
              }
              
              if (hasAbsent) {
                status = 'A';
              } else if (hasLate) {
                status = 'L';
              }
              // else status remains 'P'
              
              attendanceData[DateTime.utc(date.year, date.month, date.day)] = status;
            } catch (e) {
              // ignore date parse error
            }
          }
        }

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
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              final utcDate = DateTime.utc(date.year, date.month, date.day);
              if (attendanceData.containsKey(utcDate)) {
                final status = attendanceData[utcDate];
                Color dotColor = Colors.green;
                if (status == 'A') {
                  dotColor = Colors.red;
                } else if (status == 'L') {
                  dotColor = Colors.orange;
                }

                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }
              return null;
            },
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.3), shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
            markerDecoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle),
          ),
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        );
      },
    );
  }

  Widget _buildScheduleList(ThemeData theme) {
    // Show table only for students
    final user = context.watch<UserProvider>().user;
    if (user == null) return const SizedBox();
    
    if (user['role'] == 'student') {
      return Column(
        children: [
          _buildSubjectAttendanceTable(theme, user['uid']),
          const Divider(),
          _buildDailyScheduleAndDetails(theme),
        ],
      );
    }

    return _buildDailyScheduleAndDetails(theme);
  }

  Widget _buildDailyScheduleAndDetails(ThemeData theme) {
    final dayName = DateFormat('EEEE').format(_selectedDay ?? DateTime.now());
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Schedule for $dayName", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_selectedDay != null)
             FutureBuilder<DocumentSnapshot>(
               future: FirebaseFirestore.instance.collection('users').doc(context.read<UserProvider>().user?['uid']).collection('attendance').doc(DateFormat('yyyy-MM-dd').format(_selectedDay!)).get(),
               builder: (context, snapshot) {
                 if (snapshot.hasData && snapshot.data!.exists) {
                   final data = snapshot.data!.data() as Map<String, dynamic>;
                   final periods = data.keys.toList()..sort();
                   return Card(
                     color: theme.colorScheme.surface,
                     child: ExpansionTile(
                        initiallyExpanded: true,
                        title: const Text("Attendance Details"),
                        children: periods.map((period) {
                           final status = data[period];
                           Color dotColor = Colors.green;
                           String statusText = "Present";
                           if (status == 'A') { dotColor = Colors.red; statusText = "Absent"; }
                           else if (status == 'L') { dotColor = Colors.orange; statusText = "Late"; }
                           
                           return ListTile(
                             leading: Icon(Icons.circle, color: dotColor, size: 12),
                             title: Text("Period $period"),
                             trailing: Text(statusText, style: TextStyle(color: dotColor, fontWeight: FontWeight.bold)),
                           );
                        }).toList(),
                     ),
                   );
                 }
                 return const SizedBox.shrink();
               },
             ),
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

  Widget _buildSubjectAttendanceTable(ThemeData theme, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('attendance').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("No attendance records found.")));
        
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('classes').doc('BTECH_3').collection('timetable').get(),
          builder: (context, timetableSnap) {
             if (!timetableSnap.hasData) return const Center(child: CircularProgressIndicator());
             
             final timetableDocs = timetableSnap.data!.docs;
             final Map<String, Map<String, String>> dayToSubjects = {};
             
             for(var doc in timetableDocs) {
               // Normalize day name to Title Case just in case
               dayToSubjects[doc.id] = Map<String, String>.from(doc.data() as Map);
             }

             // Calculate stats
             final Map<String, int> totalPeriods = {};
             final Map<String, int> attendedPeriods = {};

             for (var doc in snapshot.data!.docs) {
               final dateStr = doc.id;
               final date = DateTime.tryParse(dateStr);
               if (date == null) continue;

               final dayName = DateFormat('EEEE').format(date);
               final subjectsForDay = dayToSubjects[dayName];
               
               if (subjectsForDay != null) {
                 final attendanceData = doc.data() as Map<String, dynamic>;
                 
                 attendanceData.forEach((periodKey, status) {
                    // Normalize keys: 'p1' vs '1'
                    // Timetable uses 'p1', 'p2'. Attendance uses 'p1', 'p2'.
                    // If mismatch, try to fix.
                    String lookupKey = periodKey;
                    if (!periodKey.startsWith('p')) {
                      lookupKey = 'p$periodKey'; 
                    }

                    final subject = subjectsForDay[lookupKey];
                    if (subject != null) {
                      totalPeriods[subject] = (totalPeriods[subject] ?? 0) + 1;
                      
                      // Check for Present (P) or Late (L)
                      // Normalize status to uppercase just in case
                      final s = status.toString().toUpperCase();
                      if (s == 'P' || s == 'L') { 
                        attendedPeriods[subject] = (attendedPeriods[subject] ?? 0) + 1;
                      }
                    }
                 });
               }
             }
             
             if (totalPeriods.isEmpty) {
                 return const SizedBox(
                     height: 100, 
                     child: Center(
                         child: Text("No analyzable class data found (Check Timetable Configuration).")
                     )
                 );
             }

             return Card(
               margin: const EdgeInsets.all(16),
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text("Subject Attendance", style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 10),
                     SingleChildScrollView(
                       scrollDirection: Axis.horizontal,
                       child: DataTable(
                         columns: const [
                           DataColumn(label: Text("Subject")),
                           DataColumn(label: Text("Total")),
                           DataColumn(label: Text("Attended")),
                           DataColumn(label: Text("%")),
                         ],
                         rows: totalPeriods.entries.map((e) {
                           final subject = e.key;
                           final total = e.value;
                           final attended = attendedPeriods[subject] ?? 0;
                           final pct = total == 0 ? 0.0 : (attended / total * 100);
                           return DataRow(cells: [
                             DataCell(Text(subject, style: const TextStyle(fontWeight: FontWeight.bold))),
                             DataCell(Text(total.toString())),
                             DataCell(Text(attended.toString())),
                             DataCell(Text("${pct.toStringAsFixed(1)}%", style: TextStyle(
                               fontWeight: FontWeight.bold,
                               color: pct < 75 ? Colors.red : Colors.green
                             ))),
                           ]);
                         }).toList(),
                       ),
                     ),
                   ],
                 ),
               ),
             );
          }
        );
      },
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
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final examName = doc.id;
            final date = (data['date'] as Timestamp).toDate();
            final user = context.watch<UserProvider>().user;
            final isInstructor = user?['role'] == 'instructor';

            return Card(
              child: ListTile(
                leading: const Icon(Icons.assignment),
                title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat('MMM d, y').format(date)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${data['totalMarks']} M", style: GoogleFonts.orbitron()),
                    if (isInstructor) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                        onPressed: () => _showEditExamDialog(context, examName, data),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                        onPressed: () => _confirmDeleteExam(context, examName),
                      ),
                    ],
                  ],
                ),
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
            final doc = docs[index];
            final eventId = doc.id;
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final user = context.watch<UserProvider>().user;
            final isInstructor = user?['role'] == 'instructor';

            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(DateFormat('d').format(date))),
                title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['description'] ?? ''),
                trailing: isInstructor
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showEditEventDialog(context, eventId, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _confirmDeleteEvent(context, eventId),
                          ),
                        ],
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  // Google Calendar Link Status Card
  Widget _buildGoogleCalendarCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Google Calendar',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLinked) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Linked to $_linkedEmail',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (_lastSyncTime != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last synced: ${_formatSyncTime(_lastSyncTime!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _syncAllToCalendar,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _isSyncing ? null : _unlinkGoogleCalendar,
                    child: const Text('Unlink'),
                  ),
                ],
              ),
            ] else ...[
              const Text(
                'Link your Google Calendar to automatically sync exams and events',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _linkGoogleCalendar,
                  icon: const Icon(Icons.link),
                  label: const Text('Link Google Calendar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatSyncTime(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} hr ago';
      } else {
        return DateFormat('MMM d, h:mm a').format(dateTime);
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _linkGoogleCalendar() async {
    setState(() => _isSyncing = true);

    final result = await _calendarService.linkGoogleCalendar();

    setState(() => _isSyncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        await _checkLinkStatus();
        // Auto-sync after linking
        _syncAllToCalendar();
      }
    }
  }

  Future<void> _unlinkGoogleCalendar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Google Calendar?'),
        content: const Text(
          'This will disconnect your Google Calendar. Events will remain in your calendar but won\'t sync anymore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _calendarService.unlinkGoogleCalendar();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );

        if (result['success']) {
          await _checkLinkStatus();
        }
      }
    }
  }

  Future<void> _syncAllToCalendar() async {
    setState(() => _isSyncing = true);

    try {
      // Fetch exams
      final examsSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc('BTECH_3')
          .collection('exams')
          .orderBy('date')
          .get();

      final exams = examsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['name'],
          'date': (data['date'] as Timestamp).toDate(),
          'totalMarks': data['totalMarks'] ?? data['total'] ?? 0,
        };
      }).toList();

      // Fetch events
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .orderBy('date')
          .get();

      final events = eventsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'title': data['title'],
          'date': (data['date'] as Timestamp).toDate(),
          'description': data['description'] ?? '',
        };
      }).toList();

      // Sync exams
      final examResult = await _calendarService.syncExamsToCalendar(exams);
      
      // Sync events
      final eventResult = await _calendarService.syncEventsToCalendar(events);

      setState(() => _isSyncing = false);

      if (mounted) {
        final totalSynced = (examResult['count'] ?? 0) + (eventResult['count'] ?? 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              totalSynced > 0
                  ? 'Synced $totalSynced item(s) to Google Calendar'
                  : 'All items already synced',
            ),
            backgroundColor: Colors.green,
          ),
        );

        await _checkLinkStatus();
      }
    } catch (e) {
      setState(() => _isSyncing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditEventDialog(BuildContext context, String eventId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title']);
    final descController = TextEditingController(text: data['description']);
    DateTime selectedDate = (data['date'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Event"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
            const SizedBox(height: 16),
            ListTile(
              title: Text("Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2025),
                  lastDate: DateTime(2027),
                );
                if (date != null) selectedDate = date;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              final result = await _instructorService.updateEvent(
                eventId: eventId,
                title: titleController.text.trim(),
                description: descController.text.trim(),
                date: selectedDate,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEvent(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Event?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final result = await _instructorService.deleteEvent(eventId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditExamDialog(BuildContext context, String oldName, Map<String, dynamic> currentData) {
    final nameController = TextEditingController(text: currentData['name']);
    final marksController = TextEditingController(text: currentData['totalMarks'].toString());
    DateTime selectedDate = (currentData['date'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Exam"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Exam Name")),
              TextField(controller: marksController, decoration: const InputDecoration(labelText: "Total Marks"), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              ListTile(
                title: Text("Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2027),
                  );
                  if (date != null) setDialogState(() => selectedDate = date);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                final result = await _instructorService.updateExam(
                  classId: 'BTECH_3',
                  oldName: oldName,
                  newName: nameController.text.trim(),
                  date: selectedDate,
                  totalMarks: int.tryParse(marksController.text) ?? 100,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
                }
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteExam(BuildContext context, String examName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Exam?"),
        content: Text("Are you sure you want to delete '$examName'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final result = await _instructorService.deleteExam(classId: 'BTECH_3', examName: examName);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
