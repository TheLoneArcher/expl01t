import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camp_x/utils/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camp_x/services/instructor_service.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM y').format(now);

    if (user == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dynamic Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor.withValues(alpha: 0.8), theme.colorScheme.secondary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                   "Welcome back,",
                   style: GoogleFonts.exo2(fontSize: 16, color: Colors.white70),
                 ),
                 const SizedBox(height: 5),
                 Text(
                   user['name'],
                   style: GoogleFonts.orbitron(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                 ),
                 const SizedBox(height: 15),
                 Row(
                   children: [
                     const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                     const SizedBox(width: 8),
                     Text(dateStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                   ],
                 )
              ],
            ),
          ),
          
          const SizedBox(height: 30),

          // 2. Responsive Stats Row
          StreamBuilder<double>(
            stream: InstructorService().getAttendancePercentage(user['uid']),
            builder: (context, attSnapshot) {
              return StreamBuilder<double>(
                stream: InstructorService().getMarksAverage(user['uid']),
                builder: (context, marksSnapshot) {
                   final attPerc = attSnapshot.data ?? 0.0;
                   final marksPerc = marksSnapshot.data ?? 0.0;

                   return LayoutBuilder(
                    builder: (context, constraints) {
                       // If width > 600, use Row, else Column
                       bool isWide = constraints.maxWidth > 600;
                       List<Widget> cards = [
                          _StatCard(
                            label: "Attendance",
                            value: "${attPerc.toStringAsFixed(1)}%",
                            icon: Icons.check_circle_outline,
                            color: Colors.greenAccent,
                          ),
                          SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                          _StatCard(
                            label: "Avg performance",
                            value: "${marksPerc.toStringAsFixed(1)}%", 
                            icon: Icons.bar_chart,
                            color: Colors.amberAccent,
                          ),
                       ];

                       return isWide 
                          ? Row(children: cards.map((c) => c is SizedBox ? c : Expanded(child: c)).toList())
                          : Column(children: cards);
                    }
                  );
                }
              );
            }
          ),
          
          const SizedBox(height: 30),

          const SizedBox(height: 30),

          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 900;
              
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(title: "Announcements", icon: Icons.campaign),
                          const SizedBox(height: 16),
                          _buildAnnouncements(theme),
                        ],
                      ),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: "Homework Due", 
                            icon: Icons.assignment,
                            trailing: user['role'] == 'instructor' 
                                ? IconButton(
                                    icon: const Icon(Icons.add_task),
                                    onPressed: () => _showAssignHomeworkDialog(context),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildHomeworkList(context),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _SectionHeader(title: "Announcements", icon: Icons.campaign),
                   const SizedBox(height: 16),
                   _buildAnnouncements(theme),
                   const SizedBox(height: 30),
                   _SectionHeader(
                     title: "Homework Due", 
                     icon: Icons.assignment,
                     trailing: user['role'] == 'instructor' 
                         ? IconButton(
                             icon: const Icon(Icons.add_task),
                             onPressed: () => _showAssignHomeworkDialog(context),
                           )
                         : null,
                   ),
                   const SizedBox(height: 16),
                   _buildHomeworkList(context),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncements(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('announcements').orderBy('date', descending: true).limit(3).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Column(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.primaryColor.withValues(alpha: 0.2))),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    child: Icon(Icons.campaign, color: theme.primaryColor),
                  ),
                  title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "${data['content']}\n${DateFormat('MMM d').format(date)} • ${data['author']}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: (context.read<UserProvider>().user?['role'] == 'instructor')
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => _showEditAnnouncementDialog(context, doc.id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                              onPressed: () => _confirmDeleteAnnouncement(context, doc.id),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            }).toList(),
          );
        }
        return _EmptyState(message: "No new announcements");
      },
    );
  }

  Widget _buildHomeworkList(BuildContext context) {
    final Map<String, dynamic>? user = context.read<UserProvider>().user;
    if (user == null) return const SizedBox();
    final String uid = user['uid'] as String;
    final String role = user['role'] as String;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc('BTECH_3') 
          .collection('homework')
          .orderBy('date', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text("Error: ${snapshot.error}");
        if (!snapshot.hasData) return const LinearProgressIndicator();

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text("No pending homework.");

        // We use a StreamBuilder inside to fetch completion statuses
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('homework_status')
              .snapshots(),
          builder: (context, statusSnapshot) {
            final Set<String> completedIds = statusSnapshot.hasData 
                ? statusSnapshot.data!.docs
                    .where((doc) => (doc.data() as Map<String, dynamic>)['isCompleted'] == true)
                    .map((doc) => doc.id)
                    .toSet() 
                : <String>{};

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final homeworkId = doc.id;
                // final isInstructor = user['role'] == 'instructor'; // Removed unused variable
                
                return _TaskItem(
                  id: homeworkId,
                  uid: uid,
                  subject: (data['subject'] ?? 'General') as String,
                  description: (data['description'] ?? 'Task') as String,
                  date: (data['date'] as Timestamp).toDate(),
                  isCompleted: completedIds.contains(homeworkId),
                  isInstructor: role == 'instructor',
                );
              },
            );
          }
        );
      },
    );
  }

  void _showEditAnnouncementDialog(BuildContext context, String id, Map<String, dynamic> currentData) {
    final TextEditingController editTitleController = TextEditingController(text: currentData['title']);
    final TextEditingController editContentController = TextEditingController(text: currentData['content']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Announcement"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: editTitleController, decoration: const InputDecoration(labelText: "Title")),
            const SizedBox(height: 10),
            TextField(controller: editContentController, maxLines: 4, decoration: const InputDecoration(labelText: "Message")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (editTitleController.text.isEmpty || editContentController.text.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              try {
                await FirebaseFirestore.instance.collection('announcements').doc(id).update({
                  'title': editTitleController.text.trim(),
                  'content': editContentController.text.trim(),
                });
                nav.pop();
                messenger.showSnackBar(const SnackBar(content: Text("Announcement updated!")));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAnnouncement(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Announcement?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              try {
                await FirebaseFirestore.instance.collection('announcements').doc(id).delete();
                nav.pop();
                messenger.showSnackBar(const SnackBar(content: Text("Announcement deleted!")));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAssignHomeworkDialog(BuildContext context) async {
    final subjectsSnapshot = await FirebaseFirestore.instance.collection('subjects').get();
    final subjects = subjectsSnapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    if (subjects.isEmpty) return;

    if (!context.mounted) return;

    String? selectedSubject = subjects.first;
    final TextEditingController descController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Assign Homework"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedSubject,
                decoration: const InputDecoration(labelText: "Subject"),
                items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setDialogState(() => selectedSubject = val),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description", hintText: "Read Chapter 5..."),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   const Text("Due Date: "),
                   TextButton.icon(
                     icon: const Icon(Icons.calendar_today),
                     label: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                     onPressed: () async {
                       final date = await showDatePicker(
                         context: context,
                         initialDate: selectedDate,
                         firstDate: DateTime.now(),
                         lastDate: DateTime.now().add(const Duration(days: 365)),
                       );
                       if (date != null) setDialogState(() => selectedDate = date);
                     },
                   )
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (descController.text.isEmpty || selectedSubject == null) return;
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                final user = context.read<UserProvider>().user;
                
                try {
                  await InstructorService().assignHomework(
                    classId: 'BTECH_3',
                    subject: selectedSubject!,
                    description: descController.text.trim(),
                    date: selectedDate,
                    instructorName: user?['name'] ?? 'Instructor',
                  );
                  nav.pop();
                  messenger.showSnackBar(const SnackBar(content: Text("Homework Assigned!")));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Assign"),
            )
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  const _SectionHeader({required this.title, required this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.bold))),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Center(child: Text(message)),
    );
  }
}


class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
            ],
          ),
          Icon(icon, color: color, size: 40),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String id;
  final String uid;
  final String subject;
  final String description;
  final DateTime date;
  final bool isCompleted;
  final bool isInstructor;

  const _TaskItem({
    required this.id,
    required this.uid,
    required this.subject,
    required this.description,
    required this.date,
    required this.isCompleted,
    this.isInstructor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isCompleted ? Colors.green.withValues(alpha: 0.5) : Colors.transparent),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted ? Colors.green.withValues(alpha: 0.1) : Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: isCompleted 
            ? const Icon(Icons.check, color: Colors.green, size: 16)
            : Text(subject.substring(0, 1), style: TextStyle(color: Theme.of(context).primaryColor)),
        ),
        title: Text(
          subject, 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : null,
          )
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: TextStyle(color: isCompleted ? Colors.grey : null)),
            Text(
              "Due: ${DateFormat('MMM d').format(date)}",
              style: TextStyle(fontSize: 12, color: isCompleted ? Colors.grey : Colors.redAccent.withValues(alpha: 0.8)),
            ),
          ],
        ),
        trailing: isInstructor
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => _confirmDeleteHomework(context, id),
              )
            : Checkbox(
                value: isCompleted,
                activeColor: Colors.greenAccent,
                onChanged: (val) async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('homework_status')
                      .doc(id)
                      .set({'isCompleted': val ?? false}, SetOptions(merge: true));
                },
              ),
      ),
    );
  }

  void _confirmDeleteHomework(BuildContext context, String dateStr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Homework?"),
        content: const Text("This will remove this homework for all students."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              final result = await InstructorService().deleteHomework(
                classId: 'BTECH_3',
                dateStr: dateStr,
              );
              nav.pop();
              messenger.showSnackBar(SnackBar(
                content: Text(result['message']),
                backgroundColor: result['success'] ? Colors.green : Colors.red,
              ));
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
