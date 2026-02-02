import 'package:cloud_firestore/cloud_firestore.dart';

class InstructorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final InstructorService _instance = InstructorService._internal();
  factory InstructorService() => _instance;
  InstructorService._internal();

  // Create a new event
  Future<Map<String, dynamic>> addEvent({
    required String title,
    required DateTime date,
    required String description,
    String? location,
  }) async {
    try {
      await _firestore.collection('events').add({
        'title': title,
        'date': Timestamp.fromDate(date),
        'description': description,
        'location': location ?? 'TBA',
      });
      return {'success': true, 'message': 'Event created successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create event: $e'};
    }
  }

  // Update an existing event
  Future<Map<String, dynamic>> updateEvent({
    required String eventId,
    required String title,
    required DateTime date,
    required String description,
    String? location,
  }) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'title': title,
        'date': Timestamp.fromDate(date),
        'description': description,
        'location': location ?? 'TBA',
      });
      return {'success': true, 'message': 'Event updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update event: $e'};
    }
  }

  // Delete an event
  Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      return {'success': true, 'message': 'Event deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete event: $e'};
    }
  }

  // Add a new exam
  Future<Map<String, dynamic>> addExam({
    required String classId,
    required String name,
    required DateTime date,
    required int totalMarks,
  }) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('exams')
          .doc(name)
          .set({
        'name': name,
        'date': Timestamp.fromDate(date),
        'totalMarks': totalMarks,
      });
      return {'success': true, 'message': 'Exam added successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add exam: $e'};
    }
  }

  // Update an existing exam
  Future<Map<String, dynamic>> updateExam({
    required String classId,
    required String oldName,
    required String newName,
    required DateTime date,
    required int totalMarks,
  }) async {
    try {
      final batch = _firestore.batch();
      final oldDoc = _firestore.collection('classes').doc(classId).collection('exams').doc(oldName);
      final newDoc = _firestore.collection('classes').doc(classId).collection('exams').doc(newName);

      if (oldName != newName) {
        batch.delete(oldDoc);
      }

      batch.set(newDoc, {
        'name': newName,
        'date': Timestamp.fromDate(date),
        'totalMarks': totalMarks,
      });

      await batch.commit();
      return {'success': true, 'message': 'Exam updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update exam: $e'};
    }
  }

  // Delete an exam
  Future<Map<String, dynamic>> deleteExam({
    required String classId,
    required String examName,
  }) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('exams')
          .doc(examName)
          .delete();
      return {'success': true, 'message': 'Exam deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete exam: $e'};
    }
  }

  // Update an announcement
  Future<Map<String, dynamic>> updateAnnouncement({
    required String announcementId,
    required String title,
    required String content,
  }) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'title': title,
        'content': content,
      });
      return {'success': true, 'message': 'Announcement updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update announcement: $e'};
    }
  }

  // Delete an announcement
  Future<Map<String, dynamic>> deleteAnnouncement(String announcementId) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).delete();
      return {'success': true, 'message': 'Announcement deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete announcement: $e'};
    }
  }

  // Assign marks to a student
  Future<Map<String, dynamic>> assignMarks({
    required String uid,
    required String examId,
    required Map<String, int> marks,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('marks')
          .doc(examId)
          .set({
        ...marks,
        'examId': examId,
      });
      return {'success': true, 'message': 'Marks assigned successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to assign marks: $e'};
    }
  }

  // Assign homework to a class
  Future<Map<String, dynamic>> assignHomework({
    required String classId,
    required String subject,
    required String description,
    required DateTime date,
    required String instructorName,
  }) async {
    try {
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('homework')
          .doc(dateStr)
          .set({
        'subject': subject,
        'description': description,
        'date': Timestamp.fromDate(date),
        'assignedBy': instructorName,
      });
      return {'success': true, 'message': 'Homework assigned successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to assign homework: $e'};
    }
  }

  // Delete homework
  Future<Map<String, dynamic>> deleteHomework({
    required String classId,
    required String dateStr,
  }) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('homework')
          .doc(dateStr)
          .delete();
      return {'success': true, 'message': 'Homework deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete homework: $e'};
    }
  }

  // Assign/Update Attendance
  Future<Map<String, dynamic>> updateAttendance({
    required String uid,
    required DateTime date,
    required Map<String, String> periodStatus,
  }) async {
    try {
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('attendance')
          .doc(dateStr)
          .set(periodStatus);
      return {'success': true, 'message': 'Attendance updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update attendance: $e'};
    }
  }

  // --- STATS CALCULATION (Dynamic) ---

  // Fetch Attendance Percentage for a student
  Stream<double> getAttendancePercentage(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return 0.0;
      int totalPeriods = 0;
      int presentPeriods = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data.forEach((key, value) {
          if (key.startsWith('p')) {
            totalPeriods++;
            if (value == 'P' || value == 'L') presentPeriods++;
          }
        });
      }
      if (totalPeriods == 0) return 0.0;
      return (presentPeriods / totalPeriods) * 100;
    });
  }

  // Fetch Marks Average Percentage for a student
  Stream<double> getMarksAverage(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('marks')
        .snapshots()
        .asyncMap((marksSnapshot) async {
      if (marksSnapshot.docs.isEmpty) return 0.0;

      // Fetch Exam Metadata to get correct totalMarks for each exam
      final examsSnapshot = await _firestore.collection('classes').doc('BTECH_3').collection('exams').get();
      final Map<String, int> examTotals = {
        for (var doc in examsSnapshot.docs) doc.id : (doc.data()['totalMarks'] ?? 100) as int
      };

      double totalPercentageSum = 0;
      int subjectCount = 0;

      for (var doc in marksSnapshot.docs) {
        final data = doc.data();
        final examId = doc.id;
        final totalMax = examTotals[examId] ?? 100;

        data.forEach((key, value) {
          if (key != 'examId' && value is num) {
            totalPercentageSum += (value / totalMax) * 100;
            subjectCount++;
          }
        });
      }

      if (subjectCount == 0) return 0.0;
      return totalPercentageSum / subjectCount;
    });
  }
}
