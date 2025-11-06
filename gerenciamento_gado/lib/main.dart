import 'package:flutter/material.dart';

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

void main() {
  runApp(const GerenciamentoGadoApp());
}

// ========================= MODELO DE DADOS (MUTÁVEL PARA EDIÇÃO) =========================
class Gado {
  String nome;
  String idade;
  String peso;
  String vacinas; // String contendo vacinas separadas por vírgula
  String sexo;

  Gado({
    required this.nome,
    required this.idade,
    required this.peso,
    required this.vacinas,
    required this.sexo,
  });
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

  void _login() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
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
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              ElevatedButton(
                onPressed: _login,
                child: const Text('Entrar'),
              ),
              TextButton(
                onPressed: _goToRegister,
                child: const Text('Criar conta'),
              ),
            ],
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

  void _register() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário cadastrado com sucesso!')),
      );
      Navigator.pop(context);
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
              ElevatedButton(
                onPressed: _register,
                child: const Text('Cadastrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================= DASHBOARD (PAINEL) =========================
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dashboard, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Bem-vindo ao Painel!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text('Selecione uma opção abaixo:'),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _goToGadoCadastro(context),
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar Novo Gado'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _goToGadoList(context),
              icon: const Icon(Icons.list),
              label: const Text('Ver Lista de Gados'),
            ),
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

  String? _sexoSelecionado;
  // NOVO: Armazena as vacinas selecionadas
  List<String> _vacinasSelecionadas = [];

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

  void _salvarCadastro() {
    if (_formKey.currentState!.validate()) {
      final novoGado = Gado(
        nome: _nomeController.text,
        idade: _idadeController.text,
        peso: _pesoController.text,
        // NOVO: Salva as vacinas como uma string formatada ou "N/A"
        vacinas: _vacinasSelecionadas.isEmpty
            ? 'N/A'
            : _vacinasSelecionadas.join(', '), // Junta as vacinas com vírgula
        sexo: _sexoSelecionado ?? 'Não informado',
      );

      gadosCadastrados.add(novoGado);

      // Limpa os campos para novo cadastro
      _nomeController.clear();
      _idadeController.clear();
      _pesoController.clear();
      setState(() {
        _sexoSelecionado = null;
        _vacinasSelecionadas = []; // Limpa a seleção
      });

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
                value: _sexoSelecionado,
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

    return Scaffold(
      appBar: AppBar(title: Text('Gado Cadastrado (${gadosCadastrados.length})')),
      body: ListView.builder(
        itemCount: gadosCadastrados.length,
        itemBuilder: (context, index) {
          final gado = gadosCadastrados[index];
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
  // REMOVIDO: late TextEditingController _vacinasController;

  String? _sexoSelecionado;
  // NOVO: Lista mutável para as vacinas na edição
  late List<String> _vacinasSelecionadas; 

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.gado.nome);
    _idadeController = TextEditingController(text: widget.gado.idade);
    _pesoController = TextEditingController(text: widget.gado.peso);
    _sexoSelecionado = widget.gado.sexo == 'Não informado' ? null : widget.gado.sexo;
    
    // NOVO: Inicializa a lista de vacinas, separando a string por vírgulas
    _vacinasSelecionadas = widget.gado.vacinas == 'N/A'
        ? []
        : widget.gado.vacinas.split(', ').toList();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _idadeController.dispose();
    _pesoController.dispose();
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


  void _salvarEdicao() {
    if (_formKey.currentState!.validate()) {
      // 1. Atualiza o objeto Gado original
      widget.gado.nome = _nomeController.text;
      widget.gado.idade = _idadeController.text;
      widget.gado.peso = _pesoController.text;
      // NOVO: Atualiza a string de vacinas
      widget.gado.vacinas = _vacinasSelecionadas.isEmpty
          ? 'N/A'
          : _vacinasSelecionadas.join(', ');
      widget.gado.sexo = _sexoSelecionado ?? 'Não informado';

      // 2. Chama o callback para notificar a tela de detalhes
      widget.onGadoEdited();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.gado.nome} atualizado com sucesso!')),
      );

      // Volta para a tela de detalhes
      Navigator.pop(context);
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
                value: _sexoSelecionado,
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
              gadosCadastrados.remove(widget.gado);

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