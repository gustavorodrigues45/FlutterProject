import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class TransferirGadoPage extends StatefulWidget {
  final String gadoId;
  final String gadoNome;

  const TransferirGadoPage({
    super.key,
    required this.gadoId,
    required this.gadoNome,
  });

  @override
  State<TransferirGadoPage> createState() => _TransferirGadoPageState();
}

class _TransferirGadoPageState extends State<TransferirGadoPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _observacoesController = TextEditingController();

  Map<String, dynamic>? _gadoAtual;
  List<Map<String, dynamic>> _proprietarios = [];
  
  String? _novoProprietarioId;
  String? _novaPropriedadeId;
  List<Map<String, dynamic>> _novasPropriedades = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    
    final gado = await _dbHelper.buscarGadoPorId(widget.gadoId);
    final props = await _dbHelper.buscarProprietarios();
    
    setState(() {
      _gadoAtual = gado;
      _proprietarios = props;
      _isLoading = false;
    });
  }

  Future<void> _carregarPropriedades(String proprietarioId) async {
    final props = await _dbHelper.buscarPropriedadesPorProprietario(proprietarioId);
    setState(() {
      _novasPropriedades = props;
      _novaPropriedadeId = null;
    });
  }

  Future<void> _confirmarTransferencia() async {
    if (_formKey.currentState!.validate()) {
      if (_novoProprietarioId == null || _novaPropriedadeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione o proprietário e a propriedade de destino'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Registrar a transferência no histórico
        await _dbHelper.inserirTransferencia({
          'gado_id': widget.gadoId,
          'proprietario_origem_id': _gadoAtual?['owner_id'] ?? '',
          'propriedade_origem_id': _gadoAtual?['propriedade_id'] ?? '',
          'proprietario_destino_id': _novoProprietarioId!,
          'propriedade_destino_id': _novaPropriedadeId!,
          'data_transferencia': DateTime.now().toIso8601String(),
          'observacoes': _observacoesController.text,
        });

        // Atualizar o gado com nova propriedade
        await _dbHelper.atualizarGado(
          widget.gadoId,
          {
            ..._gadoAtual!,
            'owner_id': _novoProprietarioId,
            'propriedade_id': _novaPropriedadeId,
            'atualizado_em': DateTime.now().toIso8601String(),
            'sincronizado': 0,
          },
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transferência realizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna true para indicar sucesso

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao transferir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String _obterNomeProprietario(String? id) {
    if (id == null) return 'N/A';
    final prop = _proprietarios.firstWhere(
      (p) => p['id'] == id,
      orElse: () => {'nome': 'Desconhecido'},
    );
    return prop['nome'];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _gadoAtual == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transferir Gado')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferir Gado'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Informações atuais
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dados Atuais',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Text('Gado: ${widget.gadoNome}'),
                    const SizedBox(height: 5),
                    Text(
                      'Proprietário: ${_obterNomeProprietario(_gadoAtual?['owner_id'])}',
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Propriedade: ${_gadoAtual?['propriedade_id'] ?? 'N/A'}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Nova Localização',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),

            // Dropdown Novo Proprietário
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Novo Proprietário',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              initialValue: _novoProprietarioId,
              items: _proprietarios
                  .map((p) => DropdownMenuItem(
                        value: p['id']?.toString(),
                        child: Text(p['nome']?.toString() ?? ''),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() => _novoProprietarioId = val);
                if (val != null) _carregarPropriedades(val);
              },
              validator: (value) =>
                  value == null ? 'Selecione um proprietário' : null,
            ),
            const SizedBox(height: 15),

            // Dropdown Nova Propriedade
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Nova Propriedade',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              initialValue: _novaPropriedadeId,
              items: _novasPropriedades
                  .map((p) => DropdownMenuItem(
                        value: p['id']?.toString(),
                        child: Text(p['nome']?.toString() ?? ''),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _novaPropriedadeId = val),
              validator: (value) =>
                  value == null ? 'Selecione uma propriedade' : null,
            ),
            const SizedBox(height: 15),

            // Campo de observações
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                hintText: 'Ex: Transferência para engorda',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),

            // Botão de confirmação
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _confirmarTransferencia,
                icon: const Icon(Icons.swap_horiz),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirmar Transferência',
                        style: TextStyle(fontSize: 16),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Botão cancelar
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }
}

// ============= EXEMPLO DE USO =============
// Na tela de DetalheGadoPage, adicione um botão:
/*
ElevatedButton.icon(
  onPressed: () async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransferirGadoPage(
          gadoId: widget.gado.id,
          gadoNome: widget.gado.nome,
        ),
      ),
    );
    
    if (resultado == true) {
      // Atualizar a tela ou voltar
      widget.onGadoChanged();
    }
  },
  icon: const Icon(Icons.swap_horiz),
  label: const Text('Transferir'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
  ),
),
*/
