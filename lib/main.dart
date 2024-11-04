import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(EventifyApp());
}

class EventifyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eventify',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}
