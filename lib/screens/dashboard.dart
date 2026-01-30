import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camp_x/screens/tabs/home_tab.dart';
import 'package:camp_x/screens/tabs/calendar_tab.dart';
import 'package:camp_x/screens/tabs/marks_tab.dart';
import 'package:camp_x/screens/tabs/profile_tab.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('CampX', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          indicatorColor: theme.primaryColor,
          labelStyle: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "HOME", icon: Icon(Icons.dashboard_outlined)),
            Tab(text: "CALENDAR", icon: Icon(Icons.calendar_today_outlined)),
            Tab(text: "MARKS", icon: Icon(Icons.analytics_outlined)),
            Tab(text: "PROFILE", icon: Icon(Icons.person_outline)),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: TabBarView(
            controller: _tabController,
            children: const [
              HomeTab(),
              CalendarTab(),
              MarksTab(),
              ProfileTab(),
            ],
          ),
        ),
      ),


    );
  }
}
