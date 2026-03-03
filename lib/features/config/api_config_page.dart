import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfigPage extends StatefulWidget {
  const ApiConfigPage({super.key});

  @override
  State<ApiConfigPage> createState() => _ApiConfigPageState();
}

class _ApiConfigPageState extends State<ApiConfigPage> {
  final _urlController = TextEditingController();
  final _companyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _urlController.text = prefs.getString('sap_url') ?? '';
    _companyController.text = prefs.getString('sap_company') ?? '';
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sap_url', _urlController.text);
    await prefs.setString('sap_company', _companyController.text);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuração SAP")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: "Service Layer URL",
                hintText: "https://servidor:50000/b1s/v1",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: "CompanyDB",
                hintText: "SBODemoBR",
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveConfig,
                child: const Text("Salvar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}