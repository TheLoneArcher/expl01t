import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camp_x/screens/landing_page.dart';
import 'package:camp_x/utils/theme_provider.dart';
import 'package:camp_x/utils/user_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Try to load .env, but don't crash if it's empty or missing
  try {
    await dotenv.load(fileName: ".env");
    print("Dotenv loaded successfully");
  } catch (e) {
    print("Note: .env file is empty or missing. Using compile-time variables.");
  }

  print("Techno Design Version 2.0 Loaded");

  // 2. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase initialization failed: $e");
  }

  runApp(const CampXApp());
}

class CampXApp extends StatelessWidget {
  const CampXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],

      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'CampX',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: const LandingPage(),
          );
        },
      ),
    );
  }
}
