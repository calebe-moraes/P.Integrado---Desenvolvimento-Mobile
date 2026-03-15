import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'label_config.dart';

/// Tela de impressão de etiqueta.
///
/// Aceita um único item (uso normal da ItemSearchPage) ou
/// uma lista de itens para impressão em lote.
class EtiquetaPage extends StatefulWidget {
  final Map<String, dynamic> itemData;
  final String deposito;

  // ── Impressão em lote ──
  final List<Map<String, dynamic>>? itenslote; // null = impressão única

  const EtiquetaPage({
    super.key,
    required this.itemData,
    required this.deposito,
    this.itenslote,
  });

  @override
  State<EtiquetaPage> createState() => _EtiquetaPageState();
}

class _EtiquetaPageState extends State<EtiquetaPage>
    with SingleTickerProviderStateMixin {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isPrinting = false;
  int _printedCount = 0;

  LabelConfig _config = LabelConfig();
  late TabController _tabController;

  // Controllers para campos do formulário de config
  late TextEditingController _cab1Controller;
  late TextEditingController _cab2Controller;
  late TextEditingController _rodapeController;
  late TextEditingController _larguraController;
  late TextEditingController _alturaController;
  late TextEditingController _copiasController;

  bool get _isLote => widget.itenslote != null && widget.itenslote!.isNotEmpty;
  List<Map<String, dynamic>> get _itensParaImprimir =>
      _isLote ? widget.itenslote! : [widget.itemData];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarConfig();
    _requestPermissions();
  }

  Future<void> _carregarConfig() async {
    final config = await LabelConfig.carregar();
    if (!mounted) return;
    setState(() => _config = config);
    _cab1Controller = TextEditingController(text: config.cabecalhoLinha1);
    _cab2Controller = TextEditingController(text: config.cabecalhoLinha2);
    _rodapeController = TextEditingController(text: config.rodapeTexto);
    _larguraController =
        TextEditingController(text: config.larguraMmCustom.toString());
    _alturaController =
        TextEditingController(text: config.alturaMmCustom.toString());
    _copiasController =
        TextEditingController(text: config.copiasPorItem.toString());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cab1Controller.dispose();
    _cab2Controller.dispose();
    _rodapeController.dispose();
    _larguraController.dispose();
    _alturaController.dispose();
    _copiasController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    if (statuses[Permission.bluetoothConnect]!.isGranted) {
      _getBluetoothDevices();
    }
  }

  void _getBluetoothDevices() async {
    try {
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      if (mounted) setState(() => _devices = devices);
    } catch (e) {
      debugPrint("Erro ao buscar dispositivos: $e");
    }
  }

  // ─── SALVAR CONFIG ───────────────────────────────────────────────────────

  Future<void> _salvarConfig() async {
    FocusScope.of(context).unfocus();
    final novaConfig = _config.copyWith(
      cabecalhoLinha1: _cab1Controller.text.trim(),
      cabecalhoLinha2: _cab2Controller.text.trim(),
      rodapeTexto: _rodapeController.text.trim(),
      larguraMmCustom: int.tryParse(_larguraController.text) ?? 50,
      alturaMmCustom: int.tryParse(_alturaController.text) ?? 30,
      copiasPorItem: int.tryParse(_copiasController.text)?.clamp(1, 99) ?? 1,
    );
    await novaConfig.salvar();
    if (mounted) {
      setState(() => _config = novaConfig);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Configurações salvas!',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      // Volta para a aba de preview após salvar
      _tabController.animateTo(0);
    }
  }

  // ─── IMPRESSÃO ───────────────────────────────────────────────────────────

  Future<void> _imprimir() async {
    if (_selectedDevice == null) {
      HapticFeedback.vibrate();
      _mostrarSnackBar(
          'Selecione uma impressora primeiro.', Colors.orange.shade700);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isPrinting = true;
      _printedCount = 0;
    });

    try {
      bool? isConnected = await bluetooth.isConnected;
      if (!isConnected!) {
        await bluetooth.connect(_selectedDevice!);
      }

      for (final item in _itensParaImprimir) {
        for (int copia = 0; copia < _config.copiasPorItem; copia++) {
          await _imprimirItem(item);
        }
        if (mounted) setState(() => _printedCount++);
      }

      await bluetooth.disconnect();

      if (mounted) {
        HapticFeedback.heavyImpact();
        final total = _itensParaImprimir.length * _config.copiasPorItem;
        _mostrarSnackBar(
          _isLote
              ? '$total etiqueta${total != 1 ? 's' : ''} impressa${total != 1 ? 's' : ''} com sucesso!'
              : 'Impressão enviada com sucesso!',
          Colors.green.shade700,
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        _mostrarSnackBar('Erro de impressão: $e', Colors.red.shade700);
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _imprimirItem(Map<String, dynamic> item) async {
    final codigo = item['ItemCode']?.toString() ?? '000';
    final nome = item['ItemName']?.toString() ?? '';
    final dep = item['_deposito']?.toString() ?? widget.deposito;
    final unidade = item['InventoryUOM']?.toString() ?? '';

    bluetooth.printNewLine();

    // Cabeçalho
    if (_config.mostrarCabecalho && _config.cabecalhoLinha1.isNotEmpty) {
      bluetooth.printCustom(_config.cabecalhoLinha1, 2, 1);
    }
    if (_config.mostrarCabecalho && _config.cabecalhoLinha2.isNotEmpty) {
      bluetooth.printCustom(_config.cabecalhoLinha2, 1, 1);
    }

    // Separador
    bluetooth.printCustom('--------------------------------', 0, 1);

    // Nome do item
    if (_config.mostrarNomeItem && nome.isNotEmpty) {
      bluetooth.printCustom(nome, 1, 1);
    }

    bluetooth.printNewLine();

    // Código de barras (QR neste caso — ESC/POS padrão)
    if (_config.mostrarCodigoBarras) {
      bluetooth.printQRcode(codigo, 150, 150, 1);
    }

    // Código em texto
    if (_config.mostrarCodigoTexto) {
      bluetooth.printCustom(codigo, 1, 1);
    }

    bluetooth.printNewLine();

    // Depósito e unidade
    final infoLinha = [
      if (_config.mostrarDeposito) 'DEP: $dep',
      if (_config.mostrarUnidade && unidade.isNotEmpty) 'UM: $unidade',
    ].join('  ');
    if (infoLinha.isNotEmpty) {
      bluetooth.printCustom(infoLinha, 0, 1);
    }

    // Rodapé
    if (_config.mostrarRodape && _config.rodapeTexto.isNotEmpty) {
      bluetooth.printCustom(_config.rodapeTexto, 0, 1);
    }

    bluetooth.printNewLine();
    bluetooth.printNewLine();

    // Pequeno delay entre itens em lote para não sobrecarregar o buffer
    if (_isLote) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  void _mostrarSnackBar(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLote
            ? 'Imprimir ${_itensParaImprimir.length} etiquetas'
            : 'Impressão de Etiqueta'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.preview_rounded), text: 'Preview'),
            Tab(icon: Icon(Icons.tune_rounded), text: 'Configurar'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDeviceSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPreviewTab(),
                _buildConfigTab(),
              ],
            ),
          ),
          _buildPrintButton(),
        ],
      ),
    );
  }

  // ─── SELETOR DE DISPOSITIVO ───────────────────────────────────────────────

  Widget _buildDeviceSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.print_rounded,
              color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<BluetoothDevice>(
                isExpanded: true,
                hint: const Text("Selecione a Impressora"),
                value: _selectedDevice,
                items: _devices.map((device) {
                  return DropdownMenuItem(
                    value: device,
                    child:
                        Text(device.name ?? "Dispositivo Desconhecido"),
                  );
                }).toList(),
                onChanged: (device) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDevice = device);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Theme.of(context).primaryColor,
            onPressed: () {
              HapticFeedback.lightImpact();
              _getBluetoothDevices();
            },
          ),
        ],
      ),
    );
  }

  // ─── ABA PREVIEW ─────────────────────────────────────────────────────────

  Widget _buildPreviewTab() {
    if (_isLote) {
      return _buildPreviewLote();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(child: _buildVisualEtiqueta(widget.itemData)),
    );
  }

  Widget _buildPreviewLote() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_itensParaImprimir.length} itens selecionados  •  '
                  '${_config.copiasPorItem} cópia${_config.copiasPorItem != 1 ? 's' : ''} cada  •  '
                  'Total: ${_itensParaImprimir.length * _config.copiasPorItem} etiquetas',
                  style: TextStyle(
                      fontSize: 13, color: Colors.blue.shade800),
                ),
              ),
            ],
          ),
        ),
        if (_isPrinting)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _printedCount / _itensParaImprimir.length,
                  backgroundColor: Colors.grey.shade200,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'Imprimindo $_printedCount de ${_itensParaImprimir.length}...',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: _itensParaImprimir.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _itensParaImprimir[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).primaryColor.withAlpha(26),
                    child: Icon(Icons.label_rounded,
                        color: Theme.of(context).primaryColor, size: 20),
                  ),
                  title: Text(item['ItemCode'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(item['ItemName'] ?? ''),
                  trailing: Text(
                    '× ${_config.copiasPorItem}',
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── ABA CONFIGURAÇÃO ────────────────────────────────────────────────────

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Tamanho ──
          _sectionTitle('Tamanho da Etiqueta'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TamanhoEtiqueta.values.map((t) {
              final selected = _config.tamanho == t;
              return ChoiceChip(
                label: Text(t.label),
                selected: selected,
                selectedColor:
                    Theme.of(context).primaryColor.withAlpha(40),
                labelStyle: TextStyle(
                  color: selected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade700,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                onSelected: (_) => setState(
                    () => _config = _config.copyWith(tamanho: t)),
              );
            }).toList(),
          ),

          // Campos personalizados
          if (_config.tamanho == TamanhoEtiqueta.personalizado) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _larguraController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Largura (mm)',
                      prefixIcon: Icon(Icons.width_normal_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _alturaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Altura (mm)',
                      prefixIcon: Icon(Icons.height_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),
          const Divider(),

          // ── Cabeçalho ──
          _sectionTitle('Cabeçalho'),
          const SizedBox(height: 4),
          SwitchListTile.adaptive(
            title: const Text('Mostrar cabeçalho'),
            value: _config.mostrarCabecalho,
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(mostrarCabecalho: v)),
            contentPadding: EdgeInsets.zero,
          ),
          if (_config.mostrarCabecalho) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _cab1Controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Linha 1 (ex: STOX AGRO)',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cab2Controller,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Linha 2 (opcional)',
                prefixIcon: Icon(Icons.subtitles_rounded),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),

          // ── Campos do item ──
          _sectionTitle('Campos do Item'),
          const SizedBox(height: 4),
          _switchItem('Nome do item', _config.mostrarNomeItem,
              (v) => setState(() => _config = _config.copyWith(mostrarNomeItem: v))),
          _switchItem('Código de barras (QR)', _config.mostrarCodigoBarras,
              (v) => setState(() => _config = _config.copyWith(mostrarCodigoBarras: v))),
          _switchItem('Código em texto', _config.mostrarCodigoTexto,
              (v) => setState(() => _config = _config.copyWith(mostrarCodigoTexto: v))),
          _switchItem('Depósito', _config.mostrarDeposito,
              (v) => setState(() => _config = _config.copyWith(mostrarDeposito: v))),
          _switchItem('Unidade de medida', _config.mostrarUnidade,
              (v) => setState(() => _config = _config.copyWith(mostrarUnidade: v))),

          const SizedBox(height: 8),
          const Divider(),

          // ── Rodapé ──
          _sectionTitle('Rodapé'),
          SwitchListTile.adaptive(
            title: const Text('Mostrar rodapé'),
            value: _config.mostrarRodape,
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(mostrarRodape: v)),
            contentPadding: EdgeInsets.zero,
          ),
          if (_config.mostrarRodape) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _rodapeController,
              decoration: const InputDecoration(
                labelText: 'Texto do rodapé (ex: VER. 1.0)',
                prefixIcon: Icon(Icons.text_snippet_rounded),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),

          // ── Impressão ──
          _sectionTitle('Impressão'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _copiasController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cópias por item',
                    prefixIcon: Icon(Icons.content_copy_rounded),
                    helperText: 'Quantas etiquetas imprimir por item.',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: _salvarConfig,
            icon: const Icon(Icons.save_rounded),
            label: const Text('SALVAR CONFIGURAÇÕES'),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _switchItem(
      String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  // ─── VISUAL ETIQUETA (preview na tela) ───────────────────────────────────
  // Proporcional ao tamanho configurado

  Widget _buildVisualEtiqueta(Map<String, dynamic> item) {
    final codigo = item['ItemCode']?.toString() ?? '000';
    final nome = item['ItemName']?.toString() ?? '';
    final dep =
        item['_deposito']?.toString() ?? widget.deposito;

    // Proporção da etiqueta na tela
    final double ratio = _config.largura > 0
        ? _config.altura / _config.largura
        : 1.0;
    const double previewWidth = 260.0;
    final double previewHeight = (previewWidth * ratio).clamp(80.0, 400.0);

    return Container(
      width: previewWidth,
      height: previewHeight,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_config.mostrarCabecalho &&
              _config.cabecalhoLinha1.isNotEmpty) ...[
            Text(_config.cabecalhoLinha1,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            if (_config.cabecalhoLinha2.isNotEmpty)
              Text(_config.cabecalhoLinha2,
                  style: TextStyle(
                      fontSize: 8, color: Colors.grey.shade600)),
            const Divider(height: 8),
          ],
          if (_config.mostrarNomeItem && nome.isNotEmpty) ...[
            Text(nome,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
          ],
          if (_config.mostrarCodigoBarras) ...[
            Flexible(
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: codigo.isEmpty ? '000' : codigo,
                width: previewWidth - 40,
                height: 40,
                drawText: false,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (_config.mostrarCodigoTexto)
            Text(codigo,
                style: const TextStyle(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          if (_config.mostrarDeposito || _config.mostrarRodape) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_config.mostrarDeposito)
                  Text('DEP: $dep',
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.bold)),
                if (_config.mostrarRodape &&
                    _config.rodapeTexto.isNotEmpty)
                  Text(_config.rodapeTexto,
                      style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade500)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── BOTÃO DE IMPRIMIR ───────────────────────────────────────────────────

  Widget _buildPrintButton() {
    final total = _itensParaImprimir.length * _config.copiasPorItem;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isPrinting ? null : _imprimir,
        icon: _isPrinting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Icon(Icons.print_rounded),
        label: Text(
          _isPrinting
              ? 'Imprimindo $_printedCount de ${_itensParaImprimir.length}...'
              : _isLote
                  ? 'IMPRIMIR $total ETIQUETA${total != 1 ? 'S' : ''}'
                  : 'IMPRIMIR ETIQUETA',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// DEPENDÊNCIA NECESSÁRIA no pubspec.yaml:
//   barcode_widget: ^2.0.4
// ─────────────────────────────────────────────────────────────────────────────