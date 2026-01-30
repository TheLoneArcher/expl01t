import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnnouncementsView extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final bool isPosting;
  final VoidCallback onPost;

  const AnnouncementsView({
    super.key,
    required this.titleController,
    required this.contentController,
    required this.isPosting,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Make an Announcement", style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Message",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isPosting ? null : onPost,
                      icon: const Icon(Icons.send),
                      label: isPosting ? const Text("Posting...") : const Text("POST ANNOUNCEMENT"),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text("Recent Posts", style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
             stream: FirebaseFirestore.instance.collection('announcements').orderBy('date', descending: true).limit(5).snapshots(),
             builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                if (snapshot.data!.docs.isEmpty) return const Text("No announcements yet.");
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                     final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                     final date = (data['date'] as Timestamp).toDate();
                     return Card(
                       margin: const EdgeInsets.only(bottom: 10),
                       child: ListTile(
                         title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                         subtitle: Text("${data['content']}\n\nPosted by ${data['author']} on ${DateFormat('MMM d, h:mm a').format(date)}"),
                         isThreeLine: true,
                       ),
                     );
                  },
                );
             },
          )
        ],
      ),
    );
  }
}
