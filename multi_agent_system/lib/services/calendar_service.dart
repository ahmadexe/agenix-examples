import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:multi_agent_system/services/firebase_service.dart';

class CalendarService {
  Future<void> bookEvent() async {
    final calendarApi = FirebaseService.getCalendarApi();

    final now = DateTime.now();
    final event =
        calendar.Event()
          ..summary = 'Agentic Demo Meeting'
          ..start = calendar.EventDateTime(
            dateTime: now.add(const Duration(hours: 1)),
            timeZone: 'Asia/Karachi',
          )
          ..end = calendar.EventDateTime(
            dateTime: now.add(const Duration(hours: 2)),
            timeZone: 'Asia/Karachi',
          );

    await calendarApi.events.insert(event, 'primary');
    debugPrint('✅ Event added to calendar');
  }
}
