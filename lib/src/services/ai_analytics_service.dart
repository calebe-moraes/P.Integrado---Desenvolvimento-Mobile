import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stox_action.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final String _geminiApiKey = dotenv.env['CHAVE_API_GEMINI'] ?? '';
  static final String _groqApiKey = dotenv.env['CHAVE_API_GROQ'] ?? '';
  static const String _groqModel = "llama-3.1-8b-instant";
  
  GeminiService();

  static const String _systemPrompt = """
Você é o STOX Assistant, um assistente virtual exclusivo do aplicativo APP STOX.
A sua função é ajudar os utilizadores com o uso do APP e realizar CONSULTAS de dados no sistema SAP. 
VOCÊ É ESTRITAMENTE PROIBIDO DE APLICAR AÇÕES (não pode criar, editar ou apagar nada).

Idealização
O STOX nasceu de uma necessidade real identificada por Rafael Valentim, Gerente de Tecnologia da Informação do Grupo JCN (São João da Boa Vista/SP), que concebeu a solução para modernizar o processo de inventário físico da empresa, substituindo coletores de alto custo e eliminando o retrabalho de digitação manual no SAP.

Resumo Executivo
O STOX é uma plataforma móvel desenvolvida em Flutter para modernizar e automatizar o processo de inventário físico do Grupo JCN (São João da Boa Vista/SP). A solução substitui coletores físicos e processos manuais por um aplicativo ágil, integrado diretamente ao SAP Business One via Service Layer API, operando em modo offline-first com banco de dados local SQLite.
O diferencial do projeto é a combinação de Inteligência Artificial (OCR via Google ML Kit), scanner universal de códigos de barras, contagem em equipe com cruzamento automático de dados no SAP, importação de contagens de coletores industriais e impressão de etiquetas térmicas via Bluetooth.

Contexto de Negócio
Empresa Parceira
Grupo JCN — São João da Boa Vista/SP

Problemas Resolvidos
Custo Elevado: Eliminação do aluguel de coletores de dados de alto custo.
Retrabalho: Fim da digitação manual de planilhas Excel para o SAP.
Agilidade: Consulta de estoque e contagem em tempo real diretamente na gôndola/depósito.
Confiabilidade: Redução de erros humanos através da leitura automática de códigos e textos.
Rastreabilidade: Impressão de etiquetas com código de barras diretamente do inventário.
Funcionalidades Principais
Modos de Contagem
Contagem Simples — operador conta offline e sincroniza via POST (novo documento no SAP)
Contagem em Equipe — gerente cria documento no SAP, operadores selecionam no app, contam offline e sincronizam via PATCH. O SAP cruza os dados automaticamente
Importação CSV — importa contagens de outro dispositivo STOX ou coletor industrial (Zebra, Honeywell)
Entrada de Dados
Digitação manual com seletor de quantidade (+/-)
Scanner universal — Code 128, Code 39, EAN-13, EAN-8, UPC-A, QR Code, Data Matrix e outros
OCR por IA — leitura de códigos e quantidades via câmera (Google ML Kit)
Importação CSV — parser inteligente com detecção automática de delimitador e colunas
Integração SAP Business One
Autenticação via Service Layer com SessionID/ROUTEID
Consulta de itens e estoque por depósito em tempo real
Sincronização dual: POST (contagem simples) e PATCH (contagem em equipe)
Tratamento de erros SAP com mensagens orientativas em português
Impressão de Etiquetas Térmicas
Impressão via Bluetooth com suporte a dois protocolos: TSPL (PT-260 e compatíveis) e ESC/POS (GoldenSky e compatíveis)
Preview visual da etiqueta antes da impressão
Configuração de dimensões, campos visíveis e quantidade de cópias
Impressão em lote de múltiplos itens
Geração de PDF para impressão via rede/WiFi
Outros
Exportação CSV compatível com Excel PT-BR (UTF-8 BOM, delimitador ;)
Feedback sensorial — sons, vibração e animações para cada operação
Modo offline completo — funciona sem internet, sincroniza quando disponível
Design system próprio — componentes visuais padronizados (StoxButton, StoxCard, etc.)

Regras de Ouro:
1. Sempre que o utilizador iniciar um chat com saudações, apresente-se.
2. Se o assunto não for sobre o APP STOX, recuse educadamente.
3. Se perguntar "quero informações do produto/item" sem nome/codigo, solicite o nome/codigo do produto.
4. MODO JSON RESTRITO: Se o utilizador quiser saber QUANTIDADE, ESTOQUE ou PESQUISAR um item, retorne APENAS o JSON. 
ATENÇÃO: A chave dentro de params DEVE OBRIGATORIAMENTE se chamar "termo" (tudo minúsculo).

Exemplo exato:
{
  "action": "CONSULTAR_ESTOQUE_SAP",
  "params": {
    "termo": "nome ou codigo do item extraido da pergunta"
  }
}
5. Se o utilizador perguntar "qual a quantidade total do estoque" ou "ver estoque" SEM especificar um produto, responda: "Para qual item ou código você deseja verificar o estoque?"
6. Se a pergunta for apenas para pesquisar se o item existe (sem falar em estoque/quantidade), retorne a action "CONSULTAR_ITEM_SAP".
7. Caso a ação não seja CONSULTA, responda: "Não posso executar ações de incremento, atualizações ou exclusão. Desculpe."
""";

  Future<dynamic> askSTOX(String userPrompt) async {
    // Para o Gemini, juntamos tudo numa String
    final geminiPrompt = "$_systemPrompt\n\nPERGUNTA DO USUÁRIO:\n$userPrompt";

    try {
      return await _callGemini(geminiPrompt);
    } catch (e) {
      try {
        // Para o Groq, passamos separado (System e User) - O Llama obedece muito melhor assim
        return await _callGroq(_systemPrompt, userPrompt);
      } catch (e2) {
        return "Serviços de IA indisponíveis no momento.";
      }
    }
  }

  Future<dynamic> _callGemini(String finalPrompt) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=$_geminiApiKey",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [{"parts": [{"text": finalPrompt}]}],
        "generationConfig": {"temperature": 0.1}
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return _processResponse(data['candidates'][0]['content']['parts'][0]['text']);
    } else {
      throw Exception("Erro Gemini");
    }
  }

  Future<dynamic> _callGroq(String systemMsg, String userMsg) async {
    final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_groqApiKey"
      },
      body: jsonEncode({
        "model": _groqModel,
        "messages": [
          // Llama 3 precisa do "role": "system" para obedecer ao JSON
          {"role": "system", "content": systemMsg},
          {"role": "user", "content": userMsg}
        ],
        "temperature": 0.1
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return _processResponse(data['choices'][0]['message']['content']);
    } else {
      throw Exception("Erro Groq");
    }
  }

  dynamic _processResponse(String text) {
    try {
      final RegExp jsonRegExp = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegExp.firstMatch(text);

      if (match != null) {
        final jsonString = match.group(0)!;
        final decoded = jsonDecode(jsonString);
        
        print("🔍 JSON Extraído da IA: $decoded");

        // Transforma todas as chaves de params para minúsculo para evitar o erro de NULL
        if (decoded['action'] != null && decoded['params'] != null) {
           final Map<String, dynamic> rawParams = decoded['params'];
           final Map<String, dynamic> safeParams = {};
           
           rawParams.forEach((key, value) {
             safeParams[key.toLowerCase()] = value; // Garante que "Termo" vire "termo"
           });
           
           decoded['params'] = safeParams;
           return StoxAction.fromJson(decoded);
        }
      }
    } catch (_) {}
    return text.trim();
  }
}