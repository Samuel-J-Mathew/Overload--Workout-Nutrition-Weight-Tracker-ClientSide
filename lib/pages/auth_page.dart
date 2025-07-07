import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gymapp/WebAPP/ClientManagementApp.dart';
import 'package:gymapp/WebAPP/WebappHomePage.dart';
import 'package:gymapp/pages/webAppDataAnalysis.dart';

import 'package:gymapp/WebAPP/MyApp.dart' as homeApp;

import 'ExerciseLogPage.dart';
import 'LoginOrRegisterPage.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'onboarding_flow.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // User is NOT logged in
          if (!snapshot.hasData) {
            return LoginOrRegisterPage();
          }

          // User is logged in
          final uid = snapshot.data!.uid;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (userSnapshot.hasError) {
                return Center(child: Text('Error: ${userSnapshot.error}'));
              }

              final data = userSnapshot.data?.data() as Map<String, dynamic>?;

              final onboardingComplete = data?['onboardingComplete'] ?? false;

              if (onboardingComplete) {
                return const ExerciseLogPage();
              } else {
                return const OnboardingFlow();
              }
            },
          );
        },
      ),
    );
  }
}
