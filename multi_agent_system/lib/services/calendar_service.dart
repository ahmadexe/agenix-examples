import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:multi_agent_system/services/firebase_service.dart';

class CalendarService {
  Future<void> bookEvent(String content, DateTime date) async {
    final calendarApi = FirebaseService.getCalendarApi();

    final event =
        calendar.Event()
          ..summary = content
          ..start = calendar.EventDateTime(
            dateTime: date,
            timeZone: 'Asia/Karachi',
          )
          ..end = calendar.EventDateTime(
            dateTime: date.add(const Duration(hours: 1)),
            timeZone: 'Asia/Karachi',
          );

    await calendarApi.events.insert(event, 'primary');
    debugPrint('✅ Event added to calendar');
  }
}
