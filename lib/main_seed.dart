// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:camp_x/services/seeding_service.dart';

void main() async {
  // 1. Initialize Flutter engine
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase Connected Successfully.");
  } catch (e) {
    print("❌ Firebase Init Error: $e");
    return;
  }

  print("--------------------------------------------------");
  print("STARTING ULTIMATE DATABASE SEEDING");
  print("--------------------------------------------------");

  // 3. Run the Service
  final seeder = SeedingService();
  
  try {
    await seeder.seedDatabase();
    print("--------------------------------------------------");
    print("🎯 PROCESS COMPLETE: Database is fully seeded.");
    print("--------------------------------------------------");
  } catch (e) {
    print("❌ FATAL ERROR: $e");
  }
}