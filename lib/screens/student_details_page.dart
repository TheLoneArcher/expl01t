import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:camp_x/screens/tabs/marks_tab.dart'; 
import 'package:camp_x/services/instructor_service.dart';

class StudentDetailsPage extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final String studentId;

  const StudentDetailsPage({super.key, required this.studentData, required this.studentId});

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentData['name'] ?? 'Student Details', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "MARKS"),
            Tab(text: "ATTENDANCE"),
            Tab(text: "HOMEWORK"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary Stats Row (Same as HomeTab but for this student)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<double>(
              stream: InstructorService().getAttendancePercentage(widget.studentId),
              builder: (context, attSnapshot) {
                return StreamBuilder<double>(
                  stream: InstructorService().getMarksAverage(widget.studentId),
                  builder: (context, marksSnapshot) {
                    final attPerc = attSnapshot.data ?? 0.0;
                    final marksPerc = marksSnapshot.data ?? 0.0;

                    return Row(
                      children: [
                        Expanded(child: _buildSmallStatCard("Attendance", "${attPerc.toStringAsFixed(1)}%", Icons.check_circle_outline, Colors.greenAccent)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSmallStatCard("Avg Perf", "${marksPerc.toStringAsFixed(1)}%", Icons.bar_chart, Colors.amberAccent)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMarksView(),
                _buildAttendanceView(),
                _buildHomeworkView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarksView() {
    // We can reuse MarksTab logic but specifically for this studentId
    // Since MarksTab takes an optional studentId, we can just instantiate it!
    // However, MarksTab is designed as a standalone tab. Let's check if we can reuse it.
    // Yes, MarksTab has `final String? studentId;`.
    return MarksTab(studentId: widget.studentId);
  }

  Widget _buildHomeworkView() {
    final classId = widget.studentData['classId'] ?? 'BTECH_3';
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').doc(classId).collection('homework').orderBy('dueDate', descending: true).snapshots(),
      builder: (context, hwSnapshot) {
        if (!hwSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        final homeworkDocs = hwSnapshot.data!.docs;
        
        if (homeworkDocs.isEmpty) return const Center(child: Text("No homework assigned."));

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.studentId).collection('homework_status').snapshots(),
          builder: (context, statusSnapshot) {
            // Map of homework_id -> isCompleted
            final Map<String, bool> completionMap = {};
            if (statusSnapshot.hasData) {
              for (var doc in statusSnapshot.data!.docs) {
                completionMap[doc.id] = (doc.data() as Map<String, dynamic>)['isCompleted'] ?? false;
              }
            }

            // Sort: Pending first
            final sortedDocs = List<QueryDocumentSnapshot>.from(homeworkDocs);
            sortedDocs.sort((a, b) {
                final isDoneA = completionMap[a.id] ?? false;
                final isDoneB = completionMap[b.id] ?? false;
                if (isDoneA == isDoneB) return b['dueDate'].compareTo(a['dueDate']);
                return isDoneA ? 1 : -1;
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDocs.length,
              itemBuilder: (context, index) {
                final hwDoc = sortedDocs[index];
                final hw = hwDoc.data() as Map<String, dynamic>;
                final bool isCompleted = completionMap[hwDoc.id] ?? false;

                return Opacity(
                  opacity: isCompleted ? 0.6 : 1.0,
                  child: Card(
                    elevation: isCompleted ? 0 : 2,
                    color: isCompleted ? Theme.of(context).cardColor.withValues(alpha: 0.5) : null,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        isCompleted ? Icons.check_circle : Icons.pending_actions,
                        color: isCompleted ? Colors.green : Colors.orange,
                      ),
                      title: Text(
                        hw['subject'] ?? 'Unknown Subject', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        )
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hw['description'] ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            "Due: ${(hw['dueDate'] as Timestamp).toDate().toString().split(' ')[0]}",
                            style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(isCompleted ? "Done" : "To Do"),
                        backgroundColor: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        labelStyle: TextStyle(color: isCompleted ? Colors.green : Colors.orange, fontSize: 10),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        );
      },
    );
  }

  Widget _buildAttendanceView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentId)
          .collection('attendance')
          .orderBy(FieldPath.documentId, descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Error loading attendance: ${snapshot.error}"),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No attendance records."));
        }
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final dateStr = doc.id;
            final data = doc.data() as Map<String, dynamic>;
            
            // Calculate a status summary
            int present = 0, absent = 0, late = 0;
            for (var v in data.values) {
              if (v == 'P') {
                present++;
              } else if (v == 'A') {
                absent++;
              } else if (v == 'L') {
                late++;
              }
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("P: $present | A: $absent | L: $late"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditAttendanceDialog(context, dateStr, data),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditAttendanceDialog(BuildContext context, String dateStr, Map<String, dynamic> currentData) {
    final Map<String, String> periodStatus = Map<String, String>.from({
      'p1': 'P', 'p2': 'P', 'p3': 'P', 'p4': 'P',
      'p5': 'P', 'p6': 'P', 'p7': 'P', 'p8': 'P',
    });
    
    // Fill with current data
    currentData.forEach((key, value) {
      if (periodStatus.containsKey(key)) {
        periodStatus[key] = value as String;
      }
    });

    final DateTime date = DateTime.parse(dateStr);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Edit Attendance: $dateStr"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(8, (index) {
                final period = 'p${index + 1}';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Period ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ToggleButtons(
                        isSelected: [
                          periodStatus[period] == 'P',
                          periodStatus[period] == 'A',
                          periodStatus[period] == 'L',
                        ],
                        onPressed: (idx) {
                          setDialogState(() {
                            periodStatus[period] = idx == 0 ? 'P' : (idx == 1 ? 'A' : 'L');
                          });
                        },
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 30),
                        borderRadius: BorderRadius.circular(8),
                        children: const [
                          Text("P"),
                          Text("A"),
                          Text("L"),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final result = await InstructorService().updateAttendance(
                  uid: widget.studentId,
                  date: date,
                  periodStatus: periodStatus,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
