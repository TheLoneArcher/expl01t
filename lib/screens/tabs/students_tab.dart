import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:camp_x/services/instructor_service.dart';
import 'package:intl/intl.dart';
import 'package:camp_x/screens/student_details_page.dart';

class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final InstructorService _instructorService = InstructorService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No students found."));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBulkAssignMarksDialog(context, docs),
                      icon: const Icon(Icons.grade),
                      label: const Text("Bulk Marks"),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBulkMarkAttendanceDialog(context, docs),
                      icon: const Icon(Icons.event_available),
                      label: const Text("Bulk Attendance"),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final String studentId = data['uid'] as String;
                  final String studentName = data['name'] as String;
                  final String classId = (data['classId'] ?? 'BTECH_3') as String;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        child: Text(
                          studentId.substring(studentId.length - 2), // Last 2 digits
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        studentId, // Show roll number as title
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text("Class: $classId"),
                      children: [
                        // Student Details Section
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              ListTile(
                                leading: const Icon(Icons.person),
                                title: const Text("Name"),
                                subtitle: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                dense: true,
                              ),
                              const Divider(),
                              
                              // Marks Summary
                              StreamBuilder<double>(
                                stream: _instructorService.getMarksAverage(studentId),
                                builder: (context, marksSnapshot) {
                                  final avg = marksSnapshot.data ?? 0.0;
                                  return ListTile(
                                    leading: const Icon(Icons.grade),
                                    title: const Text("Performance"),
                                    subtitle: Text(
                                      avg == 0 
                                        ? "No marks recorded" 
                                        : "${avg.toStringAsFixed(1)}% Average",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    dense: true,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StudentDetailsPage(
                                            studentData: data,
                                            studentId: studentId,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              const Divider(),
                              
                              // Attendance Summary
                              StreamBuilder<double>(
                                stream: _instructorService.getAttendancePercentage(studentId),
                                builder: (context, attSnapshot) {
                                  final percentage = attSnapshot.data ?? 0.0;
                                  return ListTile(
                                    leading: const Icon(Icons.event_available),
                                    title: const Text("Attendance"),
                                    subtitle: Text(
                                      percentage == 0
                                        ? "No attendance recorded"
                                        : "${percentage.toStringAsFixed(1)}% overall",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: percentage < 75 ? Colors.red : Colors.green,
                                      ),
                                    ),
                                    dense: true,
                                  );
                                },
                              ),
                              const Divider(),
                              
                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _showAssignMarksDialog(context, studentId, studentName, classId),
                                    icon: const Icon(Icons.grade, size: 16),
                                    label: const Text("Marks"),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _showMarkAttendanceDialog(context, studentId, studentName),
                                    icon: const Icon(Icons.event_available, size: 16),
                                    label: const Text("Attendance"),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAssignMarksDialog(BuildContext context, String uid, String name, String classId) async {
    // Fetch exams for selection
    final examsSnapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('exams')
        .get();
    
    final exams = examsSnapshot.docs.map((doc) => doc.data()).toList();
    if (exams.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No exams found for this class.")));
      return;
    }

    String? selectedExam = exams[0]['name'];
    final Map<String, int> marks = {};
    
    // Fetch subjects
    final subjectsSnapshot = await FirebaseFirestore.instance.collection('subjects').get();
    final subjects = subjectsSnapshot.docs.map((doc) => doc.data()['name'] as String).toList();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Assign Marks to $name"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedExam,
                  decoration: const InputDecoration(labelText: 'Select Exam'),
                  items: exams.map((e) => DropdownMenuItem(
                    value: e['name'] as String,
                    child: Text(e['name'] as String),
                  )).toList(),
                  onChanged: (val) async {
                    selectedExam = val;
                    if (val != null) {
                      final doc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('marks')
                          .doc(val)
                          .get();
                      if (doc.exists) {
                        final data = doc.data() as Map<String, dynamic>;
                        setDialogState(() {
                          for (var sub in subjects) {
                            if (data.containsKey(sub)) {
                              marks[sub] = (data[sub] as num).toInt();
                            }
                          }
                        });
                      } else {
                        setDialogState(() => marks.clear());
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                ...subjects.map((sub) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextFormField(
                    key: ValueKey('$selectedExam-$sub-${marks[sub]}'),
                    initialValue: marks[sub]?.toString() ?? '',
                    decoration: InputDecoration(labelText: sub, hintText: 'Enter Marks'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => marks[sub] = int.tryParse(val) ?? 0,
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (selectedExam == null || marks.isEmpty) return;
                final result = await _instructorService.assignMarks(
                  uid: uid,
                  examId: selectedExam!,
                  marks: marks,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success'] ? Colors.green : Colors.red,
                  ));
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkAttendanceDialog(BuildContext context, String uid, String name) {
    DateTime selectedDate = DateTime.now();
    final Map<String, String> periodStatus = {
      'p1': 'P', 'p2': 'P', 'p3': 'P', 'p4': 'P',
      'p5': 'P', 'p6': 'P', 'p7': 'P', 'p8': 'P',
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Mark Attendance for $name"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text("Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      final dateStr = DateFormat('yyyy-MM-dd').format(date);
                      final doc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('attendance')
                          .doc(dateStr)
                          .get();
                      
                      setDialogState(() {
                        selectedDate = date;
                        if (doc.exists) {
                          final data = doc.data() as Map<String, dynamic>;
                          periodStatus.forEach((key, value) {
                            if (data.containsKey(key)) {
                              periodStatus[key] = data[key] as String;
                            }
                          });
                        } else {
                          periodStatus.updateAll((key, value) => 'P');
                        }
                      });
                    }
                  },
                ),
                const Divider(),
                ...List.generate(8, (index) {
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
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final result = await _instructorService.updateAttendance(
                  uid: uid,
                  date: selectedDate,
                  periodStatus: periodStatus,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success'] ? Colors.green : Colors.red,
                  ));
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkAssignMarksDialog(BuildContext context, List<QueryDocumentSnapshot> students) async {
    // 1. Fetch Exams & Subjects
    final classId = 'BTECH_3'; // Assuming single class for MVP
    final examsSnapshot = await FirebaseFirestore.instance.collection('classes').doc(classId).collection('exams').get();
    final exams = examsSnapshot.docs.map((d) => d.data()).toList();
    
    final subjectsSnapshot = await FirebaseFirestore.instance.collection('subjects').get();
    final subjects = subjectsSnapshot.docs.map((d) => d.data()['name'] as String).toList();

    if (exams.isEmpty || subjects.isEmpty) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No exams or subjects found.")));
      return;
    }

    String? selectedExam = exams.first['name'];
    String? selectedSubject = subjects.first;
    final Map<String, int> marksMap = {}; // uid -> marks

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Bulk Assign Marks"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedExam,
                        decoration: const InputDecoration(labelText: 'Exam', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                        items: exams.map((e) => DropdownMenuItem(value: e['name'] as String, child: Text(e['name'] as String, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setDialogState(() => selectedExam = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedSubject,
                        decoration: const InputDecoration(labelText: 'Subject', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                        items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setDialogState(() => selectedSubject = val),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final doc = students[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Unknown';
                      final uid = doc.id;

                      return ListTile(
                        leading: CircleAvatar(child: Text(name[0])),
                        title: Text(name, style: const TextStyle(fontSize: 13)),
                        trailing: SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: '',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'Marks', isDense: true),
                            onChanged: (val) {
                              marksMap[uid] = int.tryParse(val) ?? 0;
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (selectedExam == null || selectedSubject == null) return;
                
                int successCount = 0;
                for (var entry in marksMap.entries) {
                  final uid = entry.key;
                  final score = entry.value;
                  
                  // Use existing assignMarks but formatted for single update or batched if optimal.
                  // Reusing _instructorService.assignMarks which expects a Map of subjects.
                  // We are assigning ONLY ONE subject here for bulk to keep it simple.
                  // Ideally we'd have `updateStudentMark(uid, exam, subject, score)` but `assignMarks` overwrites.
                  // We should be careful not to overwrite other subject marks if `assignMarks` uses `set` without `merge: true`.
                  // Looking at standard Firestore patterns, `set` replaces. `update` patches.
                  // Let's assume `assignMarks` handles it or we use `set` with `SetOptions(merge: true)` inside it.
                  // Since I can't check `InstructorService` right now, I'll assume safe merge OR
                  // I will do a direct Firestore update here to be safe and fast.
                  
                  try {
                    await FirebaseFirestore.instance.collection('users').doc(uid).collection('marks').doc(selectedExam).set(
                      { selectedSubject!: score, 'examId': selectedExam },
                      SetOptions(merge: true)
                    );
                    successCount++;
                  } catch (e) {
                    debugPrint("Error assigning marks for $uid: $e");
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Assigned marks to $successCount students."),
                    backgroundColor: Colors.green,
                  ));
                }
              },
              child: const Text("Save All"),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkMarkAttendanceDialog(BuildContext context, List<QueryDocumentSnapshot> students) {
    DateTime selectedDate = DateTime.now();
    final Map<String, String> commonPeriodStatus = {
      'p1': 'P',
      'p2': 'P',
      'p3': 'P',
      'p4': 'P',
      'p5': 'P',
      'p6': 'P',
      'p7': 'P',
      'p8': 'P',
    };
    final Set<String> selectedStudentIds = students.map((s) => s.id).toSet();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Bulk Mark Attendance"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text("Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setDialogState(() => selectedDate = date);
                    },
                  ),
                  const Divider(),
                  const Text("Apply to all selected students:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ...List.generate(8, (index) {
                    final period = 'p${index + 1}';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("P${index + 1}", style: const TextStyle(fontSize: 12)),
                          ToggleButtons(
                            isSelected: [
                              commonPeriodStatus[period] == 'P',
                              commonPeriodStatus[period] == 'A',
                              commonPeriodStatus[period] == 'L',
                            ],
                            onPressed: (idx) {
                              setDialogState(() {
                                commonPeriodStatus[period] = idx == 0 ? 'P' : (idx == 1 ? 'A' : 'L');
                              });
                            },
                            constraints: const BoxConstraints(minWidth: 35, minHeight: 25),
                            borderRadius: BorderRadius.circular(6),
                            children: const [
                              Text("P", style: TextStyle(fontSize: 10)),
                              Text("A", style: TextStyle(fontSize: 10)),
                              Text("L", style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  const Text("Select Students:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ...students.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final uid = doc.id;
                    return CheckboxListTile(
                      title: Text(name, style: const TextStyle(fontSize: 13)),
                      value: selectedStudentIds.contains(uid),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            selectedStudentIds.add(uid);
                          } else {
                            selectedStudentIds.remove(uid);
                          }
                        });
                      },
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (selectedStudentIds.isEmpty) return;

                int successCount = 0;
                for (String uid in selectedStudentIds) {
                  final result = await _instructorService.updateAttendance(
                    uid: uid,
                    date: selectedDate,
                    periodStatus: Map<String, String>.from(commonPeriodStatus),
                  );
                  if (result['success']) successCount++;
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Attendance updated for $successCount students."),
                    backgroundColor: Colors.green,
                  ));
                }
              },
              child: const Text("Save Attendance"),
            ),
          ],
        ),
      ),
    );
  }
}
