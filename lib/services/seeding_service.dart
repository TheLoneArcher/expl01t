import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SeedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedFromJson(Map<String, dynamic> data) async {
    // 1. Users
    final batch = _firestore.batch();
    final usersRef = _firestore.collection('users');
    
    for (var u in (data['students'] as List)) {
      final userMap = Map<String, dynamic>.from(u);
      batch.set(usersRef.doc(userMap['uid']), userMap);
    }
    for (var u in (data['instructors'] as List)) {
       final userMap = Map<String, dynamic>.from(u);
       batch.set(usersRef.doc(userMap['uid']), userMap);
    }
    await batch.commit();
    print("   -> Users Uploaded");

    // 2. Subjects (Top-level for SyllabusTab)
    final subBatch = _firestore.batch();
    final subRef = _firestore.collection('subjects');
    for (var s in (data['subjects'] as List)) {
      final subMap = Map<String, dynamic>.from(s);
      subBatch.set(subRef.doc(subMap['name']), subMap);
    }
    await subBatch.commit();
    print("   -> Subjects Uploaded");

    // 2.1 Meetings (Top-level for InstructorHomeView)
    if (data['meetings'] != null) {
      final meetBatch = _firestore.batch();
      final meetRef = _firestore.collection('meetings');
      for (var m in (data['meetings'] as List)) {
        final meetMap = Map<String, dynamic>.from(m);
        meetBatch.set(meetRef.doc(), {
          ...meetMap,
          'time': Timestamp.fromDate(DateTime.parse(meetMap['time'])),
        });
      }
      await meetBatch.commit();
      print("   -> Meetings Uploaded");
    }

    // 3. Timetable
    final ttBatch = _firestore.batch();
    final ttMap = Map<String, dynamic>.from(data['timetable']);
    ttMap.forEach((day, schedule) {
      ttBatch.set(_firestore.collection('classes').doc('BTECH_3').collection('timetable').doc(day), Map<String, dynamic>.from(schedule));
    });
    await ttBatch.commit();
    print("   -> Timetable Uploaded");

    // 4. Exams
    final examBatch = _firestore.batch();
    for (var e in (data['exams'] as List)) {
       final examMap = Map<String, dynamic>.from(e);
       final examRef = _firestore.collection('classes').doc('BTECH_3').collection('exams').doc(examMap['name']);
       examBatch.set(examRef, {
         'name': examMap['name'],
         'date': Timestamp.fromDate(DateTime.parse(examMap['date'])),
         'totalMarks': examMap['total']
       });
       
       if (examMap['isCompleted'] == true) {
         for (var u in (data['students'] as List)) {
            final student = Map<String, dynamic>.from(u);
            Map<String, int> marks = {};
            for (var s in (data['subjects'] as List)) {
              final sub = Map<String, dynamic>.from(s);
              marks[sub['name']] = 20; // Default pass
            }
            await _firestore.collection('users').doc(student['uid']).collection('marks').doc(examMap['name']).set({
              ...marks, 'examId': examMap['name']
            });
         }
       }
    }
    await examBatch.commit();
    print("   -> Exams Uploaded");

    // 5. Events & Attendance (Reuse existing logic or simplified)
    await _seedEvents(); 
    await _seedAcademicData(); 
    print("   -> Events & Attendance Generated");
  }

  Future<void> seedDatabase() async {

    try {
      if (kDebugMode) {
        print("Starting Database Seeding...");
      }

      await _seedUsers();
      await _seedSubjects();
      await _seedTimetable();
      await _seedEvents();
      await _seedMeetings();
      await _seedAcademicData(); // Attendance, Homework, Exams, Marks

      if (kDebugMode) {
        print("Database Seeding Completed Successfully.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error seeding database: $e");
      }
      rethrow;
    }
  }

  Future<void> _seedUsers() async {
    final batch = _firestore.batch();
    final usersRef = _firestore.collection('users');

    // 5 Students
    for (int i = 1; i <= 5; i++) {
      String rollNo = "23AK1A36${i.toString().padLeft(2, '0')}";
      batch.set(usersRef.doc(rollNo), {
        'uid': rollNo,
        'role': 'student',
        'name': 'Student $i',
        'password': rollNo, // As requested
        'classId': 'BTECH_3', 
        'email': '$rollNo@campx.edu',
      });
    }

    // 2 Instructors
    for (int i = 1; i <= 2; i++) {
      String empId = "INSTR${i.toString().padLeft(2, '0')}";
      batch.set(usersRef.doc(empId), {
        'uid': empId,
        'role': 'instructor',
        'name': 'Instructor $i',
        'password': empId, // As requested
        'email': '$empId@campx.edu',
      });
    }

    await batch.commit();
  }

  Future<void> _seedSubjects() async {
    final subjects = [
      {
        'name': 'Machine Learning', 
        'code': 'ML', 
        'topics': [
          {'name': 'Supervised Learning', 'status': 'covered'},
          {'name': 'Unsupervised Learning', 'status': 'pending'},
          {'name': 'Neural Networks', 'status': 'pending'},
          {'name': 'SVM', 'status': 'pending'},
        ]
      },
      {
        'name': 'English', 
        'code': 'ENG', 
        'topics': [
          {'name': 'Communication Skills', 'status': 'covered'},
          {'name': 'Professional Writing', 'status': 'covered'},
          {'name': 'Grammar & Vocab', 'status': 'pending'},
        ]
      },
      {
        'name': 'Blockchain', 
        'code': 'BLK', 
        'topics': [
          {'name': 'Cryptography', 'status': 'covered'},
          {'name': 'Consensus', 'status': 'covered'},
          {'name': 'Ethereum', 'status': 'pending'},
        ]
      },
      {
        'name': 'Cyber Security', 
        'code': 'CYB', 
        'topics': [
          {'name': 'Network Security', 'status': 'covered'},
          {'name': 'Malware Analysis', 'status': 'pending'},
          {'name': 'Web Security', 'status': 'pending'},
        ]
      },
      {
        'name': 'Databases', 
        'code': 'DB', 
        'topics': [
          {'name': 'SQL Basics', 'status': 'covered'},
          {'name': 'Normalization', 'status': 'pending'},
          {'name': 'NoSQL Intro', 'status': 'pending'},
        ]
      },
       {
        'name': 'Python', 
        'code': 'PY', 
        'topics': [
          {'name': 'Data Types', 'status': 'covered'},
          {'name': 'Functions & Modules', 'status': 'pending'},
          {'name': 'Pandas & NumPy', 'status': 'pending'},
        ]
      },
    ];
    final batch = _firestore.batch();
    final subRef = _firestore.collection('subjects'); 

    for (var sub in subjects) {
      batch.set(subRef.doc(sub['name'] as String), sub);
    }
    await batch.commit();
  }

  Future<void> _seedMeetings() async {
    final meetings = [
      {
        'title': 'Faculty Board Meeting',
        'time': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 2))),
        'type': 'Online (Zoom)',
        'link': 'https://zoom.us/j/campx_fac_123',
      },
      {
        'title': 'Syllabus Review: ML',
        'time': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1, hours: 3))),
        'type': 'Offline (Conf. Room A)',
        'link': null,
      },
      {
         'title': 'Parent Teacher Meet',
         'time': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
         'type': 'Online (GMeet)',
         'link': 'https://meet.google.com/xyz-abc-123',
      }
    ];

    final batch = _firestore.batch();
    final meetRef = _firestore.collection('meetings');

    for (var m in meetings) {
      batch.set(meetRef.doc(), m);
    }
    await batch.commit();
  }


  Future<void> _seedTimetable() async {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    final subjects = ['Machine Learning', 'English', 'Blockchain', 'Cyber Security', 'Databases', 'Python'];
    final batch = _firestore.batch();
    
    // Simple mock timetable: 5 periods per day, cycling through subjects
    int subIndex = 0;
    
    for (var day in days) {
      Map<String, String> daySchedule = {};
      for (int period = 1; period <= 5; period++) {
        daySchedule['p$period'] = subjects[subIndex % subjects.length];
        subIndex++;
      }
      
      batch.set(
        _firestore.collection('classes').doc('BTECH_3').collection('timetable').doc(day),
        daySchedule,
      );
    }
    await batch.commit();
  }

  Future<void> _seedEvents() async {
    final batch = _firestore.batch();
    final eventsRef = _firestore.collection('events');

    // Generate random events from April 2025 to May 2026
    DateTime startDate = DateTime(2025, 4, 1);
    DateTime endDate = DateTime(2026, 5, 30);
    int eventCount = 10;

    for (int i = 0; i < eventCount; i++) {
      int daysToAdd = (i * (endDate.difference(startDate).inDays / eventCount)).round();
       DateTime eventDate = startDate.add(Duration(days: daysToAdd));
       String eventId = 'evt_$i';
       
       batch.set(eventsRef.doc(eventId), {
         'title': 'Event $i: Tech Symposium',
         'date': Timestamp.fromDate(eventDate),
         'description': 'A generic event for the campus.',
         'location': 'Auditorium'
       });
    }
    await batch.commit();
  }

  Future<void> _seedAcademicData() async {
    // Exams Schedule
    // 4 Quarterlies (30 marks)
    // Half Year
    // Prefinal (April)
    // Final (May)
    
    final exams = [
      {'name': 'Quarterly 1', 'date': DateTime(2025, 8, 15), 'total': 30, 'isCompleted': true},
      {'name': 'Quarterly 2', 'date': DateTime(2025, 10, 15), 'total': 30, 'isCompleted': true},
      {'name': 'Half Yearly', 'date': DateTime(2025, 12, 10), 'total': 100, 'isCompleted': true},
      {'name': 'Quarterly 3', 'date': DateTime(2026, 2, 10), 'total': 30, 'isCompleted': true},
      // Future/Current
      {'name': 'Quarterly 4', 'date': DateTime(2026, 3, 20), 'total': 30, 'isCompleted': false},

      {'name': 'Prefinal', 'date': DateTime(2026, 4, 10), 'total': 100, 'isCompleted': false},
      {'name': 'Final', 'date': DateTime(2026, 5, 5), 'total': 100, 'isCompleted': false},
    ];

    final subjects = ['Machine Learning', 'English', 'Blockchain', 'Cyber Security', 'Databases', 'Python'];
    
    // Seed Exams
    for (var exam in exams) {
      await _firestore.collection('classes').doc('BTECH_3').collection('exams').doc(exam['name'] as String).set({
        'name': exam['name'],
        'date': Timestamp.fromDate(exam['date'] as DateTime),
        'totalMarks': exam['total'],
      });
      
      // If completed, seed marks for students
      if (exam['isCompleted'] as bool) {
         for (int i = 1; i <= 5; i++) {
            String rollNo = "23AK1A36${i.toString().padLeft(2, '0')}";
            Map<String, int> studentMarks = {};
            for (var sub in subjects) {
              // Random passing marks
              studentMarks[sub] = 15 + (DateTime.now().millisecond % ((exam['total'] as int) - 15)); 
            }
            
            await _firestore.collection('users').doc(rollNo).collection('marks').doc(exam['name'] as String).set({
              ...studentMarks,
              'examId': exam['name'],
            });
         }
      }
    }

    // Homework & Attendance (Daily until Jan 30, 2026)
    // Academic year starts April 2025 as requested
    DateTime cursor = DateTime(2025, 4, 1);

    DateTime cutoff = DateTime(2026, 1, 30);
    
    // To avoid hitting write limits in a single go, we might process in larger chunks or just simplistic batching
    // For 5 students * ~200 days = 1000 attendance records per student -> 5000 writes. This is a lot.
    // Optimization: Store attendance as one doc per month per student or just skip broad history seeding if not strictly needed.
    // Request says: "attendance for all students for each period every day until January 30"
    // I will optimize by doing "Attendance Summary" or just last 30 days to be safe on quota, 
    // OR just use a simpler document structure: /attendance/{date}/{classId}/{rollNo}: status
    
    // Let's do a simplified approach: Only weekdays.
    // Batching carefully.
    
    WriteBatch batch = _firestore.batch();
    int batchCount = 0;
    
    while (cursor.isBefore(cutoff)) {
      if (cursor.weekday <= 5) { // Mon-Fri
        String dateStr = "${cursor.year}-${cursor.month.toString().padLeft(2,'0')}-${cursor.day.toString().padLeft(2,'0')}";
        
        // 1. Homework (Assigned every day)
        // Pick a random subject
        String subject = subjects[cursor.day % subjects.length];
        DocumentReference hwRef = _firestore.collection('classes').doc('BTECH_3').collection('homework').doc(dateStr);
        batch.set(hwRef, {
            'date': Timestamp.fromDate(cursor),
            'subject': subject,
            'description': 'Chapter review and exercises for $subject',
            'assignedBy': 'INSTR01'
        });

        // 2. Attendance (All students, present)
        for (int i = 1; i <= 5; i++) {
           String rollNo = "23AK1A36${i.toString().padLeft(2, '0')}";
           // 5 periods
           Map<String, String> periodStatus = {
             'p1': 'P', 'p2': 'P', 'p3': 'P', 'p4': 'P', 'p5': 'P'
           };
           // Randomly absent
           if ((cursor.day + i) % 15 == 0) periodStatus['p1'] = 'A';
           
           DocumentReference attRef = _firestore.collection('users').doc(rollNo).collection('attendance').doc(dateStr);
           batch.set(attRef, periodStatus);
        }

        batchCount += (2 + 5); // 1 HW + 5 Students
        if (batchCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    if (batchCount > 0) await batch.commit();
  }
}
