import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleCalendarService {
  static final GoogleCalendarService _instance = GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '891565212850-shda268or0qmnmvpdi52c3408d0ml9ic.apps.googleusercontent.com',
    scopes: [
      calendar.CalendarApi.calendarScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  calendar.CalendarApi? _calendarApi;

  // Check if Google Calendar is linked
  Future<bool> isLinked() async {
    final prefs = await SharedPreferences.getInstance();
    final isLinked = prefs.getBool('google_calendar_linked') ?? false;
    
    if (isLinked) {
      // Try to sign in silently
      try {
        _currentUser = await _googleSignIn.signInSilently();
        if (_currentUser != null) {
          await _initializeCalendarApi();
          return true;
        }
      } catch (e) {
        // Silent sign-in failed, user needs to sign in manually
      }
    }
    
    return false;
  }

  // Get linked Google account email
  String? getLinkedEmail() {
    return _currentUser?.email;
  }

  // Link Google Calendar
  Future<Map<String, dynamic>> linkGoogleCalendar() async {
    try {
      // Sign in with Google
      _currentUser = await _googleSignIn.signIn();
      
      if (_currentUser == null) {
        return {
          'success': false,
          'message': 'Sign-in cancelled',
        };
      }

      // Initialize Calendar API
      await _initializeCalendarApi();

      // Save link status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('google_calendar_linked', true);
      await prefs.setString('google_calendar_email', _currentUser!.email);

      return {
        'success': true,
        'message': 'Google Calendar linked successfully!',
        'email': _currentUser!.email,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to link Google Calendar: ${e.toString()}',
      };
    }
  }

  // Initialize Calendar API
  Future<void> _initializeCalendarApi() async {
    try {
      final auth.AuthClient? client = await _googleSignIn.authenticatedClient();
      if (client != null) {
        _calendarApi = calendar.CalendarApi(client);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Unlink Google Calendar
  Future<Map<String, dynamic>> unlinkGoogleCalendar() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _calendarApi = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('google_calendar_linked');
      await prefs.remove('google_calendar_email');
      await prefs.remove('last_sync_time');

      return {
        'success': true,
        'message': 'Google Calendar unlinked successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to unlink: ${e.toString()}',
      };
    }
  }

  // Sync exams to Google Calendar
  Future<Map<String, dynamic>> syncExamsToCalendar(List<Map<String, dynamic>> exams) async {
    if (_calendarApi == null) {
      return {
        'success': false,
        'message': 'Google Calendar not linked',
      };
    }

    try {
      int syncedCount = 0;
      
      for (var exam in exams) {
        final examName = exam['name'] as String;
        final examDate = (exam['date'] as DateTime);
        
        // Check if event already exists
        final existingEvents = await _calendarApi!.events.list(
          'primary',
          q: 'CampX: $examName',
          timeMin: examDate.subtract(const Duration(days: 1)),
          timeMax: examDate.add(const Duration(days: 1)),
        );

        if (existingEvents.items?.isEmpty ?? true) {
          // Create new event as all-day event
          // Create a DateTime at midnight for the exam date
          final eventStart = DateTime(examDate.year, examDate.month, examDate.day);
          
          final event = calendar.Event()
            ..summary = 'CampX: $examName'
            ..description = 'Exam from CampX app\nTotal Marks: ${exam['totalMarks'] ?? exam['total'] ?? 'N/A'}'
            ..start = (calendar.EventDateTime()..date = eventStart)
            ..end = (calendar.EventDateTime()..date = eventStart)
            ..colorId = '11'; // Red color for exams

          await _calendarApi!.events.insert(event, 'primary');
          syncedCount++;
        }
      }

      // Save sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', DateTime.now().toIso8601String());

      return {
        'success': true,
        'message': syncedCount > 0 
            ? 'Synced $syncedCount exam(s) to Google Calendar'
            : 'All exams already synced',
        'count': syncedCount,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to sync exams: ${e.toString()}',
      };
    }
  }

  // Sync events to Google Calendar
  Future<Map<String, dynamic>> syncEventsToCalendar(List<Map<String, dynamic>> events) async {
    if (_calendarApi == null) {
      return {
        'success': false,
        'message': 'Google Calendar not linked',
      };
    }

    try {
      int syncedCount = 0;
      
      for (var event in events) {
        final eventTitle = event['title'] as String;
        final eventDate = (event['date'] as DateTime);
        
        // Check if event already exists
        final existingEvents = await _calendarApi!.events.list(
          'primary',
          q: 'CampX: $eventTitle',
          timeMin: eventDate.subtract(const Duration(days: 1)),
          timeMax: eventDate.add(const Duration(days: 1)),
        );

        if (existingEvents.items?.isEmpty ?? true) {
          // Create new event as all-day event
          // Create a DateTime at midnight for the event date
          final eventStart = DateTime(eventDate.year, eventDate.month, eventDate.day);
          
          final calEvent = calendar.Event()
            ..summary = 'CampX: $eventTitle'
            ..description = event['description'] ?? 'Event from CampX app'
            ..start = (calendar.EventDateTime()..date = eventStart)
            ..end = (calendar.EventDateTime()..date = eventStart)
            ..colorId = '9'; // Blue color for events

          await _calendarApi!.events.insert(calEvent, 'primary');
          syncedCount++;
        }
      }

      // Save sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', DateTime.now().toIso8601String());

      return {
        'success': true,
        'message': syncedCount > 0 
            ? 'Synced $syncedCount event(s) to Google Calendar'
            : 'All events already synced',
        'count': syncedCount,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to sync events: ${e.toString()}',
      };
    }
  }

  // Get last sync time
  Future<String?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_sync_time');
  }
}
