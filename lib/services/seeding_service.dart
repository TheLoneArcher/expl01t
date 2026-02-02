import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class SeedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Primary entry point for deep cleaning and re-seeding
  Future<void> seedDatabase() async {
    try {
      if (kDebugMode) print("Starting ULTIMATE Database Reconstruction...");

      // 1. GLOBAL WIPE: Clean EVERY collection used in the app
      if (kDebugMode) print("   -> Performing ULTIMATE WIPE...");
      await _deleteAllDocuments(_firestore.collection('users'));
      await _deleteAllDocuments(_firestore.collection('subjects'));
      await _deleteAllDocuments(_firestore.collection('events'));
      await _deleteAllDocuments(_firestore.collection('meetings'));
      await _deleteAllDocuments(_firestore.collection('announcements'));
      
      // Clear class-level data
      final classRef = _firestore.collection('classes').doc('BTECH_3');
      await _deleteAllDocuments(classRef.collection('exams'));
      await _deleteAllDocuments(classRef.collection('homework'));
      await _deleteAllDocuments(classRef.collection('timetable'));

      // 2. WAIT for Firestore Consistency
      if (kDebugMode) print("   -> Waiting for consistency...");
      await Future.delayed(const Duration(seconds: 2));

      // 3. SEED USERS (5 Students, 2 Instructors)
      final studentList = await _seedUsers();

      // 4. SEED METADATA (Subjects, Timetable, Meetings, Events, Announcements)
      await _seedSubjects();
      await _seedTimetable();
      await _seedMeetings();
      await _seedEvents();
      await _seedAnnouncements();

      // 5. SEED ACADEMIC DATA (Exams, Marks, Attendance, Homework)
      await _seedAcademicData(students: studentList);

      if (kDebugMode) {
        print("--------------------------------------------------");
        print("ULTIMATE RECONSTRUCTION COMPLETED SUCCESSFULLY");
        print("--------------------------------------------------");
      }
    } catch (e) {
      if (kDebugMode) print("FATAL ERROR DURING SEEDING: $e");
      rethrow;
    }
  }

  Future<void> seedVariedAttendance() async {
    // Exact 5 Student IDs
    final List<String> studentUids = [
      '23AK1A3601', '23AK1A3602', '23AK1A3603', '23AK1A3604', '23AK1A3605'
    ];
    
    // Profiles matching requirement
    final List<String> profiles = ['topper', 'topper', 'average', 'average', 'struggler'];
    final Random r = Random();

    try {
      if (kDebugMode) print("🚀 Beginning randomization logic...");

      for (int i = 0; i < studentUids.length; i++) {
        final String uid = studentUids[i];
        final String profile = profiles[i];
        
        DateTime cursor = DateTime(2026, 1, 1);
        DateTime now = DateTime.now();
        WriteBatch batch = _firestore.batch();
        int opCount = 0;

        if (kDebugMode) print("   -> Processing $uid ($profile)");

        while (cursor.isBefore(now)) {
          if (cursor.weekday <= 5) { // Mon-Fri
            String dateStr = "${cursor.year}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}";
            
            // Get randomized period statuses based on student profile
            Map<String, String> dayStatus = _generatePattern(profile, r);

            final docRef = _firestore
                .collection('users')
                .doc(uid)
                .collection('attendance')
                .doc(dateStr);

            batch.set(docRef, {
              ...dayStatus,
              'date': Timestamp.fromDate(cursor),
              'status': dayStatus.values.contains('A') ? 'Partial' : 'Present',
            }, SetOptions(merge: true));

            opCount++;
          }

          // Commit every 400 operations to respect Firestore limits
          if (opCount >= 400) {
            await batch.commit();
            batch = _firestore.batch();
            opCount = 0;
          }
          cursor = cursor.add(const Duration(days: 1));
        }
        await batch.commit(); // Final student commit
      }
      if (kDebugMode) print("✅ Success: Attendance patterns varied.");
    } catch (e) {
      if (kDebugMode) print("❌ Error during randomization: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _seedUsers() async {
    if (kDebugMode) print("   -> Seeding Users...");
    
    final batch = _firestore.batch();
    final usersRef = _firestore.collection('users');
    final List<Map<String, dynamic>> createdStudents = [];

    // EXACTLY 5 Students (3601 to 3605)
    final profiles = ['topper', 'topper', 'average', 'average', 'struggler'];
    for (int i = 1; i <= 5; i++) {
      String rollNo = "23AK1A360$i";
      final studentData = {
        'uid': rollNo,
        'role': 'student',
        'name': 'Student $i',
        'password': rollNo,
        'classId': 'BTECH_3', 
        'email': '$rollNo@campx.edu',
        'profile': profiles[i - 1],
      };
      batch.set(usersRef.doc(rollNo), studentData);
      createdStudents.add(studentData);
    }

    // EXACTLY 2 Instructors (INSTR01, INSTR02)
    for (int i = 1; i <= 2; i++) {
      String empId = "INSTR0$i";
      batch.set(usersRef.doc(empId), {
        'uid': empId,
        'role': 'instructor',
        'name': 'Instructor $i',
        'password': empId,
        'email': '$empId@campx.edu',
      });
    }

    await batch.commit();
    if (kDebugMode) print("   -> Created 5 Students and 2 Instructors.");
    return createdStudents;
  }

  Future<void> _seedAcademicData({required List<Map<String, dynamic>> students}) async {
    final List<String> subjects = ['Advanced Mathematics', 'Physics', 'Computer Science', 'Literature & Rhetoric', 'World History'];
    final examsList = [
      {'name': 'Quarterly 1', 'date': Timestamp.fromDate(DateTime(2025, 9, 15)), 'total': 50},
      {'name': 'Mid Terms', 'date': Timestamp.fromDate(DateTime(2025, 12, 10)), 'total': 100},
      {'name': 'Quarterly 2', 'date': Timestamp.fromDate(DateTime(2026, 2, 20)), 'total': 50},
      {'name': 'Finals', 'date': Timestamp.fromDate(DateTime(2026, 4, 15)), 'total': 100},
    ];

    final classDoc = _firestore.collection('classes').doc('BTECH_3');
    final r = Random();
    int range(int min, int max) => min + r.nextInt(max - min + 1);

    // 1. Seed Exams to Class
    WriteBatch examBatch = _firestore.batch();
    for (var exam in examsList) {
      examBatch.set(classDoc.collection('exams').doc(exam['name'] as String), {
        'name': exam['name'],
        'date': exam['date'],
        'totalMarks': exam['total'],
      });
    }
    await examBatch.commit();

    // 2. Seed Marks & Attendance per Student
    for (var student in students) {
      final uid = student['uid'];
      final profile = student['profile'];
      if (kDebugMode) print("      * Seeding marks/attendance for $uid");

      final studentMarksBatch = _firestore.batch();
      for (var exam in examsList) {
        String examName = exam['name'] as String;
        int total = exam['total'] as int;
        Map<String, dynamic> marksData = {'examId': examName};
        
        for (var sub in subjects) {
          int score;
          if (profile == 'topper') {
            score = range((total * 0.88).round(), total);
          } else if (profile == 'struggler') {
            score = range((total * 0.35).round(), (total * 0.60).round());
          } else {
            score = range((total * 0.60).round(), (total * 0.88).round());
          }
          marksData[sub] = score;
        }
        studentMarksBatch.set(_firestore.collection('users').doc(uid).collection('marks').doc(examName), marksData);
      }
      await studentMarksBatch.commit();

      // Attendance (Jan 2026 to Now) with Randomization
      DateTime cursor = DateTime(2026, 1, 1);
      DateTime now = DateTime.now();
      WriteBatch attendanceBatch = _firestore.batch();
      int attCount = 0;

      while (cursor.isBefore(now)) {
        if (cursor.weekday <= 5) {
          String dateStr = "${cursor.year}-${cursor.month.toString().padLeft(2,'0')}-${cursor.day.toString().padLeft(2,'0')}";
          Map<String, String> dayStatus = _generatePattern(profile, r);

          attendanceBatch.set(_firestore.collection('users').doc(uid).collection('attendance').doc(dateStr), {
            ...dayStatus,
            'date': Timestamp.fromDate(cursor),
            'status': dayStatus.values.contains('A') ? 'Partial' : 'Present',
          });
          attCount++;
        }
        
        if (attCount >= 400) {
          await attendanceBatch.commit();
          attendanceBatch = _firestore.batch();
          attCount = 0;
        }
        cursor = cursor.add(const Duration(days: 1));
      }
      await attendanceBatch.commit();
    }

    // 3. Seed Shared Homework & Student Homework Status
    final hwBatch = _firestore.batch();
    DateTime hwCursor = DateTime(2026, 1, 1);
    while (hwCursor.isBefore(DateTime.now())) {
      if (hwCursor.weekday <= 5) {
        String dateStr = "${hwCursor.year}-${hwCursor.month.toString().padLeft(2,'0')}-${hwCursor.day.toString().padLeft(2,'0')}";
        
        // a. Class-level Shared Homework
        hwBatch.set(classDoc.collection('homework').doc(dateStr), {
          'date': Timestamp.fromDate(hwCursor),
          'subject': subjects[hwCursor.day % subjects.length],
          'description': 'Daily chapter review and exercises.',
          'dueDate': Timestamp.fromDate(hwCursor.add(const Duration(days: 2))),
          'assignedBy': 'INSTR01'
        });

        // b. Individual Student Status (Mark some as completed)
        for (var student in students) {
           final uid = student['uid'];
           bool isDone = (uid.hashCode + hwCursor.day) % 2 == 0;
           hwBatch.set(
             _firestore.collection('users').doc(uid).collection('homework_status').doc(dateStr),
             {'isCompleted': isDone}
           );
        }
      }
      hwCursor = hwCursor.add(const Duration(days: 1));
    }
    await hwBatch.commit();
    if (kDebugMode) print("   -> Homework seeded successfully.");
  }

  // --- Helper Methods ---

  Future<void> _seedSubjects() async {
    final subjects = ['Advanced Mathematics', 'Physics', 'Computer Science', 'Literature & Rhetoric', 'World History'];
    final batch = _firestore.batch();
    for (var name in subjects) {
      batch.set(_firestore.collection('subjects').doc(name), {
        'name': name,
        'code': name.substring(0, 3).toUpperCase(),
        'topics': [{'name': 'Introduction', 'status': 'covered'}]
      });
    }
    await batch.commit();
  }

  Future<void> _seedTimetable() async {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    final subjects = ['Advanced Mathematics', 'Physics', 'Computer Science', 'Literature & Rhetoric', 'World History'];
    final batch = _firestore.batch();
    for (var day in days) {
      batch.set(_firestore.collection('classes').doc('BTECH_3').collection('timetable').doc(day), {
        'p1': subjects[0], 'p2': subjects[1], 'p3': subjects[2], 'p4': subjects[3], 'p5': subjects[4]
      });
    }
    await batch.commit();
  }

  Future<void> _seedMeetings() async {
    final batch = _firestore.batch();
    batch.set(_firestore.collection('meetings').doc(), {
      'title': 'General Faculty Meet',
      'time': Timestamp.now(),
      'type': 'Online',
      'link': 'https://meet.google.com/campx'
    });
    await batch.commit();
  }

  Future<void> _seedEvents() async {
    final batch = _firestore.batch();
    batch.set(_firestore.collection('events').doc(), {
      'title': 'Campus Tech Fest',
      'date': Timestamp.fromDate(DateTime(2026, 2, 15)),
      'description': 'Main auditorium event',
      'location': 'Block A auditorium'
    });
    batch.set(_firestore.collection('events').doc(), {
      'title': 'Final Exams Week',
      'date': Timestamp.fromDate(DateTime(2026, 4, 15)),
      'description': 'End of semester examinations',
      'location': 'Examination Wing'
    });
    await batch.commit();
  }

  Future<void> _seedAnnouncements() async {
    final batch = _firestore.batch();
    batch.set(_firestore.collection('announcements').doc(), {
      'title': 'Semester Fee Deadline',
      'content': 'Please ensure all dues are cleared by the end of this month.',
      'date': Timestamp.now(),
      'author': 'Accounting Dept'
    });
    batch.set(_firestore.collection('announcements').doc(), {
      'title': 'Library Hours Extended',
      'content': 'Library will remain open until midnight during exam week.',
      'date': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'author': 'Library Admin'
    });
    await batch.commit();
  }

  Future<void> _deleteAllDocuments(CollectionReference collection) async {
    final snapshot = await collection.get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Profile-based probability logic
  Map<String, String> _generatePattern(String profile, Random r) {
    Map<String, String> periods = {};
    double absenceChance;

    if (profile == 'topper') {
      absenceChance = 0.02;
    } else if (profile == 'struggler') {
      absenceChance = 0.22;
    } else {
      absenceChance = 0.07;
    }

    for (int p = 1; p <= 5; p++) {
      if (r.nextDouble() < absenceChance) {
        periods['p$p'] = 'A';
      } else if (r.nextDouble() < 0.05) {
        periods['p$p'] = 'L';
      } else {
        periods['p$p'] = 'P';
      }
    }
    return periods;
  }
}