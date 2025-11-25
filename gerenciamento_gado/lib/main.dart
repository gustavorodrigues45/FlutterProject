import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'database/database_helper.dart';
import 'services/auth_service.dart';
import 'services/image_service.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'package:permission_handler/permission_handler.dart';

// ========================= DADOS GLOBAIS (SIMULAÇÃO DE BANCO DE DADOS) =========================
// Lista global para armazenar os gados cadastrados dinamicamente.
List<Gado> gadosCadastrados = [];

// NOVA LISTA GLOBAL DE OPÇÕES DE VACINAS
const List<String> listaOpcoesVacinas = [
  'Febre Aftosa',
  'Brucelose',
  'Raiva',
  'Leptospirose',
  'Clostridiose',
  'Botulismo',
  'IBR/BVD',
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Nota: MySQL removido - app usa lista em memória para demo
  // Para produção, implemente API REST ou use MySQL em desktop/mobile
  
  // Em Web, evitamos inicializações que não são suportadas
  if (!kIsWeb) {
    // Inicializar serviço de notificações (somente mobile/desktop)
    await NotificationService().initialize();
    await NotificationService().solicitarPermissoes();

    // Inicializar serviço de sincronização
    await SyncService().inicializar();

    // Solicitar permissões
    await _solicitarPermissoes();
  }
  
  runApp(const GerenciamentoGadoApp());
}

Future<void> _solicitarPermissoes() async {
  await Permission.camera.request();
  await Permission.storage.request();
  await Permission.photos.request();
  await Permission.notification.request();
}

// ========================= MODELO DE DADOS (MUTÁVEL PARA EDIÇÃO) =========================
class Gado {
  // ID único do gado (gerado automaticamente se não fornecido)
  String id;
  String nome;
  int idade; // Alterado para int
  int peso;  // Alterado para int
  String vacinas; // String contendo vacinas separadas por vírgula
  String sexo;
  int ativo; // 1 ativo, 0 inativo (venda/perda)

  // NOVOS CAMPOS PARA ATENDER A ESTRUTURA SOLICITADA
  // foto: caminho/URI da foto ou base64 (opcional)
  String? foto;

  // Referências (IDs) para proprietário, propriedade e lote
  String? ownerId;
  String? propriedadeId;
  String? loteId;

  Gado({
    String? id,
    required this.nome,
    required this.idade,
    required this.peso,
    required this.vacinas,
    required this.sexo,
    this.ativo = 1,
    this.foto,
    this.ownerId,
    this.propriedadeId,
    this.loteId,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();
  
  // Converter para Map para salvar no banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'idade': idade,
      'peso': peso,
      'vacinas': vacinas,
      'sexo': sexo,
      'ativo': ativo,
      'foto': foto,
      'owner_id': ownerId,
      'propriedade_id': propriedadeId,
      'lote_id': loteId,
      'criado_em': DateTime.now().toIso8601String(),
      'atualizado_em': DateTime.now().toIso8601String(),
      'sincronizado': 0,
    };
  }
  
  // Criar Gado a partir de Map do banco
  factory Gado.fromMap(Map<String, dynamic> map) {
    return Gado(
      id: map['id'],
      nome: map['nome'],
      idade: map['idade'],
      peso: map['peso'],
      vacinas: map['vacinas'],
      sexo: map['sexo'],
      ativo: map['ativo'] ?? 1,
      foto: map['foto'],
      ownerId: map['owner_id'],
      propriedadeId: map['propriedade_id'],
      loteId: map['lote_id'],
    );
  }
}

// ========================= NOVO MODELO: PROPRIETÁRIOS/POLÍCIAS/LOTES =========================
class Proprietario {
  String id;
  String nome;
  List<Propriedade> propriedades;

  Proprietario({required this.id, required this.nome, List<Propriedade>? propriedades})
      : propriedades = propriedades ?? [];
}

class Propriedade {
  String id;
  String nome;
  List<Lote> lotes;
  // IDs dos gados vinculados a essa propriedade
  List<String> gadoIds;

  Propriedade({
    required this.id,
    required this.nome,
    List<Lote>? lotes,
    List<String>? gadoIds,
  })  : lotes = lotes ?? [],
        gadoIds = gadoIds ?? [];
}

class Lote {
  String id;
  String nome;
  String? descricao;

  Lote({required this.id, required this.nome, this.descricao});
}

// Lista global de proprietários (simulação de banco)
List<Proprietario> proprietarios = [];

// ----------------- Helpers reutilizáveis para criar entidades -----------------
// Retornam o id criado ou null se cancelado.
Future<String?> showCreateProprietarioDialog(BuildContext context) async {
  final TextEditingController nameCtrl = TextEditingController();
  final result = await showDialog<String?>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Novo Proprietário'),
      content: TextField(
        controller: nameCtrl,
        decoration: const InputDecoration(labelText: 'Nome do proprietário'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(context, nameCtrl.text.trim()), child: const Text('Criar')),
      ],
    ),
  );

  if (result != null && result.isNotEmpty) {
    final novo = Proprietario(id: DateTime.now().microsecondsSinceEpoch.toString(), nome: result);
    proprietarios.add(novo);
    return novo.id;
  }
  return null;
}

Future<String?> showCreatePropriedadeDialog(BuildContext context, String ownerId) async {
  final TextEditingController nameCtrl = TextEditingController();
  final result = await showDialog<String?>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nova Propriedade'),
      content: TextField(
        controller: nameCtrl,
        decoration: const InputDecoration(labelText: 'Nome da propriedade'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(context, nameCtrl.text.trim()), child: const Text('Criar')),
      ],
    ),
  );

  if (result != null && result.isNotEmpty) {
    final prop = Propriedade(id: DateTime.now().microsecondsSinceEpoch.toString(), nome: result);
    final ownerIndex = proprietarios.indexWhere((p) => p.id == ownerId);
    if (ownerIndex != -1) {
      proprietarios[ownerIndex].propriedades.add(prop);
      return prop.id;
    }
  }
  return null;
}

Future<String?> showCreateLoteDialog(BuildContext context, String ownerId, String propriedadeId) async {
  final TextEditingController nameCtrl = TextEditingController();
  final result = await showDialog<String?>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Novo Lote'),
      content: TextField(
        controller: nameCtrl,
        decoration: const InputDecoration(labelText: 'Nome do lote'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(context, nameCtrl.text.trim()), child: const Text('Criar')),
      ],
    ),
  );

  if (result != null && result.isNotEmpty) {
    final lote = Lote(id: DateTime.now().microsecondsSinceEpoch.toString(), nome: result);
    final ownerIndex = proprietarios.indexWhere((p) => p.id == ownerId);
    if (ownerIndex != -1) {
      final propIndex = proprietarios[ownerIndex].propriedades.indexWhere((pr) => pr.id == propriedadeId);
      if (propIndex != -1) {
        proprietarios[ownerIndex].propriedades[propIndex].lotes.add(lote);
        return lote.id;
      }
    }
  }
  return null;
}

class GerenciamentoGadoApp extends StatelessWidget {
  const GerenciamentoGadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciamento de Gado',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ========================= LOGIN PAGE =========================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final resultado = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      setState(() => _isLoading = false);
      
      if (resultado['sucesso']) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['mensagem']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login - Gerenciamento de Gado'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Ícone
                Icon(
                  Icons.pets,
                  size: 100,
                  color: Colors.green[700],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bem-vindo!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o e-mail';
                    }
                    if (!value.contains('@')) {
                      return 'E-mail inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Informe a senha' : null,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Entrar', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: _goToRegister,
                  child: const Text('Criar conta'),
                ),
                const SizedBox(height: 10),
                Text(
                  'Login padrão: admin@gado.com / admin123',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================= CADASTRO DE USUÁRIO =========================
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final resultado = await _authService.registrar(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['mensagem']),
          backgroundColor: resultado['sucesso'] ? Colors.green : Colors.red,
        ),
      );
      
      if (resultado['sucesso']) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) =>
                    value!.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (value) =>
                    value!.isEmpty ? 'Informe o e-mail' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
                validator: (value) =>
                    value!.isEmpty ? 'Informe a senha' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Cadastrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================= DASHBOARD (PAINEL) =========================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, int>? _metricas;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarMetricas();
  }

  Future<void> _carregarMetricas() async {
    final m = await DatabaseHelper().obterMetricasDashboard();
    setState(() {
      _metricas = m;
      _loading = false;
    });
  }

  void _goToGadoList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ListaGadoPage()),
    );
  }

  void _goToGadoCadastro(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CadastrarGadoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Painel de Gado')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarMetricas,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(child: _cardMetric('Total', _metricas!['total'] ?? 0, Icons.all_inbox, Colors.blue)),
                      const SizedBox(width: 8),
                      Expanded(child: _cardMetric('Ativos', _metricas!['ativos'] ?? 0, Icons.check_circle, Colors.green)),
                      const SizedBox(width: 8),
                      Expanded(child: _cardMetric('Inativos', _metricas!['inativos'] ?? 0, Icons.remove_circle, Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _cardMetric('Vendas (30d)', _metricas!['vendas30'] ?? 0, Icons.sell, Colors.orange)),
                      const SizedBox(width: 8),
                      Expanded(child: _cardMetric('Perdas (30d)', _metricas!['perdas30'] ?? 0, Icons.warning, Colors.red)),
                      const SizedBox(width: 8),
                      Expanded(child: _cardMetric('Vacinas (7d)', _metricas!['proximasVacinas7'] ?? 0, Icons.vaccines, Colors.purple)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _goToGadoCadastro(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Cadastrar Novo Gado'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _goToGadoList(context),
                          icon: const Icon(Icons.list),
                          label: const Text('Ver Lista de Gados'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _cardMetric(String label, int value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ========================= CADASTRO DE GADO =========================
class CadastrarGadoPage extends StatefulWidget {
  const CadastrarGadoPage({super.key});

  @override
  State<CadastrarGadoPage> createState() => _CadastrarGadoPageState();
}

class _CadastrarGadoPageState extends State<CadastrarGadoPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  // Foto (URI/path) controller
  final TextEditingController _fotoController = TextEditingController();

  String? _sexoSelecionado;
  // NOVO: Armazena as vacinas selecionadas
  List<String> _vacinasSelecionadas = [];
  // Seleção/IDs para proprietário, propriedade e lote
  String? _ownerId;
  String? _propriedadeId;
  String? _loteId;

  // NOVO MÉTODO: Abre um diálogo para seleção múltipla de vacinas
  Future<void> _selecionarVacinas() async {
    // Abre o diálogo e espera pelo resultado (lista de vacinas selecionadas)
    final List<String>? resultado = await showDialog<List<String>>(
      context: context,
      builder: (context) => MultiSelectVacinasDialog(
        todasVacinas: listaOpcoesVacinas,
        vacinasAtuais: _vacinasSelecionadas,
      ),
    );

    if (resultado != null) {
      setState(() {
        _vacinasSelecionadas = resultado;
      });
    }
  }

  // Cria um novo proprietário via diálogo simples


  Future<void> _salvarCadastro() async {
    if (_formKey.currentState!.validate()) {
      try {
        final novoGado = Gado(
          nome: _nomeController.text,
          idade: int.tryParse(_idadeController.text) ?? 0,
          peso: int.tryParse(_pesoController.text) ?? 0,
          // NOVO: Salva as vacinas como uma string formatada ou "N/A"
          vacinas: _vacinasSelecionadas.isEmpty
              ? 'N/A'
              : _vacinasSelecionadas.join(', '), // Junta as vacinas com vírgula
          sexo: _sexoSelecionado ?? 'Não informado',
          foto: _fotoController.text.isEmpty ? null : _fotoController.text,
          ownerId: _ownerId,
          propriedadeId: _propriedadeId,
          loteId: _loteId,
        );

        // Salvar no banco de dados
        await DatabaseHelper().inserirGado(novoGado.toMap());
        
        // Manter compatibilidade com lista em memória
        gadosCadastrados.add(novoGado);

        // Se vinculou a uma propriedade, registre o id do gado na propriedade
        if (_ownerId != null && _propriedadeId != null) {
          final ownerIndex = proprietarios.indexWhere((p) => p.id == _ownerId);
          if (ownerIndex != -1) {
            final propIndex = proprietarios[ownerIndex].propriedades.indexWhere((pr) => pr.id == _propriedadeId);
            if (propIndex != -1) {
              proprietarios[ownerIndex].propriedades[propIndex].gadoIds.add(novoGado.id);
            }
          }
        }

        // Limpa os campos para novo cadastro
        _nomeController.clear();
        _idadeController.clear();
        _pesoController.clear();
        setState(() {
          _sexoSelecionado = null;
          _vacinasSelecionadas = []; // Limpa a seleção
          _fotoController.clear();
          _ownerId = null;
          _propriedadeId = null;
          _loteId = null;
        });

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cadastro realizado'),
            content: Text('${novoGado.nome} foi adicionado à lista com sucesso!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Gado',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Informe o nome do gado' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _idadeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Idade (em meses)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Informe a idade' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _pesoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Peso (em kg)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Informe o peso' : null,
              ),
              const SizedBox(height: 15),
              // Botões de Foto
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ImageService imageService = ImageService();
                        final foto = await imageService.capturarFoto();
                        if (foto != null) {
                          setState(() => _fotoController.text = foto);
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Câmera'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ImageService imageService = ImageService();
                        final foto = await imageService.selecionarDaGaleria();
                        if (foto != null) {
                          setState(() => _fotoController.text = foto);
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeria'),
                    ),
                  ),
                ],
              ),
              if (_fotoController.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Foto: ${_fotoController.text.split('/').last}', 
                     style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              const SizedBox(height: 15),

              // Proprietário / Propriedade / Lote (edição)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Proprietário', border: OutlineInputBorder()),
                      initialValue: _ownerId,
                      items: proprietarios
                          .map((p) => DropdownMenuItem(value: p.id, child: Text(p.nome)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _ownerId = val;
                          _propriedadeId = null;
                          _loteId = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      final id = await showCreateProprietarioDialog(context);
                      if (id != null) {
                        setState(() {
                          _ownerId = id;
                          _propriedadeId = null;
                          _loteId = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    tooltip: 'Novo proprietário',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Propriedade', border: OutlineInputBorder()),
                      initialValue: _propriedadeId,
                      items: _ownerId == null
                          ? []
                          : proprietarios
                              .firstWhere((p) => p.id == _ownerId)
                              .propriedades
                              .map((pr) => DropdownMenuItem(value: pr.id, child: Text(pr.nome)))
                              .toList(),
                      onChanged: (val) {
                        setState(() {
                          _propriedadeId = val;
                          _loteId = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      if (_ownerId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um proprietário primeiro')));
                        return;
                      }
                      final id = await showCreatePropriedadeDialog(context, _ownerId!);
                      if (id != null) {
                        setState(() {
                          _propriedadeId = id;
                          _loteId = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.add_home_outlined),
                    tooltip: 'Nova propriedade',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Lote', border: OutlineInputBorder()),
                      initialValue: _loteId,
                      items: (_ownerId == null || _propriedadeId == null)
                          ? []
                          : proprietarios
                              .firstWhere((p) => p.id == _ownerId)
                              .propriedades
                              .firstWhere((pr) => pr.id == _propriedadeId)
                              .lotes
                              .map((l) => DropdownMenuItem(value: l.id, child: Text(l.nome)))
                              .toList(),
                      onChanged: (val) {
                        setState(() {
                          _loteId = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      if (_propriedadeId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma propriedade primeiro')));
                        return;
                      }
                      final id = await showCreateLoteDialog(context, _ownerId!, _propriedadeId!);
                      if (id != null) {
                        setState(() {
                          _loteId = id;
                        });
                      }
                    },
                    icon: const Icon(Icons.storage),
                    tooltip: 'Novo lote',
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // NOVO CAMPO: Seleção Múltipla de Vacinas
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Vacinas Aplicadas',
                  border: const OutlineInputBorder(),
                  // Exibe a lista de vacinas selecionadas
                  hintText: _vacinasSelecionadas.isEmpty
                      ? 'Clique para selecionar as vacinas'
                      : _vacinasSelecionadas.join(', '),
                  suffixIcon: const Icon(Icons.vaccines),
                ),
                readOnly: true, // Torna o campo não editável
                onTap: _selecionarVacinas, // Abre o diálogo ao tocar
              ),
              
              const SizedBox(height: 15),
              
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
                onChanged: (value) {
                  setState(() {
                    _sexoSelecionado = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecione o sexo' : null,
              ),
              const SizedBox(height: 25),
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
      ),
    );
  }
}

// ========================= NOVO WIDGET: DIÁLOGO DE SELEÇÃO MÚLTIPLA DE VACINAS =========================
class MultiSelectVacinasDialog extends StatefulWidget {
  final List<String> todasVacinas;
  final List<String> vacinasAtuais;

  const MultiSelectVacinasDialog({
    super.key,
    required this.todasVacinas,
    required this.vacinasAtuais,
  });

  @override
  State<MultiSelectVacinasDialog> createState() => _MultiSelectVacinasDialogState();
}

class _MultiSelectVacinasDialogState extends State<MultiSelectVacinasDialog> {
  // Lista temporária para armazenar as seleções dentro do diálogo
  late List<String> _vacinasSelecionadasTemp;

  @override
  void initState() {
    super.initState();
    // Inicializa a lista temporária com as vacinas que já estão selecionadas
    _vacinasSelecionadasTemp = List.from(widget.vacinasAtuais);
  }

  void _itemChange(String item, bool isSelected) {
    setState(() {
      if (isSelected) {
        _vacinasSelecionadasTemp.add(item);
      } else {
        _vacinasSelecionadasTemp.remove(item);
      }
    });
  }

  void _cancel() {
    // Retorna null ou a lista original para indicar que nenhuma mudança foi aplicada
    Navigator.pop(context, widget.vacinasAtuais); 
  }

  void _submit() {
    // Retorna a lista atualizada
    Navigator.pop(context, _vacinasSelecionadasTemp); 
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecione as Vacinas'),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.todasVacinas
              .map(
                (vacina) => CheckboxListTile(
                  value: _vacinasSelecionadasTemp.contains(vacina),
                  title: Text(vacina),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (bool? isChecked) {
                    _itemChange(vacina, isChecked!);
                  },
                ),
              )
              .toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('OK'),
        ),
      ],
    );
  }
}


// ========================= LISTA DE GADO (STATEFUL PARA REFRESH) =========================
class ListaGadoPage extends StatefulWidget {
  const ListaGadoPage({super.key});

  @override
  State<ListaGadoPage> createState() => _ListaGadoPageState();
}

class _ListaGadoPageState extends State<ListaGadoPage> {

  // Função para recarregar a lista quando voltamos da edição/exclusão
  void _refreshList() {
    setState(() {
      // Força a reconstrução da página com a lista atualizada
    });
  }

  // Busca
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToDetalhe(BuildContext context, Gado gado) async {
    // A lista precisa ser atualizada ao voltar da DetalheGadoPage (após edição/exclusão)
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetalheGadoPage(gado: gado, onGadoChanged: _refreshList)),
    );
    _refreshList(); // Chamada para atualizar a lista ao voltar
  }

  @override
  Widget build(BuildContext context) {
    if (gadosCadastrados.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gado Cadastrado')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                'Nenhum gado cadastrado ainda.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Filtra a lista com base na query
    final query = _searchQuery.toLowerCase();
    final filtered = gadosCadastrados.where((gado) {
      if (gado.ativo == 0) return false; // oculta gado inativo
      if (query.isEmpty) return true;
      final ownerName = gado.ownerId == null
          ? ''
          : (proprietarios.firstWhere((p) => p.id == gado.ownerId, orElse: () => Proprietario(id: '', nome: '')).nome);
      final propriedadeName = (gado.ownerId == null || gado.propriedadeId == null)
          ? ''
          : (proprietarios
              .firstWhere((p) => p.id == gado.ownerId, orElse: () => Proprietario(id: '', nome: ''))
              .propriedades
              .firstWhere((pr) => pr.id == gado.propriedadeId, orElse: () => Propriedade(id: '', nome: ''))
              .nome);
      final loteName = (gado.ownerId == null || gado.propriedadeId == null || gado.loteId == null)
          ? ''
          : (proprietarios
              .firstWhere((p) => p.id == gado.ownerId, orElse: () => Proprietario(id: '', nome: ''))
              .propriedades
              .firstWhere((pr) => pr.id == gado.propriedadeId, orElse: () => Propriedade(id: '', nome: ''))
              .lotes
              .firstWhere((l) => l.id == gado.loteId, orElse: () => Lote(id: '', nome: '') )
              .nome);

      final combined = '${gado.nome} ${gado.id} ${gado.sexo} ${gado.vacinas} $ownerName $propriedadeName $loteName'.toLowerCase();
      return combined.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Gado Cadastrado (${gadosCadastrados.where((g) => g.ativo == 1).length})')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por nome, id, proprietário, propriedade, lote, vacinas...',
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('Nenhum resultado para "$_searchQuery"', style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final gado = filtered[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            gado.sexo == 'Macho' ? Icons.male : Icons.female,
                            color: gado.sexo == 'Macho' ? Colors.blue : Colors.pink,
                            size: 40,
                          ),
                          title: Text(gado.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Idade: ${gado.idade} meses | Peso: ${gado.peso} kg'),
                          trailing: Text(gado.sexo),
                          onTap: () => _goToDetalhe(context, gado),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ========================= TELA DE EDIÇÃO DO GADO =========================
class EditarGadoPage extends StatefulWidget {
  final Gado gado;
  final VoidCallback onGadoEdited; // Callback para notificar a DetalhePage

  const EditarGadoPage({super.key, required this.gado, required this.onGadoEdited});

  @override
  State<EditarGadoPage> createState() => _EditarGadoPageState();
}

class _EditarGadoPageState extends State<EditarGadoPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _idadeController;
  late TextEditingController _pesoController;
  late TextEditingController _fotoController;
  // REMOVIDO: late TextEditingController _vacinasController;

  String? _sexoSelecionado;
  // NOVO: Lista mutável para as vacinas na edição
  late List<String> _vacinasSelecionadas; 
  // Seleção/IDs para proprietário, propriedade e lote na edição
  String? _ownerId;
  String? _propriedadeId;
  String? _loteId;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.gado.nome);
    _idadeController = TextEditingController(text: widget.gado.idade.toString());
    _pesoController = TextEditingController(text: widget.gado.peso.toString());
    _fotoController = TextEditingController(text: widget.gado.foto ?? '');
    _sexoSelecionado = widget.gado.sexo == 'Não informado' ? null : widget.gado.sexo;
    
    // NOVO: Inicializa a lista de vacinas, separando a string por vírgulas
    _vacinasSelecionadas = widget.gado.vacinas == 'N/A'
        ? []
        : widget.gado.vacinas.split(', ').toList();

    // inicializa seleção de owner/propriedade/lote
    _ownerId = widget.gado.ownerId;
    _propriedadeId = widget.gado.propriedadeId;
    _loteId = widget.gado.loteId;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _idadeController.dispose();
    _pesoController.dispose();
    _fotoController.dispose();
    super.dispose();
  }
  
  // NOVO MÉTODO: Abre um diálogo para seleção múltipla de vacinas
  Future<void> _selecionarVacinas() async {
    final List<String>? resultado = await showDialog<List<String>>(
      context: context,
      builder: (context) => MultiSelectVacinasDialog(
        todasVacinas: listaOpcoesVacinas,
        vacinasAtuais: _vacinasSelecionadas,
      ),
    );

    if (resultado != null) {
      setState(() {
        _vacinasSelecionadas = resultado;
      });
    }
  }

  // ---- duplicados dos helpers de criação usados no cadastro ----
  


  Future<void> _salvarEdicao() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 1. Atualiza o objeto Gado original
        final oldOwnerId = widget.gado.ownerId;
        final oldPropId = widget.gado.propriedadeId;

        widget.gado.nome = _nomeController.text;
        widget.gado.idade = int.tryParse(_idadeController.text) ?? widget.gado.idade;
        widget.gado.peso = int.tryParse(_pesoController.text) ?? widget.gado.peso;
        // NOVO: Atualiza a string de vacinas
        widget.gado.vacinas = _vacinasSelecionadas.isEmpty
            ? 'N/A'
            : _vacinasSelecionadas.join(', ');
        widget.gado.sexo = _sexoSelecionado ?? 'Não informado';
        widget.gado.foto = _fotoController.text.isEmpty ? null : _fotoController.text;
        widget.gado.ownerId = _ownerId;
        widget.gado.propriedadeId = _propriedadeId;
        widget.gado.loteId = _loteId;

        // Atualizar no banco de dados
        await DatabaseHelper().atualizarGado(widget.gado.id, widget.gado.toMap());

        // Atualiza referências em propriedades: remove de antiga propriedade e adiciona na nova
        if (oldPropId != null) {
          final oi = proprietarios.indexWhere((p) => p.id == oldOwnerId);
          if (oi != -1) {
            final pi = proprietarios[oi].propriedades.indexWhere((pr) => pr.id == oldPropId);
            if (pi != -1) {
              proprietarios[oi].propriedades[pi].gadoIds.removeWhere((id) => id == widget.gado.id);
            }
          }
        }
        if (_propriedadeId != null && _ownerId != null) {
          final oi2 = proprietarios.indexWhere((p) => p.id == _ownerId);
          if (oi2 != -1) {
            final pi2 = proprietarios[oi2].propriedades.indexWhere((pr) => pr.id == _propriedadeId);
            if (pi2 != -1) {
              final exists = proprietarios[oi2].propriedades[pi2].gadoIds.contains(widget.gado.id);
              if (!exists) proprietarios[oi2].propriedades[pi2].gadoIds.add(widget.gado.id);
            }
          }
        }

        // 2. Chama o callback para notificar a tela de detalhes
        widget.onGadoEdited();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.gado.nome} atualizado com sucesso!')),
        );

        // Volta para a tela de detalhes
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar ${widget.gado.nome}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Gado',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Informe o nome do gado' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _idadeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Idade (em meses)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Informe a idade' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _pesoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Peso (em kg)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Informe o peso' : null,
              ),
              const SizedBox(height: 15),
              
              // Botões de Foto
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ImageService imageService = ImageService();
                        final foto = await imageService.capturarFoto();
                        if (foto != null) {
                          setState(() => _fotoController.text = foto);
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Câmera'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ImageService imageService = ImageService();
                        final foto = await imageService.selecionarDaGaleria();
                        if (foto != null) {
                          setState(() => _fotoController.text = foto);
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeria'),
                    ),
                  ),
                ],
              ),
              if (_fotoController.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Foto: ${_fotoController.text.split('/').last}', 
                     style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              const SizedBox(height: 15),
              
              // NOVO CAMPO: Seleção Múltipla de Vacinas
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Vacinas Aplicadas',
                  border: const OutlineInputBorder(),
                  // Exibe a lista de vacinas selecionadas
                  hintText: _vacinasSelecionadas.isEmpty
                      ? 'Clique para selecionar as vacinas'
                      : _vacinasSelecionadas.join(', '),
                  suffixIcon: const Icon(Icons.vaccines),
                ),
                readOnly: true, // Torna o campo não editável
                onTap: _selecionarVacinas, // Abre o diálogo ao tocar
              ),
              
              const SizedBox(height: 15),
              
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
                onChanged: (value) {
                  setState(() {
                    _sexoSelecionado = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecione o sexo' : null,
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: _salvarEdicao,
                icon: const Icon(Icons.edit),
                label: const Text('Salvar Edição'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================= DETALHES DO GADO (COM EDIÇÃO E EXCLUSÃO) =========================
class DetalheGadoPage extends StatefulWidget {
  final Gado gado;
  // Callback para notificar a ListaGadoPage sobre a mudança/exclusão
  final VoidCallback onGadoChanged; 

  const DetalheGadoPage({super.key, required this.gado, required this.onGadoChanged});

  @override
  State<DetalheGadoPage> createState() => _DetalheGadoPageState();
}

class _DetalheGadoPageState extends State<DetalheGadoPage> {

  // Reconstroi a UI quando o gado for editado (chamado pelo callback da EditarGadoPage)
  void _refreshDetails() {
    setState(() {
      // Força a reconstrução do widget com os dados atualizados
    });
    // Notifica a lista principal
    widget.onGadoChanged();
  }

  Future<void> _registrarSaidaDialog() async {
    final tipoOptions = ['venda', 'perda'];
    String? tipoSelecionado = 'venda';
    final TextEditingController obsCtrl = TextEditingController();
    DateTime dataSelecionada = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Saída'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
              initialValue: tipoSelecionado,
              onChanged: (v) => tipoSelecionado = v,
              items: tipoOptions.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: obsCtrl,
              decoration: const InputDecoration(labelText: 'Observações (opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text('Data: ${dataSelecionada.toLocal().toString().split(' ').first}')),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dataSelecionada,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        dataSelecionada = picked;
                      });
                    }
                  },
                  child: const Text('Alterar'),
                )
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Registrar')),
        ],
      ),
    );

        if (ok == true && tipoSelecionado != null) {
      try {
        await DatabaseHelper().registrarSaida(
          gadoId: widget.gado.id,
          tipo: tipoSelecionado!,
          data: dataSelecionada,
              observacoes: obsCtrl.text.trim().isEmpty ? null : obsCtrl.text.trim(),
        );

        // Atualiza estado local
        setState(() {
          widget.gado.ativo = 0;
        });
        // Remove da lista em memória
        gadosCadastrados.removeWhere((g) => g.id == widget.gado.id);
        widget.onGadoChanged();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saída registrada (${tipoSelecionado!.toUpperCase()})')),
        );
        Navigator.pop(context); // Volta para a lista
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar saída: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _goToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarGadoPage(gado: widget.gado, onGadoEdited: _refreshDetails)),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja remover ${widget.gado.nome} da lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // 1. Remove da lista global
              // remove da lista principal
              gadosCadastrados.remove(widget.gado);
              // remove referências em propriedades (caso exista)
              for (var owner in proprietarios) {
                for (var prop in owner.propriedades) {
                  prop.gadoIds.removeWhere((id) => id == widget.gado.id);
                }
              }

              // 2. Notifica a ListaGadoPage e volta para ela
              widget.onGadoChanged();
              Navigator.of(context).pop(); // Fecha o AlertDialog
              Navigator.of(context).pop(); // Volta para a ListaGadoPage
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${widget.gado.nome} foi removido com sucesso!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gado.nome),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Icon(
                    widget.gado.sexo == 'Macho' ? Icons.pets : Icons.favorite_border,
                    color: widget.gado.sexo == 'Macho' ? Colors.blue : Colors.pink,
                    size: 80,
                  ),
                ),
                const Divider(height: 30, thickness: 1),
                
                // Exibindo as informações
                _buildInfoRow(
                  'Nome',
                  widget.gado.nome,
                  Icons.label_important,
                  Colors.green,
                ),
                _buildInfoRow(
                  'Idade',
                  '${widget.gado.idade} meses',
                  Icons.cake,
                  Colors.orange,
                ),
                _buildInfoRow(
                  'Peso',
                  '${widget.gado.peso} kg',
                  Icons.line_weight,
                  Colors.brown,
                ),
                _buildInfoRow(
                  'Sexo',
                  widget.gado.sexo,
                  widget.gado.sexo == 'Macho' ? Icons.male : Icons.female,
                  widget.gado.sexo == 'Macho' ? Colors.blue : Colors.pink,
                ),
                _buildInfoRow(
                  'Vacinas',
                  widget.gado.vacinas,
                  Icons.local_hospital,
                  Colors.red,
                ),
                const SizedBox(height: 12),
                // Foto (se for URL, exibe imagem)
                if (widget.gado.foto != null && widget.gado.foto!.startsWith('http'))
                  Center(
                    child: Image.network(widget.gado.foto!, height: 180, fit: BoxFit.cover),
                  )
                else
                  _buildInfoRow('Foto', widget.gado.foto ?? 'N/A', Icons.photo, Colors.teal),

                const SizedBox(height: 12),
                // Proprietário / Propriedade / Lote
                Builder(builder: (context) {
                  String ownerName = 'N/A';
                  String propriedadeName = 'N/A';
                  String loteName = 'N/A';
                  if (widget.gado.ownerId != null) {
                    final oi = proprietarios.indexWhere((p) => p.id == widget.gado.ownerId);
                    if (oi != -1) ownerName = proprietarios[oi].nome;
                    if (widget.gado.propriedadeId != null && oi != -1) {
                      final pi = proprietarios[oi].propriedades.indexWhere((pr) => pr.id == widget.gado.propriedadeId);
                      if (pi != -1) propriedadeName = proprietarios[oi].propriedades[pi].nome;
                      if (widget.gado.loteId != null && pi != -1) {
                        final li = proprietarios[oi].propriedades[pi].lotes.indexWhere((l) => l.id == widget.gado.loteId);
                        if (li != -1) loteName = proprietarios[oi].propriedades[pi].lotes[li].nome;
                      }
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Proprietário', ownerName, Icons.person, Colors.green),
                      _buildInfoRow('Propriedade', propriedadeName, Icons.house, Colors.brown),
                      _buildInfoRow('Lote', loteName, Icons.layers, Colors.indigo),
                    ],
                  );
                }),
                
                const SizedBox(height: 30),
                
                // Botões de Ação
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        // Chamada corrigida:
                        onPressed: () => _goToEdit(context),
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text('Editar', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _registrarSaidaDialog,
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text('Registrar Saída', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _confirmDelete,
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text('Excluir', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}