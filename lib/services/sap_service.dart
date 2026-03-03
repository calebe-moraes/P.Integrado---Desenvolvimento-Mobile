import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SapService {
  static Future<bool> login({
    required String usuario,
    required String senha,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('sap_url');
    final companyDb = prefs.getString('sap_company');

    if (baseUrl == null || companyDb == null) {
      return false;
    }

    final response = await http.post(
      Uri.parse("$baseUrl/Login"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "UserName": usuario,
        "Password": senha,
        "CompanyDB": companyDb,
      }),
    );

    if (response.statusCode == 200) {
      final cookies = response.headers['set-cookie'];

      if (cookies != null) {
        final sessionMatch =
            RegExp(r'B1SESSION=([^;]+)').firstMatch(cookies);
        final routeMatch =
            RegExp(r'ROUTEID=([^;]+)').firstMatch(cookies);

        if (sessionMatch != null) {
          await prefs.setString(
              'B1SESSION', sessionMatch.group(1)!);
        }

        if (routeMatch != null) {
          await prefs.setString(
              'ROUTEID', routeMatch.group(1)!);
        }
      }

      return true;
    }

    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('sap_url');
    final session = prefs.getString('B1SESSION');

    if (baseUrl != null && session != null) {
      await http.post(
        Uri.parse("$baseUrl/Logout"),
        headers: {
          "Cookie": "B1SESSION=$session",
        },
      );
    }

    await prefs.remove('B1SESSION');
    await prefs.remove('ROUTEID');
  }
}