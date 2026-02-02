import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camp_x/screens/landing_page.dart';
import 'package:camp_x/utils/theme_provider.dart';
import 'package:camp_x/utils/user_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'firebase_options.dart';



void main() async {
  // Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found or invalid. API keys may be missing.");
  }



  // Try to load Firebase but don't stop if it fails
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // print("Firebase initialized");
  } catch (e) {
    // print("Firebase error: $e");
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
