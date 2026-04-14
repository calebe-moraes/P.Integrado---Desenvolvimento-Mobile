import '../services/gemini_service.dart';
import '../models/stox_action.dart';
import '../services/database_helper.dart';

class StoxOrchestrator {
  final GeminiService gemini;
  final DatabaseHelper db;

  StoxOrchestrator(this.gemini, this.db);

  Future<String> handle(String message) async {
    final result = await gemini.askSTOX(message);

    if (result is StoxAction) {
      switch (result.action) {
        case "GET_STOCK":
          final itemCode = result.params['itemCode'];

          if (itemCode == null || itemCode.isEmpty) {
            return "⚠️ Informe o código do item.";
          }

          final total = await db.getStockByItem(itemCode);

          return "📦 Quantidade do item contado em modo offline $itemCode: ${total.toStringAsFixed(2)} unidades";
      }
    }

    return result.toString();
  }
}