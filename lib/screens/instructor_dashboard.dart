import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:camp_x/utils/user_provider.dart'; // Ensure correct path
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart'; // Removed unused import
import 'package:camp_x/screens/tabs/calendar_tab.dart';
import 'package:camp_x/screens/tabs/students_tab.dart';
import 'package:camp_x/screens/landing_page.dart';
import 'package:camp_x/screens/widgets/announcements_view.dart';






import 'package:camp_x/screens/widgets/instructor_home_view.dart';
import 'package:camp_x/screens/tabs/syllabus_tab.dart';
import 'package:camp_x/screens/tabs/profile_tab.dart';
import 'package:camp_x/screens/tabs/chat_tab.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _announcementTitleController = TextEditingController();
  final TextEditingController _announcementContentController = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this); // Adjusted length
  }



  @override
  void dispose() {
    _tabController.dispose();
    _announcementTitleController.dispose();
    _announcementContentController.dispose();
    super.dispose();
  }

  Future<void> _postAnnouncement() async {
    if (_announcementTitleController.text.isEmpty || _announcementContentController.text.isEmpty) return;
    setState(() => _isPosting = true);
    try {
      final user = context.read<UserProvider>().user;
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': _announcementTitleController.text.trim(),
        'content': _announcementContentController.text.trim(),
        'date': Timestamp.now(),
        'author': user?['name'] ?? 'Instructor',
      });
      _announcementTitleController.clear();
      _announcementContentController.clear();
      _announcementContentController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Posted!")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Instructor Panel', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "HOME", icon: Icon(Icons.home)),
            Tab(text: "SYLLABUS", icon: Icon(Icons.book)),
            Tab(text: "AI CHAT", icon: Icon(Icons.psychology_outlined)),
            Tab(text: "STUDENTS", icon: Icon(Icons.people)),
            Tab(text: "CALENDAR", icon: Icon(Icons.calendar_month)),
            Tab(text: "ANNOUNCE", icon: Icon(Icons.campaign)),
            Tab(text: "PROFILE", icon: Icon(Icons.person)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<UserProvider>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LandingPage()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: TabBarView(
            controller: _tabController,
            children: [
              user != null 
                ? InstructorHomeView(user: user) 
                : const Center(child: Text("Loading user data...")),
              const SyllabusTab(),
              const ChatTab(),
              const StudentsTab(),
              const CalendarTab(),
              AnnouncementsView(
                titleController: _announcementTitleController,
                contentController: _announcementContentController,
                isPosting: _isPosting,
                onPost: _postAnnouncement,
              ),
              const ProfileTab(),
            ],
          ),
        ),
      ),


    );
  }
}
