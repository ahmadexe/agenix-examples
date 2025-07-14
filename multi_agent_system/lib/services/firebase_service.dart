import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FirebaseService {
  static final _auth = FirebaseAuth.instance;

  static const _scopes = [
    'email',
    gmail.GmailApi.gmailReadonlyScope,
    gmail.GmailApi.gmailSendScope,
    calendar.CalendarApi.calendarScope,
  ];

  static GoogleSignInAuthentication? _googleAuth;
  static http.Client? _httpClient;
  static AccessCredentials? _accessCredentials;
  static Future<void> init() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
        debugPrint("Dummy Firebase user signed in anonymously.");
      }
    } catch (e) {
      debugPrint('Firebase anonymous sign-in failed: $e');
    }
  }

  static Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn(scopes: _scopes).signIn();
    if (googleUser == null) throw Exception('Google sign-in aborted');

    _googleAuth = await googleUser.authentication;

    final accessToken = _googleAuth!.accessToken;
    final idToken = _googleAuth!.idToken;

    if (accessToken == null || idToken == null) {
      throw Exception('Failed to retrieve Google tokens');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );

    _httpClient = http.Client();
    _accessCredentials = AccessCredentials(
      AccessToken(
        'Bearer',
        accessToken,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      _scopes,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential;
  }

  static gmail.GmailApi getGmailApi() {
    if (_httpClient == null || _accessCredentials == null) {
      throw Exception("Gmail API not ready — Sign in first.");
    }
    final client = authenticatedClient(_httpClient!, _accessCredentials!);
    return gmail.GmailApi(client);
  }

  static calendar.CalendarApi getCalendarApi() {
    if (_httpClient == null || _accessCredentials == null) {
      throw Exception("Calendar API not ready — Sign in first.");
    }
    final client = authenticatedClient(_httpClient!, _accessCredentials!);
    return calendar.CalendarApi(client);
  }
}
