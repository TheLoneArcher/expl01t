import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeworkSection extends StatefulWidget {
  final String subjectName;
  const HomeworkSection({super.key, required this.subjectName});

  @override
  State<HomeworkSection> createState() => _HomeworkSectionState();
}

class _HomeworkSectionState extends State<HomeworkSection> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc('BTECH_3')
          .collection('homework')
          .where('subject', isEqualTo: widget.subjectName)
          // .orderBy('dueDate', descending: true) // Removed for index issue
          .limit(5)
          .snapshots(),
      builder: (context, hwSnapshot) {
        if (hwSnapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text("Error: ${hwSnapshot.error}", style: const TextStyle(color: Colors.red)),
          );
        }
        if (!hwSnapshot.hasData || hwSnapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Assigned Homework",
                  style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 8),
                const Text("No homework assigned for this subject.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        final homeworkDocs = hwSnapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                "Assigned Homework",
                style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).primaryColor),
              ),
            ),
            ...homeworkDocs.map((hwDoc) {
              final hw = hwDoc.data() as Map<String, dynamic>;
              final isExpanded = _expandedId == hwDoc.id;
              
              return Card(
                elevation: isExpanded ? 4 : 1,
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isExpanded ? BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)) : BorderSide.none,
                ),
                color: isExpanded ? Theme.of(context).cardColor : Theme.of(context).cardColor.withOpacity(0.9),
                child: _buildHomeworkStatItem(context, hwDoc.id, hw, isExpanded),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildHomeworkStatItem(BuildContext context, String hwId, Map<String, dynamic> hw, bool isExpanded) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classId', isEqualTo: 'BTECH_3')
          .snapshots(),
      builder: (context, studentsSnapshot) {
        if (!studentsSnapshot.hasData) {
          return const ListTile(title: Text("Loading stats..."));
        }

        final students = studentsSnapshot.data!.docs;
        
        return FutureBuilder<Map<String, List<String>>>(
          future: _getCompletionDetails(hwId, students),
          builder: (context, detailsSnapshot) {
            final details = detailsSnapshot.data;
            final completedCount = details?['completed']?.length ?? 0;
            final total = students.length;

            return ExpansionTile(
              // Key forces rebuild on expansion state change to enforce single expansion
              key: Key('${hwId}_$isExpanded'), 
              initiallyExpanded: isExpanded,
              onExpansionChanged: (val) {
                if (val) {
                  setState(() => _expandedId = hwId);
                } else if (_expandedId == hwId) {
                  setState(() => _expandedId = null);
                }
              },
              title: Text(
                hw['description'] ?? 'Homework',
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: isExpanded ? FontWeight.bold : FontWeight.normal
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "Due: ${(hw['dueDate'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'N/A'}  |  $completedCount/$total Completed",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              leading: Icon(
                Icons.assignment, 
                color: completedCount == total ? Colors.green : (completedCount > 0 ? Colors.orange : Colors.grey)
              ),
              children: [
                if (details == null)
                   const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()),
                if (details != null) ...[
                  if (details['completed']!.isNotEmpty)
                    ListTile(
                      title: const Text("Completed", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
                      subtitle: Text(details['completed']!.join(", "), style: const TextStyle(fontSize: 12)),
                      dense: true,
                    ),
                  if (details['pending']!.isNotEmpty)
                    ListTile(
                      title: const Text("Pending", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 12)),
                      subtitle: Text(details['pending']!.join(", "), style: const TextStyle(fontSize: 12)),
                      dense: true,
                    ),
                  if (details['completed']!.isEmpty && details['pending']!.isEmpty)
                     const ListTile(title: Text("No data")),
                   const Divider(),
                   ListTile(
                     leading: const Icon(Icons.delete, color: Colors.red),
                     title: const Text("Delete Homework", style: TextStyle(color: Colors.red)),
                     onTap: () => _confirmDeleteHomework(context, hwId),
                   ),
                ]
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, List<String>>> _getCompletionDetails(String hwId, List<QueryDocumentSnapshot> students) async {
    List<String> completed = [];
    List<String> pending = [];

    for (var student in students) {
      try {
        final data = student.data() as Map<String, dynamic>;
        final rollNo = data['rollNumber'] ?? data['name'] ?? 'Unknown';
        
        final statusDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(student.id)
            .collection('homework_status')
            .doc(hwId)
            .get();
        
        if (statusDoc.exists && (statusDoc.data()?['isCompleted'] == true)) {
          completed.add(rollNo);
        } else {
          pending.add(rollNo);
        }
      } catch (e) {
        // ignore error
      }
    }
    return {'completed': completed, 'pending': pending};
  }

  Future<void> _confirmDeleteHomework(BuildContext context, String hwId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Homework?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('classes')
            .doc('BTECH_3')
            .collection('homework')
            .doc(hwId)
            .delete();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Homework deleted")));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }
}
