import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class SyllabusTab extends StatelessWidget {
  const SyllabusTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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
                title: Text(subData['name'], style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text(
                  "${topics.where((t) => t['status'] == 'covered').length} / ${topics.length} Topics Completed",
                  style: const TextStyle(color: Colors.grey),
                ),
                children: topics.map((topic) {
                  final bool isCovered = topic['status'] == 'covered';
                  return CheckboxListTile(
                    activeColor: Theme.of(context).primaryColor,
                    value: isCovered,
                    title: Text(topic['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                    onChanged: (val) async {
                      final updatedTopics = topics.map((t) {
                        if (t['name'] == topic['name']) {
                          return {'name': t['name'], 'status': val! ? 'covered' : 'pending'};
                        }
                        return t;
                      }).toList();

                      await subjects[index].reference.update({'topics': updatedTopics});
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );

  }
}
