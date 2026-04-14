import 'package:flutter/services.dart';

class KnowledgeChunk {
  final String content;

  KnowledgeChunk(this.content);
}

class KnowledgeService {
  List<KnowledgeChunk> _chunks = [];

  /// Inicializa e carrega arquivos
  Future<void> init() async {
    final readme = await rootBundle.loadString('assets/README.md');

    _chunks = _splitText(readme, 500)
        .map((c) => KnowledgeChunk(c))
        .toList();
  }

  /// Divide texto em pedaços
  List<String> _splitText(String text, int size) {
    List<String> chunks = [];

    for (int i = 0; i < text.length; i += size) {
      chunks.add(text.substring(
        i,
        i + size > text.length ? text.length : i + size,
      ));
    }

    return chunks;
  }

  /// Busca simples por palavras-chave
  List<KnowledgeChunk> _search(String query) {
    final keywords = query.toLowerCase().split(" ");

    return _chunks.where((chunk) {
      final text = chunk.content.toLowerCase();
      return keywords.any((k) => text.contains(k));
    }).toList();
  }

  /// Retorna contexto relevante
  Future<String> getContext(String query) async {
    final results = _search(query);

    if (results.isEmpty) return "";

    return results
        .take(3)
        .map((c) => c.content)
        .join("\n\n");
  }
}