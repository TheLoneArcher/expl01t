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
  await dotenv.load(fileName: ".env");
  print("Techno Design Version 2.0 Loaded");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
