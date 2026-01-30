import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InstructorHomeView extends StatelessWidget {
  final Map<String, dynamic> user;

  const InstructorHomeView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM y').format(now);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.8),
                  theme.colorScheme.secondary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi,",
                  style: GoogleFonts.exo2(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  user['name'],
                  style: GoogleFonts.orbitron(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Meetings Section
          Text(
            "Meetings & Schedule",
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('meetings')
                    .orderBy('time')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Card(
                      child: ListTile(
                        title: Text("No meetings scheduled"),
                      ),
                    );
                  }

                  if (isWide) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final data = snapshot.data!.docs[index]
                            .data() as Map<String, dynamic>;
                        final time =
                            (data['time'] as Timestamp)
                                .toDate();

                        return MeetingCard(
                          data: data,
                          time: time,
                        );
                      },
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final data = snapshot.data!.docs[index]
                          .data() as Map<String, dynamic>;
                      final time =
                          (data['time'] as Timestamp)
                              .toDate();

                      return MeetingCard(
                        data: data,
                        time: time,
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/* ============================
   MEETING CARD WIDGET
============================ */

class MeetingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final DateTime time;

  const MeetingCard({
    super.key,
    required this.data,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.videocam),
        title: Text(
          data['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${DateFormat('h:mm a').format(time)} | ${data['type']}",
        ),
        trailing: data['link'] != null
            ? IconButton(
                icon: const Icon(Icons.link),
                onPressed: () {},
              )
            : null,
      ),
    );
  }
}
