import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../services/database_helper.dart';

class ReportService {
  final dbHelper = DatabaseHelper.instance;

  Future<void> generateStockReport() async {
    final pdf = pw.Document();
    final List<Map<String, dynamic>> localItems = await dbHelper.queryAllRows();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // CORREÇÃO AQUI: Usamos 'child' em vez de 'text' para evitar o erro de tipagem
              pw.Header(
                level: 0,
                child: pw.Text("STOX - Inventario Integrado SAP", 
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text("Relatorio de Contagens Locais"),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // A tabela deve ser injetada diretamente como um widget na lista
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                headerHeight: 25,
                cellHeight: 20,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                data: <List<String>>[
                  ['Item', 'Qtd', 'Deposito', 'Status'],
                  ...localItems.map((item) => [
                    item['itemCode']?.toString() ?? '',
                    item['quantidade']?.toString() ?? '0',
                    item['warehouseCode']?.toString() ?? 'N/A',
                    item['syncStatus'] == 1 ? 'Sincronizado' : 'Pendente',
                  ]).toList(), // Importante converter para List
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'relatorio_stox_${DateTime.now().millisecondsSinceEpoch}.pdf'
    );
  }
}