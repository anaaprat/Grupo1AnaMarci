import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'services/auth_provider.dart';

void main() {
  runApp(EventifyApp());
}

class EventifyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AuthProvider()), // Añadir AuthProvider aquí
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Eventify',
        theme: ThemeData(
          primarySwatch: Colors.purple,
        ),
        home: LoginScreen(),
      ),
    );
  }
}
