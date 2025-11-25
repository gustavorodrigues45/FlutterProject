// EXEMPLO: Como integrar o DatabaseHelper no CadastrarGadoPage
// Substitua o código existente por este exemplo

import 'package:flutter/material.dart';
import 'dart:io';
import '../database/database_helper.dart';
import '../services/image_service.dart';

class CadastrarGadoPageExemplo extends StatefulWidget {
  const CadastrarGadoPageExemplo({super.key});

  @override
  State<CadastrarGadoPageExemplo> createState() => _CadastrarGadoPageExemploState();
}

class _CadastrarGadoPageExemploState extends State<CadastrarGadoPageExemplo> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ImageService _imageService = ImageService();
  
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  
  String? _fotoPath;
  String? _sexoSelecionado;
  List<String> _vacinasSelecionadas = [];
  String? _ownerId;
  String? _propriedadeId;
  String? _loteId;

  // Carregar dados do banco
  List<Map<String, dynamic>> _proprietarios = [];
  List<Map<String, dynamic>> _propriedades = [];
  List<Map<String, dynamic>> _lotes = [];

  @override
  void initState() {
    super.initState();
    _carregarProprietarios();
  }

  Future<void> _carregarProprietarios() async {
    final props = await _dbHelper.buscarProprietarios();
    setState(() {
      _proprietarios = props;
    });
  }

  Future<void> _carregarPropriedades(String proprietarioId) async {
    final props = await _dbHelper.buscarPropriedadesPorProprietario(proprietarioId);
    setState(() {
      _propriedades = props;
      _propriedadeId = null;
      _loteId = null;
    });
  }

  Future<void> _carregarLotes(String propriedadeId) async {
    final lotes = await _dbHelper.buscarLotesPorPropriedade(propriedadeId);
    setState(() {
      _lotes = lotes;
      _loteId = null;
    });
  }

  Future<void> _tirarFoto() async {
    final foto = await _imageService.capturarFoto();
    if (foto != null) {
      setState(() => _fotoPath = foto);
    }
  }

  Future<void> _selecionarDaGaleria() async {
    final foto = await _imageService.selecionarDaGaleria();
    if (foto != null) {
      setState(() => _fotoPath = foto);
    }
  }

  Future<void> _salvarCadastro() async {
    if (_formKey.currentState!.validate()) {
      try {
        final gadoMap = {
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          'nome': _nomeController.text,
          'idade': int.tryParse(_idadeController.text) ?? 0,
          'peso': int.tryParse(_pesoController.text) ?? 0,
          'vacinas': _vacinasSelecionadas.isEmpty ? 'N/A' : _vacinasSelecionadas.join(', '),
          'sexo': _sexoSelecionado ?? 'Não informado',
          'foto': _fotoPath,
          'owner_id': _ownerId,
          'propriedade_id': _propriedadeId,
          'lote_id': _loteId,
          'criado_em': DateTime.now().toIso8601String(),
          'atualizado_em': DateTime.now().toIso8601String(),
          'sincronizado': 0,
          'ativo': 1,
        };

        await _dbHelper.inserirGado(gadoMap);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nomeController.text} cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Limpar formulário
        _nomeController.clear();
        _idadeController.clear();
        _pesoController.clear();
        setState(() {
          _fotoPath = null;
          _sexoSelecionado = null;
          _vacinasSelecionadas = [];
          _ownerId = null;
          _propriedadeId = null;
          _loteId = null;
        });

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Gado')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Campo Nome
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Gado',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 15),

            // Campo Idade
            TextFormField(
              controller: _idadeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Idade (meses)',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Informe a idade' : null,
            ),
            const SizedBox(height: 15),

            // Campo Peso
            TextFormField(
              controller: _pesoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Informe o peso' : null,
            ),
            const SizedBox(height: 15),

            // Botões de Foto
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _tirarFoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Câmera'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selecionarDaGaleria,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeria'),
                  ),
                ),
              ],
            ),
            if (_fotoPath != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_fotoPath!),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 15),

            // Dropdown Proprietário
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Proprietário',
                border: OutlineInputBorder(),
              ),
              initialValue: _ownerId,
              items: _proprietarios
                  .map((p) => DropdownMenuItem(
                        value: p['id']?.toString(),
                        child: Text(p['nome']?.toString() ?? ''),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() => _ownerId = val);
                if (val != null) _carregarPropriedades(val);
              },
            ),
            const SizedBox(height: 15),

            // Dropdown Propriedade
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Propriedade',
                border: OutlineInputBorder(),
              ),
              initialValue: _propriedadeId,
              items: _propriedades
                  .map((p) => DropdownMenuItem(
                        value: p['id']?.toString(),
                        child: Text(p['nome']?.toString() ?? ''),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() => _propriedadeId = val);
                if (val != null) _carregarLotes(val);
              },
            ),
            const SizedBox(height: 15),

            // Dropdown Lote
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Lote/Curral',
                border: OutlineInputBorder(),
              ),
              initialValue: _loteId,
              items: _lotes
                  .map((l) => DropdownMenuItem(
                        value: l['id']?.toString(),
                        child: Text(l['nome']?.toString() ?? ''),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _loteId = val),
            ),
            const SizedBox(height: 15),

            // Dropdown Sexo
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Sexo',
                border: OutlineInputBorder(),
              ),
              initialValue: _sexoSelecionado,
              items: const [
                DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                DropdownMenuItem(value: 'Fêmea', child: Text('Fêmea')),
              ],
              onChanged: (val) => setState(() => _sexoSelecionado = val),
              validator: (value) => value == null ? 'Selecione o sexo' : null,
            ),
            const SizedBox(height: 25),

            // Botão Salvar
            ElevatedButton.icon(
              onPressed: _salvarCadastro,
              icon: const Icon(Icons.save),
              label: const Text('Salvar Cadastro'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
