import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:camp_x/services/seeding_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

// Standalone runner for database seeding
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print("\n=============================================");
  print("   CAMPX DATABASE SEEDER - CLI MODE");
  print("=============================================\n");

  try {
    // 1. Initialize Firebase
    print(">> Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print(">> Firebase Initialized!");

    // 2. Load JSON Data
    print(">> Loading data from assets/data/campx_data.json...");
    // We need to run runApp to get a context for AssetBundle? No, rootBundle works.
    // However, rootBundle needs the Flutter engine running. 'flutter run' provides this.
    
    final jsonString = await rootBundle.loadString('assets/data/campx_data.json');
    final data = json.decode(jsonString);
    print(">> Data Loaded successfully.");

    // 3. Inject Data via SeedingService (Modified to accept data)
    print(">> Starting Upload to Firestore... (This may take a moment)");
    
    final seeder = SeedingService();
    await seeder.seedFromJson(data);

    print("\n=============================================");
    print("   ✅ SUCCESS: DATABASE SEEDED FROM JSON!");
    print("=============================================\n");

  } catch (e) {
    print("\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    print("   ❌ ERROR: $e");
    print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
  } finally {
    print("Process Complete. You can press 'q' to quit.");
  }


  
  // Minimal UI to keep engine alive while processing
  runApp(const MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: Text("Seeding Database... Check Console.", style: TextStyle(color: Colors.green, fontSize: 24))),
    ),
  ));
}
