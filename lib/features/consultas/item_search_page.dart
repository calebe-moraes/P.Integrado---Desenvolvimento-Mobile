import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';

import '../../services/sap_service.dart';
import '../../services/ocr_service.dart';
import 'etiqueta_page.dart';

class ItemSearchPage extends StatefulWidget {
  const ItemSearchPage({super.key});

  @override
  State<ItemSearchPage> createState() => _ItemSearchPageState();
}

class _ItemSearchPageState extends State<ItemSearchPage> {
  final _searchController = TextEditingController();
  final AudioPlayer _audio = AudioPlayer();

  Timer? _debounceTimer;
  Map<String, dynamic>? _itemData;
  List<dynamic> _searchResults = [];

  bool _loading            = false;
  bool _scannerProcessando = false;

  // ── Carrinho de impressão ─────────────────────────────────────────────────
  // Persiste durante toda a sessão na tela, independente da busca ativa
  final Map<String, Map<String, dynamic>> _carrinho = {};

  bool get _temItensNoCarrinho => _carrinho.isNotEmpty;

  void _adicionarAoCarrinho(Map<String, dynamic> item) {
    final code = item['ItemCode'] as String;
    HapticFeedback.mediumImpact();
    setState(() => _carrinho[code] = Map<String, dynamic>.from(item));
    _mostrarAviso('${item['ItemCode']} adicionado à fila de impressão.',
        isSuccess: true);
  }

  void _removerDoCarrinho(String code) {
    HapticFeedback.selectionClick();
    setState(() => _carrinho.remove(code));
  }

  bool _estaNoCarrinho(String code) => _carrinho.containsKey(code);

  void _irParaImpressao() {
    if (_carrinho.isEmpty) return;
    HapticFeedback.lightImpact();
    final itens = _carrinho.values.toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EtiquetaPage(
          itemData:  itens.first,
          deposito:  itens.first['_deposito']?.toString() ?? '01',
          itenslote: itens,
        ),
      ),
    );
  }

  void _mostrarCarrinho() {
    HapticFeedback.lightImpact();
    // Usa Navigator para poder chamar setState do sheet via pop+push
    // ou simplesmente abre como rota que lê direto do _carrinho pai
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Usa o builder sem StatefulBuilder — o sheet lê _carrinho
      // direto do estado pai. Para forçar rebuild do sheet ao remover,
      // fechamos e reabrimos via setState + showModalBottomSheet não é
      // necessário: usamos um ValueNotifier local sincronizado.
      builder: (ctx) => _CarrinhoSheet(
        carrinho: _carrinho,
        primaryColor: Theme.of(context).primaryColor,
        onRemover: (code) {
          setState(() => _carrinho.remove(code));
        },
        onLimpar: () {
          setState(() => _carrinho.clear());
        },
        onImprimir: () {
          Navigator.pop(ctx);
          _irParaImpressao();
        },
      ),
    );
  }

  // ─── FEEDBACK ────────────────────────────────────────────────────────────

  Future<void> _play(String asset,
      {bool isError = false, bool isFail = false}) async {
    try {
      if (await Vibration.hasVibrator()) {
        if (isFail) {
          Vibration.vibrate(pattern: [0, 400, 100, 400]);
        } else if (isError) {
          Vibration.vibrate(pattern: [0, 200, 100, 300]);
        } else {
          Vibration.vibrate(duration: 100);
        }
      } else {
        if (isFail || isError) {
          HapticFeedback.vibrate();
        } else {
          HapticFeedback.lightImpact();
        }
      }
      await _audio.play(AssetSource(asset));
    } catch (e) {
      debugPrint('Feedback error: $e');
    }
  }

  // ─── BUSCA ────────────────────────────────────────────────────────────────

  Future<void> _buscar({bool autoSearch = false}) async {
    final termo = _searchController.text.trim();
    if (termo.isEmpty) {
      if (!autoSearch) HapticFeedback.selectionClick();
      return;
    }
    if (!autoSearch) {
      FocusScope.of(context).unfocus();
      HapticFeedback.lightImpact();
    }

    final sessaoAtiva = await SapService.verificarSessao();
    if (!sessaoAtiva) {
      if (!autoSearch && mounted) {
        await _play('sounds/error_beep.mp3', isError: true);
        _mostrarErro(
            'Sessão SAP não encontrada. Faça login antes de pesquisar.');
      }
      return;
    }

    setState(() {
      _loading       = true;
      _itemData      = null;
      _searchResults = [];
    });
    try {
      final results = await SapService.searchItems(termo);
      if (mounted) {
        setState(() {
          _loading = false;
          if (results.length == 1) {
            FocusScope.of(context).unfocus();
            _carregarDetalhes(results.first['ItemCode']);
          } else {
            _searchResults = results;
            if (results.isNotEmpty && !autoSearch) {
              HapticFeedback.selectionClick();
            }
          }
        });
      }
      if (results.isEmpty && !autoSearch) {
        await _play('sounds/error_beep.mp3', isError: true);
        _mostrarAviso("Nenhum item encontrado para '$termo'.");
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      if (!autoSearch) {
        await _play('sounds/fail.mp3', isFail: true);
        _mostrarErro('Erro na busca: $e');
      }
    }
  }

  Future<void> _carregarDetalhes(String itemCode) async {
    setState(() => _loading = true);
    try {
      final data = await SapService.getDetailedItem(itemCode);
      if (mounted) {
        setState(() {
          _itemData      = data;
          _searchResults = [];
          _loading       = false;
        });
        await _play('sounds/beep.mp3');
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      await _play('sounds/fail.mp3', isFail: true);
      _mostrarErro('Erro ao carregar detalhes do item.');
    }
  }

  Future<void> _escanearTextoIA() async {
    HapticFeedback.mediumImpact();
    final resultado = await OcrService.lerAnotacaoDaCamera();
    if (resultado != null &&
        resultado['itemCode'] != null &&
        resultado['itemCode']!.isNotEmpty) {
      setState(() => _searchController.text = resultado['itemCode']!);
      await _play('sounds/beep.mp3');
      _buscar();
    } else {
      await _play('sounds/error_beep.mp3', isError: true);
      _mostrarAviso('Nenhum código reconhecido pela câmera.');
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: const TextStyle(fontWeight: FontWeight.bold))),
      ]),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _mostrarAviso(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isSuccess
              ? Icons.check_circle_outline_rounded
              : Icons.warning_amber_rounded,
          color: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: const TextStyle(fontWeight: FontWeight.bold))),
      ]),
      backgroundColor:
          isSuccess ? Colors.green.shade700 : Colors.orange.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _abrirScanner() {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    _scannerProcessando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          LayoutBuilder(builder: (context, constraints) {
        final scanWindow = Rect.fromCenter(
          center: Offset(constraints.maxWidth / 2, 200),
          width: 280,
          height: 180,
        );
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10)),
              ),
              AppBar(
                title: const Text('Escanear Código',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black87,
                elevation: 0,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MobileScanner(
                      scanWindow: scanWindow,
                      onDetect: (capture) async {
                        if (_scannerProcessando) return;
                        final barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final code = barcodes.first.rawValue ?? '';
                          if (code.isEmpty) return;
                          _scannerProcessando = true;
                          await _play('sounds/beep.mp3');
                          if (!mounted) return;
                          _searchController.text = code;
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pop();
                          _buscar();
                        }
                      },
                    ),
                  ),
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                        Colors.black.withAlpha(179), BlendMode.srcOut),
                    child: Stack(children: [
                      Container(
                          decoration: const BoxDecoration(
                              color: Colors.black,
                              backgroundBlendMode: BlendMode.dstOut)),
                      Center(
                        child: Container(
                          width: scanWindow.width,
                          height: scanWindow.height,
                          decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ]),
                  ),
                  Center(
                    child: Container(
                      width: scanWindow.width,
                      height: scanWindow.height,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ]),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Alinhe o código de barras dentro do quadro'),
              ),
            ]),
          ),
        );
      }),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultar Item'),
        actions: [
          // Ícone do carrinho com badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.print_rounded),
                tooltip: 'Fila de impressão',
                onPressed: _mostrarCarrinho,
              ),
              if (_temItensNoCarrinho)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_carrinho.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          _buildSearchBar(),
          if (_loading)
            const Expanded(
                child: Center(child: CircularProgressIndicator())),
          if (!_loading && _searchResults.isNotEmpty)
            _buildSearchSuggestions(),
          if (!_loading && _itemData != null) _buildResultList(),
          if (!_loading && _itemData == null && _searchResults.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_rounded,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Busque por código ou nome.',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _buscar(),
            onTap: () => HapticFeedback.selectionClick(),
            onChanged: (value) {
              if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
              _debounceTimer =
                  Timer(const Duration(milliseconds: 600), () {
                if (value.trim().isNotEmpty) _buscar(autoSearch: true);
              });
            },
            decoration: InputDecoration(
              hintText: 'Código ou Nome',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.auto_awesome,
                        color: Colors.blueAccent),
                    tooltip: 'Ler texto com IA',
                    onPressed: _escanearTextoIA,
                  ),
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner_rounded,
                        color: theme.primaryColor),
                    tooltip: 'Escanear código de barras',
                    onPressed: _abrirScanner,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 56,
          width: 56,
          child: ElevatedButton(
            onPressed: () => _buscar(),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Icon(Icons.arrow_forward_rounded),
          ),
        ),
      ]),
    );
  }

  Widget _buildSearchSuggestions() {
    final theme = Theme.of(context);
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _searchResults.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item  = _searchResults[index] as Map<String, dynamic>;
          final code  = item['ItemCode'] as String;
          final noCarrinho = _estaNoCarrinho(code);

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: noCarrinho
                    ? theme.primaryColor.withAlpha(80)
                    : Colors.grey.shade300,
              ),
            ),
            color: noCarrinho
                ? theme.primaryColor.withAlpha(8)
                : Colors.white,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.primaryColor.withAlpha(20),
                child: Icon(Icons.inventory_2_outlined,
                    color: theme.primaryColor, size: 18),
              ),
              title: Text(item['ItemName'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(code,
                  style: TextStyle(color: Colors.grey.shade600)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão adicionar/remover do carrinho
                  IconButton(
                    icon: Icon(
                      noCarrinho
                          ? Icons.print_disabled_rounded
                          : Icons.add_to_queue_rounded,
                      color: noCarrinho
                          ? Colors.red.shade400
                          : theme.primaryColor,
                    ),
                    tooltip: noCarrinho
                        ? 'Remover da fila'
                        : 'Adicionar à fila de impressão',
                    onPressed: () {
                      if (noCarrinho) {
                        _removerDoCarrinho(code);
                      } else {
                        _adicionarAoCarrinho(item);
                      }
                    },
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.grey.shade400),
                ],
              ),
              onTap: () => _carregarDetalhes(code),
            ),
          );
        },
      ),
    );
  }

  // ─── DETALHE DO ITEM ──────────────────────────────────────────────────────

  Widget _buildResultList() {
    final noCarrinho =
        _estaNoCarrinho(_itemData!['ItemCode'] ?? '');
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),

          // Botão adicionar/remover do carrinho — logo abaixo do card
          const SizedBox(height: 12),
          noCarrinho
              ? OutlinedButton.icon(
                  onPressed: () =>
                      _removerDoCarrinho(_itemData!['ItemCode']),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('REMOVER DA FILA DE IMPRESSÃO',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () => _adicionarAoCarrinho(_itemData!),
                  icon: const Icon(Icons.add_to_queue_rounded),
                  label: const Text('ADICIONAR À FILA DE IMPRESSÃO',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),

          _buildStatusFlags(),

          _buildSectionTitle('Estoque por Depósito'),
          _buildWarehouseInfo(),

          _buildSectionTitle('Identificação'),
          _buildInfoCard([
            _buildDetailRow(
                'Unidade de Medida', _itemData!['InventoryUOM']?.toString()),
            _buildDetailRow(
                'Embalagem', _itemData!['SalesPackagingUnit']?.toString()),
            _buildDetailRow(
                'Código de Barras (EAN)', _itemData!['BarCode']?.toString()),
            _buildDetailRow(
                'Código Adicional (SWW)', _itemData!['SWW']?.toString()),
            _buildDetailRow(
                'Nome Estrangeiro', _itemData!['ForeignName']?.toString()),
            _buildDetailRow(
                'Grupo (código)', _itemData!['ItemsGroupCode']?.toString()),
            _buildDetailRow('NCM', _itemData!['NCMCode']?.toString()),
          ]),

          _buildSectionTitle('Controle de Estoque'),
          _buildInfoCard([
            _buildDetailRow('Estoque Total',
                _formatNum(_itemData!['QuantityOnStock']),
                destaque: true),
            _buildDetailRow('Pedidos de Clientes',
                _formatNum(_itemData!['QuantityOrderedByCustomers'])),
            _buildDetailRow('Pedidos a Fornecedores',
                _formatNum(_itemData!['QuantityOrderedFromVendors'])),
            _buildDetailRow(
                'Estoque Mínimo', _formatNum(_itemData!['MinInventory'])),
            _buildDetailRow(
                'Estoque Máximo', _formatNum(_itemData!['MaxInventory'])),
            _buildDetailRow('Qtd. Mínima de Pedido',
                _formatNum(_itemData!['MinOrderQuantity'])),
            _buildDetailRow('Controle por Lote',
                _itemData!['ManageBatchNumbers'] == 'tYES' ? 'Sim' : 'Não'),
            _buildDetailRow('Controle por Nº de Série',
                _itemData!['ManageSerialNumbers'] == 'tYES' ? 'Sim' : 'Não'),
          ]),

          _buildSectionTitle('Fornecimento e Preços'),
          _buildInfoCard([
            _buildDetailRow('Fornecedor Principal',
                _itemData!['Mainsupplier']?.toString()),
            _buildDetailRow(
                'Fabricante (código)', _itemData!['Manufacturer']?.toString()),
            _buildDetailRow('Preço Médio Móvel',
                _formatPreco(_itemData!['MovingAveragePrice'])),
            _buildDetailRow('Preço Médio / Padrão',
                _formatPreco(_itemData!['AvgStdPrice'])),
            _buildDetailRow('Preço Lista 1', _formatPrecoLista(1)),
          ]),

          _buildSectionTitle('Dimensões e Peso'),
          _buildInfoCard([
            _buildDetailRow(
                'Peso', _formatMedida(_itemData!['SalesUnitWeight'], 'kg')),
            _buildDetailRow(
                'Altura', _formatMedida(_itemData!['SalesUnitHeight'], 'm')),
            _buildDetailRow(
                'Largura', _formatMedida(_itemData!['SalesUnitWidth'], 'm')),
            _buildDetailRow('Comprimento',
                _formatMedida(_itemData!['SalesUnitLength'], 'm')),
          ]),

          _buildSectionTitle('Status'),
          _buildInfoCard([
            _buildDetailRow(
              'Item Bloqueado',
              _itemData!['Frozen'] == 'tYES' ? 'SIM' : 'NÃO',
              isAlert: _itemData!['Frozen'] == 'tYES',
            ),
          ]),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── FORMATAÇÃO ───────────────────────────────────────────────────────────

  String? _formatPrecoLista(int lista) {
    final prices = _itemData!['ItemPrices'] as List? ?? [];
    try {
      final entry = prices.firstWhere(
          (p) => p['PriceList'] == lista && (p['Price'] ?? 0) > 0);
      return _formatPreco(entry['Price']);
    } catch (_) {
      return null;
    }
  }

  String? _formatNum(dynamic val) {
    if (val == null) return null;
    final n = num.tryParse(val.toString());
    if (n == null || n == 0) return null;
    return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(2);
  }

  String? _formatPreco(dynamic val) {
    if (val == null) return null;
    final n = num.tryParse(val.toString());
    if (n == null || n == 0) return null;
    return 'R\$ ${n.toStringAsFixed(2)}';
  }

  String? _formatMedida(dynamic val, String unidade) {
    if (val == null) return null;
    final n = num.tryParse(val.toString());
    if (n == null || n == 0) return null;
    return '${n.toStringAsFixed(3)} $unidade';
  }

  // ─── WIDGETS ──────────────────────────────────────────────────────────────

  Widget _buildHeaderCard() {
    final theme  = Theme.of(context);
    final qtdNum = num.tryParse(
            _itemData!['QuantityOnStock']?.toString() ?? '0') ??
        0;
    final qtdStr = qtdNum % 1 == 0
        ? qtdNum.toInt().toString()
        : qtdNum.toStringAsFixed(2);
    final um     = _itemData!['InventoryUOM']?.toString() ?? '';
    final minimo = num.tryParse(
            _itemData!['MinInventory']?.toString() ?? '0') ??
        0;
    final corQtd = qtdNum == 0
        ? Colors.white38
        : qtdNum < minimo
            ? Colors.orangeAccent
            : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_itemData!['ItemCode'] ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(_itemData!['ItemName'] ?? '',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(qtdStr,
                      style: TextStyle(
                          color: corQtd,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.0)),
                  Text(um,
                      style: TextStyle(
                          color: corQtd.withAlpha(200),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  Text('em estoque',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10)),
                ],
              ),
            ],
          ),
          if (minimo > 0 || qtdNum > 0) ...[
            const SizedBox(height: 16),
            _buildEstoqueBarra(
                qtdNum,
                minimo,
                num.tryParse(_itemData!['MaxInventory']?.toString() ?? '0') ??
                    0),
          ],
        ],
      ),
    );
  }

  Widget _buildEstoqueBarra(num atual, num minimo, num maximo) {
    final ref = maximo > 0
        ? maximo
        : (minimo > 0 ? minimo * 3 : atual * 1.5);
    final pct =
        ref > 0 ? (atual / ref).clamp(0.0, 1.0).toDouble() : 0.0;
    final cor = atual == 0
        ? Colors.white24
        : atual < minimo
            ? Colors.orangeAccent
            : Colors.greenAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(cor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (minimo > 0)
              Text('Mín: $minimo',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 10)),
            if (maximo > 0)
              Text('Máx: $maximo',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusFlags() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Wrap(
        spacing: 12,
        children: [
          _statusChip('Estoque', _itemData!['InventoryItem'] == 'tYES'),
          _statusChip('Venda',   _itemData!['SalesItem']     == 'tYES'),
          _statusChip('Compra',  _itemData!['PurchaseItem']  == 'tYES'),
        ],
      ),
    );
  }

  Widget _statusChip(String label, bool active) {
    return Chip(
      label: Text(label),
      backgroundColor: active ? Colors.green.shade50 : Colors.grey.shade100,
      avatar: Icon(active ? Icons.check_circle : Icons.cancel,
          size: 16, color: active ? Colors.green : Colors.grey),
    );
  }

  Widget _buildWarehouseInfo() {
    final list = (_itemData!['ItemWarehouseInfoCollection'] as List? ?? []);
    final warehouses =
        list.where((wh) => (wh['InStock'] ?? 0) > 0).toList();
    if (warehouses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text('Sem estoque disponível em nenhum depósito.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      );
    }
    return Column(
      children: warehouses.map((wh) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Icon(Icons.warehouse_rounded,
                  color: Colors.blue.shade700, size: 20),
            ),
            title: Text('Depósito ${wh['WarehouseCode']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Disponível: ${wh['InStock']}  •  '
              'Comprometido: ${wh['Committed'] ?? 0}  •  '
              'Pedido: ${wh['Ordered'] ?? 0}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.print_rounded),
              tooltip: 'Imprimir etiqueta deste depósito',
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EtiquetaPage(
                      itemData: _itemData!,
                      deposito: wh['WarehouseCode'].toString(),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(title,
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  Widget _buildInfoCard(List<Widget> rows) {
    final visible = rows.where((w) => w is! SizedBox).toList();
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text('Sem informações disponíveis.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          for (int i = 0; i < visible.length; i++) ...[
            visible[i],
            if (i < visible.length - 1)
              Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.grey.shade100),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String? value, {
    bool isAlert  = false,
    bool destaque = false,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      title: Text(label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: destaque ? 16 : 13,
          fontWeight: destaque ? FontWeight.bold : FontWeight.w600,
          color: isAlert
              ? Colors.red
              : destaque
                  ? Theme.of(context).primaryColor
                  : Colors.black87,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _audio.dispose();
    super.dispose();
  }
}

// ─── SHEET DO CARRINHO ────────────────────────────────────────────────────────
// Widget próprio com estado local — garante que a lista atualiza
// imediatamente ao excluir sem depender de setState do pai.

class _CarrinhoSheet extends StatefulWidget {
  final Map<String, Map<String, dynamic>> carrinho;
  final Color primaryColor;
  final void Function(String code) onRemover;
  final VoidCallback onLimpar;
  final VoidCallback onImprimir;

  const _CarrinhoSheet({
    required this.carrinho,
    required this.primaryColor,
    required this.onRemover,
    required this.onLimpar,
    required this.onImprimir,
  });

  @override
  State<_CarrinhoSheet> createState() => _CarrinhoSheetState();
}

class _CarrinhoSheetState extends State<_CarrinhoSheet> {
  // Cópia local das chaves para controlar a lista sem depender do mapa pai
  late List<String> _keys;

  @override
  void initState() {
    super.initState();
    _keys = widget.carrinho.keys.toList();
  }

  void _remover(String code) {
    widget.onRemover(code);
    setState(() => _keys.remove(code));
    HapticFeedback.selectionClick();
  }

  void _limpar() {
    widget.onLimpar();
    setState(() => _keys.clear());
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Handle
        const SizedBox(height: 12),
        Container(
          width: 48, height: 6,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10)),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(children: [
            Icon(Icons.print_rounded, color: widget.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Fila de impressão (${_keys.length})',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (_keys.isNotEmpty)
              TextButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Limpar fila'),
                    content: const Text(
                        'Remover todos os itens da fila de impressão?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCELAR'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _limpar();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600),
                        child: const Text('LIMPAR TUDO'),
                      ),
                    ],
                  ),
                ),
                icon: Icon(Icons.delete_sweep_rounded,
                    color: Colors.red.shade600, size: 18),
                label: Text('Limpar',
                    style: TextStyle(color: Colors.red.shade600)),
              ),
          ]),
        ),
        const Divider(height: 1),

        // Lista com swipe para excluir
        Expanded(
          child: _keys.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.print_disabled_rounded,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Nenhum item na fila.',
                          style:
                              TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text('Adicione itens pela busca.',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: _keys.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final code = _keys[index];
                    final item = widget.carrinho[code]!;
                    return Dismissible(
                      key: Key(code),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_rounded,
                            color: Colors.white),
                      ),
                      onDismissed: (_) => _remover(code),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                          color: Colors.white,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                widget.primaryColor.withAlpha(20),
                            child: Icon(Icons.label_rounded,
                                color: widget.primaryColor, size: 18),
                          ),
                          title: Text(code,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          subtitle: Text(
                            item['ItemName'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: Colors.red.shade400),
                            tooltip: 'Remover da fila',
                            onPressed: () => _remover(code),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Botão imprimir
        if (_keys.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: widget.onImprimir,
                icon: const Icon(Icons.print_rounded),
                label: Text(
                  'Imprimir ${_keys.length} '
                  '${_keys.length == 1 ? "etiqueta" : "etiquetas"}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}