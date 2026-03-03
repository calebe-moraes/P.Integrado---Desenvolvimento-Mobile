import 'package:flutter/material.dart';
import '../../services/sap_service.dart';
import '../auth/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sistema de Estoque"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SapService.logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Bem-vindo ao sistema!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}