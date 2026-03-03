import 'package:flutter/material.dart';
import 'features/auth/login_page.dart';

void main() {
  runApp(const StoxApp());
}

class StoxApp extends StatelessWidget {
  const StoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}