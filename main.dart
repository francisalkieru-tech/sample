import 'package:flutter/material.dart';
import 'frontpage.dart';
import 'personalPage.dart';
import 'userlog.dart';

void main() {
  runApp(const ExerciseApp());
}

class ExerciseApp extends StatelessWidget {
  const ExerciseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Exercise App',
      theme: ThemeData.dark(),
      initialRoute: '/Front',
      routes: {
        '/signup': (context) => const UserLog(),
        '/Personal': (context) => Personalize(),
        '/Front': (context) => const FrontPage(),
      },
    );
  }
}