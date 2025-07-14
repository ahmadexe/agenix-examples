import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;

  static Future<void> init() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      debugPrint("Dummy user authenticated");
    } catch (e) {
      debugPrint(
        'Error initializing Firebase (Failed while trying to authenticate dummy uesr): $e',
      );
    }
  }

  static Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'https://www.googleapis.com/auth/gmail.readonly',
        'https://www.googleapis.com/auth/calendar.events',
        'https://www.googleapis.com/auth/gmail.send',
      ],
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Sign-in aborted by user');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw Exception('Missing Google Auth Token');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );

    debugPrint('🟢 Signed in as: ${userCredential.user?.email}');
    return userCredential;
  }
}
