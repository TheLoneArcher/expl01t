import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'temp_homework_section.dart';


class SyllabusTab extends StatelessWidget {
  const SyllabusTab({super.key});

  void _showAssignHomeworkDialog(BuildContext context, String subjectName) {
    final TextEditingController descController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String classId = 'BTECH_3'; // Default class

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Assign $subjectName Homework"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                     label: Text(selectedDate.toString().split(' ')[0]),
                     onPressed: () async {
                       final date = await showDatePicker(
                         context: context,
                         initialDate: selectedDate,
                         firstDate: DateTime.now(),
                         lastDate: DateTime.now().add(const Duration(days: 365)),
                       );
                       if (date != null) setState(() => selectedDate = date);
                     },
                   )
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (descController.text.isEmpty) return;
                
                // Show loading indicator or disable button
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);

                try {
                  await FirebaseFirestore.instance.collection('classes').doc(classId).collection('homework').add({
                    'subject': subjectName,
                    'description': descController.text.trim(),
                    'dueDate': Timestamp.fromDate(selectedDate),
                    'assignedDate': Timestamp.now(),
                    'status': 'pending', 
                  });
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

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Error loading subjects: ${snapshot.error}"),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("No subjects available"),
            ),
          );
        }
        final subjects = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subData = subjects[index].data() as Map<String, dynamic>;
            final topics = List<Map<String, dynamic>>.from(subData['topics'] ?? []);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Expanded(child: Text(subData['name'], style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 18))),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.assignment_add, color: Theme.of(context).primaryColor, size: 20),
                          tooltip: "Assign Homework",
                          onPressed: () => _showAssignHomeworkDialog(context, subData['name']),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor, size: 20),
                          tooltip: "Add Topic",
                          onPressed: () => _showAddTopicDialog(context, subjects[index].reference, topics),
                        ),
                      ],
                    ),
                  ],
                ),
                subtitle: Text(
                  "${topics.where((t) => t['status'] == 'covered').length} / ${topics.length} Topics Completed",
                  style: const TextStyle(color: Colors.grey),
                ),
                children: [
                  // Topics Section Header
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "Topics",
                      style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).primaryColor),
                    ),
                  ),
                  ...topics.map((topic) {
                    final bool isCovered = topic['status'] == 'covered';
                    return ListTile(
                      leading: Checkbox(
                        activeColor: Theme.of(context).primaryColor,
                        value: isCovered,
                        onChanged: (val) async {
                          final updatedTopics = topics.map((t) {
                            if (t['name'] == topic['name']) {
                              return {'name': t['name'], 'status': val! ? 'covered' : 'pending'};
                            }
                            return t;
                          }).toList();

                          await subjects[index].reference.update({'topics': updatedTopics});
                        },
                      ),
                      title: Text(topic['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        tooltip: "Delete Topic",
                        onPressed: () => _confirmDeleteTopic(context, subjects[index].reference, topics, topic),
                      ),
                    );
                  }),
                  const Divider(),
                  // Homework Section
                  HomeworkSection(subjectName: subData['name']),
                ],
              ),
            );
          },
        );
      },
    );

  }

  void _showAddTopicDialog(BuildContext context, DocumentReference subRef, List<Map<String, dynamic>> currentTopics) {
    final TextEditingController topicController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Topic"),
        content: TextField(
          controller: topicController,
          decoration: const InputDecoration(labelText: "Topic Name", hintText: "e.g. Quantum Mechanics Intro"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (topicController.text.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);

              final newTopic = {
                'name': topicController.text.trim(),
                'status': 'pending',
              };
              final updatedTopics = [...currentTopics, newTopic];
              try {
                await subRef.update({'topics': updatedTopics});
                nav.pop();
                messenger.showSnackBar(const SnackBar(content: Text("Topic added!")));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTopic(BuildContext context, DocumentReference subRef, List<Map<String, dynamic>> currentTopics, Map<String, dynamic> topicToDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Topic?"),
        content: Text("Are you sure you want to delete \"${topicToDelete['name']}\"? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              
              final updatedTopics = currentTopics.where((t) => t['name'] != topicToDelete['name']).toList();
              try {
                await subRef.update({'topics': updatedTopics});
                nav.pop();
                messenger.showSnackBar(const SnackBar(content: Text("Topic deleted!")));
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
}


