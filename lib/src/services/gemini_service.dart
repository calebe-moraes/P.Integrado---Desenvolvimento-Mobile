import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stox_action.dart';
import 'knowledge_service.dart';

class GeminiService {
  static const String _apiKey = "AIzaSyBsWFMZSAfGzZfrHsK5ermskaKkV1RE_2I";

  final KnowledgeService knowledgeService;

  GeminiService(this.knowledgeService);

  static const String _systemPrompt = """
Você é o STOX Assistant.

Use a BASE DE CONHECIMENTO para responder.

Se não for sobre o STOX:
"não consigo responder isso, tente informações relacionadas ao APP"

Se precisar executar algo, responda em JSON:

{
  "action": "NOME_DA_ACAO",
  "params": {}
}

Se a pergunta for sobre quantidade de itens em estoque,
retorne:

{
  "action": "GET_LOCAL_STOCK",
  "params": {
    "itemCode": "codigo"
  }
}"""
;

  Future<dynamic> askSTOX(String userPrompt) async {
    final context = await knowledgeService.getContext(userPrompt);

    final finalPrompt = """
$_systemPrompt

BASE DE CONHECIMENTO:
$context

PERGUNTA:
$userPrompt
""";

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$_apiKey",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": finalPrompt}
            ]
          }
        ]
      }),
    );

    final data = jsonDecode(response.body);
    final text = data['candidates'][0]['content']['parts'][0]['text'];

    /// 🔥 tenta converter para ação
    try {
      final decoded = jsonDecode(text);
      if (decoded['action'] != null) {
        return StoxAction.fromJson(decoded);
      }
    } catch (_) {}

    return text;
  }
}