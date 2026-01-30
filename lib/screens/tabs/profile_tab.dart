import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this import
import 'package:camp_x/utils/user_provider.dart'; // Add this import
import 'package:camp_x/screens/landing_page.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) return const Center(child: Text("No user data"));

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 700;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Pic
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 70, // Bigger profile pic
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    child: SvgPicture.asset(
                      'assets/images/default_profile.svg',
                      width: 80, 
                      height: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 24),
                  )
                ],
              ),
              const SizedBox(height: 24),
              
              Text(
                user['name'],
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Text(
                user['uid'],
                style: TextStyle(color: Colors.grey[600], fontSize: 18),
              ),
              const SizedBox(height: 40),
              
              // Responsive Items Grid
              if (isWide)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 4.5, // Even more compact
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 12,
                  children: [
                    _ProfileItem(icon: Icons.email, label: "Email", value: user['email'] ?? 'N/A'),
                    _ProfileItem(icon: Icons.school, label: "Class", value: user['classId'] ?? 'N/A'),
                    _ProfileItem(icon: Icons.shield, label: "Role", value: (user['role'] as String).toUpperCase()),
                    _ProfileItem(icon: Icons.calendar_today, label: "Member Since", value: "April 2025"),
                  ],
                )
              else
                Column(
                  children: [
                    _ProfileItem(icon: Icons.email, label: "Email", value: user['email'] ?? 'N/A'),
                    _ProfileItem(icon: Icons.school, label: "Class", value: user['classId'] ?? 'N/A'),
                    _ProfileItem(icon: Icons.shield, label: "Role", value: (user['role'] as String).toUpperCase()),
                    _ProfileItem(icon: Icons.calendar_today, label: "Member Since", value: "April 2025"),
                  ],
                ),

              const SizedBox(height: 30), // Reduced from 50
              SizedBox(
                width: isWide ? 300 : double.infinity,
                height: 50, // Slightly shorter
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<UserProvider>().logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LandingPage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text("SECURE LOGOUT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Sharper corners for techno look
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );

  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(
                    value, 
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

