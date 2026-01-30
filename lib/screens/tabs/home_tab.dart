import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camp_x/utils/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                colors: [theme.primaryColor.withOpacity(0.8), theme.colorScheme.secondary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
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
          LayoutBuilder(
            builder: (context, constraints) {
               // If width > 600, use Row, else Column
               bool isWide = constraints.maxWidth > 600;
               List<Widget> cards = [
                  _StatCard(
                    label: "Attendance",
                    value: "85%", // Todo: Real calc
                    icon: Icons.check_circle_outline,
                    color: Colors.greenAccent,
                  ),
                  SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                  _StatCard(
                    label: "Marks Avg",
                    value: "78%", 
                    icon: Icons.bar_chart,
                    color: Colors.amberAccent,
                  ),
               ];

               return isWide 
                  ? Row(children: cards.map((c) => c is SizedBox ? c : Expanded(child: c)).toList())
                  : Column(children: cards);
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
                          _SectionHeader(title: "Homework Due", icon: Icons.assignment),
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
                   _SectionHeader(title: "Homework Due", icon: Icons.assignment),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.primaryColor.withOpacity(0.2))),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Icon(Icons.campaign, color: theme.primaryColor),
                  ),
                  title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "${data['content']}\n${DateFormat('MMM d').format(date)} • ${data['author']}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
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
    final user = context.read<UserProvider>().user;
    if (user == null) return const SizedBox();

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
              .doc(user['uid'])
              .collection('homework_status')
              .snapshots(),
          builder: (context, statusSnapshot) {
            final completedIds = statusSnapshot.hasData 
                ? statusSnapshot.data!.docs.where((doc) => doc['isCompleted'] == true).map((doc) => doc.id).toSet() 
                : <String>{};

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final homeworkId = doc.id;
                
                return _TaskItem(
                  id: homeworkId,
                  uid: user['uid'],
                  subject: data['subject'] ?? 'General',
                  description: data['description'] ?? 'Task',
                  date: (data['date'] as Timestamp).toDate(),
                  isCompleted: completedIds.contains(homeworkId),
                );
              },
            );
          }
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.bold)),
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
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
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

  const _TaskItem({
    required this.id,
    required this.uid,
    required this.subject,
    required this.description,
    required this.date,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isCompleted ? Colors.green.withOpacity(0.5) : Colors.transparent),
      ),
      child: CheckboxListTile(
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
              style: TextStyle(fontSize: 12, color: isCompleted ? Colors.grey : Colors.redAccent.withOpacity(0.8)),
            ),
          ],
        ),
        secondary: CircleAvatar(
          backgroundColor: isCompleted ? Colors.green.withOpacity(0.1) : Theme.of(context).primaryColor.withOpacity(0.1),
          child: isCompleted 
            ? const Icon(Icons.check, color: Colors.green, size: 16)
            : Text(subject.substring(0, 1), style: TextStyle(color: Theme.of(context).primaryColor)),
        ),
      ),
    );
  }
}
