import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:camp_x/utils/theme_provider.dart';
import 'package:camp_x/utils/user_provider.dart';
import 'package:camp_x/services/seeding_service.dart';
import 'package:camp_x/screens/dashboard.dart';
import 'package:camp_x/screens/instructor_dashboard.dart';


import 'dart:math' as math;


class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Animated Background
          const _TechnoBackground(),

          // 2. Content
          Column(
            children: [
              _NavBar(isDesktop: isDesktop),
              Expanded(
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 5, child: _HeroSection(isDesktop: true)),
                          Expanded(
                            flex: 4, 
                            child: Container(
                              height: double.infinity, // Fill available height
                              child: const _TechnoVisualizer(),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            const SizedBox(height: 300, child: _TechnoVisualizer()),
                            _HeroSection(isDesktop: false),
                          ],
                        ),
                      ),
              ),


            ],

          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final bool isDesktop;
  const _NavBar({required this.isDesktop});

  void _showLoginDialog(BuildContext context) {
    final uidController = TextEditingController();
    final passController = TextEditingController();
    // Using a ValueNotifier for simple state in stateless widget
    final isLoading = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) => ValueListenableBuilder<bool>(
        valueListenable: isLoading,
        builder: (context, loading, child) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.login_rounded, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text("Student Login", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: uidController,
                    decoration: InputDecoration(
                      labelText: "Student ID",
                      hintText: "e.g. 23AK1A3601",
                      prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                    ),
                  ),
                  if (loading) const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Quick Access",
                    style: GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor.withOpacity(0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAccessCard(
                          label: "STUDENT",
                          icon: Icons.school_outlined,
                          color: Colors.blueAccent,
                          onTap: loading ? null : () {
                            uidController.text = "23AK1A3601";
                            passController.text = "23AK1A3601";
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAccessCard(
                          label: "INSTRUCTOR",
                          icon: Icons.person_outline,
                          color: Colors.greenAccent,
                          onTap: loading ? null : () {
                            uidController.text = "INSTR01";
                            passController.text = "INSTR01";
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text("CANCEL", style: GoogleFonts.exo2(fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: loading ? null : () async {
                  isLoading.value = true;
                  final success = await context.read<UserProvider>().login(uidController.text.trim(), passController.text.trim());
                  isLoading.value = false;
                  
                  if (success) {
                    Navigator.pop(context); // Close dialog
                    final user = context.read<UserProvider>().user;
                    
                    if (user != null && user['role'] == 'instructor') {
                       Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (_) => const InstructorDashboard())
                      );
                    } else {
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (_) => const DashboardScreen())
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Credentials")));
                  }

                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("LOGIN", style: GoogleFonts.exo2(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 20, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
        border: Border(bottom: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: () async {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seeding Database...")));
                 await SeedingService().seedDatabase();
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Database Seeded!")));
              },
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary],
                ).createShader(bounds),
                child: Text(
                  'CampX',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.orbitron(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  context.watch<ThemeProvider>().isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () => context.read<ThemeProvider>().toggleTheme(),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _showLoginDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shadowColor: Theme.of(context).primaryColor,
                    elevation: 10,
                  ),
                  child: Text('LOGIN', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
                ),
              ] else ...[
                 const SizedBox(width: 8),
                 IconButton(
                  onPressed: () => _showLoginDialog(context),
                  icon: Icon(Icons.login, color: Theme.of(context).primaryColor),
                  tooltip: "Login",
                 )
              ]
            ],
          ),
        ],
      ),
    );
  }
}

// Quick Access Card Widget for Login Dialog
class _QuickAccessCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAccessCard({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.exo2(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _HeroSection extends StatelessWidget {
  final bool isDesktop;
  const _HeroSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 60.0 : 30.0),
      child: Column(
        crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: theme.primaryColor.withOpacity(0.5)),
            ),
            child: Text(
              'SYSTEM ONLINE',
              style: GoogleFonts.shareTechMono(
                color: theme.primaryColor,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'CAMPUS\nINTELLIGENCE',
            textAlign: isDesktop ? TextAlign.start : TextAlign.center,
            style: GoogleFonts.orbitron(
              fontSize: isDesktop ? 60 : 36, // Reduced font size to prevent overflow
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: theme.colorScheme.onBackground,
              shadows: [
                Shadow(color: theme.primaryColor.withOpacity(0.6), blurRadius: 20),
              ],
            ),

          ),
          const SizedBox(height: 24),
          Text(
            'The next-generation operating system for educational institutions. Automated. Integrated. Intelligent.',
            textAlign: isDesktop ? TextAlign.start : TextAlign.center,
            style: GoogleFonts.exo2(
              fontSize: 18,
              color: theme.colorScheme.onBackground.withOpacity(0.8),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
            children: [
              _FeatureChip(icon: Icons.analytics_outlined, label: 'Analytics'),
              _FeatureChip(icon: Icons.hub_outlined, label: 'IoT Core'),
              _FeatureChip(icon: Icons.psychology_outlined, label: 'AI Engine'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// A simple widget that draws some animated tech circles instead of a 3D model
class _TechnoVisualizer extends StatefulWidget {
  const _TechnoVisualizer();

  @override
  State<_TechnoVisualizer> createState() => _TechnoVisualizerState();
}

class _TechnoVisualizerState extends State<_TechnoVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final secondary = Theme.of(context).colorScheme.secondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure we have a non-zero size. If unbound, default to 300x300.
        double width = constraints.maxWidth.isFinite ? constraints.maxWidth : 300;
        double height = constraints.maxHeight.isFinite ? constraints.maxHeight : 300;
        if (height == 0) height = 300; 

        return SizedBox(
          width: width,
          height: height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(width, height),
                painter: _TechCirclePainter(
                  animationValue: _controller.value,
                  primary: primary,
                  secondary: secondary,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _TechCirclePainter extends CustomPainter {
  final double animationValue;
  final Color primary;
  final Color secondary;

  _TechCirclePainter({
    required this.animationValue,
    required this.primary,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Ensure radius is visible even if size is weird
    final maxRadius = math.min(size.width, size.height) / 2 * 0.8; 
    
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) { // Increased rings
      double radius = maxRadius * (0.3 + i * 0.2);
      if (radius <= 0) radius = 10; // Fallback

      double rotation = animationValue * 2 * math.pi * (i % 2 == 0 ? 1 : -1) + (i * math.pi / 4);
      
      paint.color = i % 2 == 0 ? primary.withOpacity(0.6) : secondary.withOpacity(0.6);
      
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      
      // Draw Arcs
      Rect rect = Rect.fromCircle(center: Offset.zero, radius: radius);
      canvas.drawArc(rect, 0, math.pi / 1.5, false, paint);
      
      // Draw Orbital Dots
      Paint dotPaint = Paint()..style = PaintingStyle.fill..color = paint.color;
      canvas.drawCircle(
        Offset(radius * math.cos(0), radius * math.sin(0)), 
        6, 
        dotPaint
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TechnoBackground extends StatelessWidget {
  const _TechnoBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: CustomPaint(
        painter: _GridPainter(
          color: Theme.of(context).primaryColor.withOpacity(0.1), // Increased opacity
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
        ),
        child: Container(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final bool isDarkMode;
  _GridPainter({required this.color, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    final dotPaint = Paint()..color = color.withOpacity(isDarkMode ? 0.3 : 0.5)..style = PaintingStyle.fill;
    
    const spacing = 30.0; // Tighter grid

    // Draw Grid
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw Dots Pattern (The "Pattern" user misses)
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
         if ((x + y) % (spacing * 2) == 0) { // Checkered pattern of dots
            canvas.drawCircle(Offset(x + spacing/2, y + spacing/2), 1.5, dotPaint);
         }
      }
    }
  }
  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

