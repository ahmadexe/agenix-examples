import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;

import 'package:multi_agent_system/services/firebase_service.dart';

class EmailService {
  String encodeEmail({
    required String to,
    required String subject,
    required String body,
  }) {
    final message =
        'To: $to\n'
        'Subject: $subject\n'
        'Content-Type: text/plain; charset="UTF-8"\n\n'
        '$body';
    return base64Url.encode(utf8.encode(message)).replaceAll('=', '');
  }

  Future<void> sendEmail() async {
    final gmailApi = FirebaseService.getGmailApi();
    final raw = encodeEmail(
      to: 'muahmad710@gmail.com',
      subject: 'Agentic Flutter Test',
      body: 'Hello! This is an automated email using Gmail API.',
    );

    final message = gmail.Message()..raw = raw;
    await gmailApi.users.messages.send(message, 'me');
    debugPrint('✅ Email sent!');
  }
}
