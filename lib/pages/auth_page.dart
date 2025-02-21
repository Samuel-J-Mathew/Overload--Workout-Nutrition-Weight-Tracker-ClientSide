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

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // user is logged in
          if (snapshot.hasData) {
            //return ClientManagementApp();
            return ExerciseLogPage();
          }

          // user is NOT logged in
          else {
            return LoginOrRegisterPage();
          }
        },
      ),
    );
  }
}
