/// DatabaseHelper temporário - usa dados em memória
/// Para usar MySQL, configure AppConfig e implemente conexão real
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Simulação em memória - substitua por MySQL quando configurado
  final List<Map<String, dynamic>> _gadosMemoria = [];
  final List<Map<String, dynamic>> _saidasMemoria = [];
  final List<Map<String, dynamic>> _vacinasMemoria = [];
  final List<Map<String, dynamic>> _notificacoesMemoria = [];
  final List<Map<String, dynamic>> _transferenciasMemoria = [];
  final List<Map<String, dynamic>> _usuariosMemoria = [
    {
      'id': 1,
      'nome': 'Admin',
      'email': 'admin@gado.com',
      'senha_hash': '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', // admin123
      'criado_em': DateTime.now().toIso8601String(),
    }
  ];
  final List<Map<String, dynamic>> _proprietariosMemoria = [];
  final List<Map<String, dynamic>> _propriedadesMemoria = [];
  final List<Map<String, dynamic>> _lotesMemoria = [];

  // ========== USUÁRIOS ==========
  Future<Map<String, dynamic>?> buscarUsuarioPorEmail(String email) async {
    if (email.isEmpty || !_validarEmail(email)) {
      throw ArgumentError('Email inválido');
    }
    try {
      return _usuariosMemoria.firstWhere((u) => u['email'] == email);
    } catch (_) {
      return null;
    }
  }

  Future<void> inserirUsuario(Map<String, dynamic> usuario) async {
    if (!_validarUsuario(usuario)) {
      throw ArgumentError('Dados de usuário inválidos');
    }
    _usuariosMemoria.add({
      ...usuario,
      'id': _usuariosMemoria.length + 1,
      'nome': _sanitizarString(usuario['nome']),
      'email': _sanitizarString(usuario['email']),
    });
  }

  // ========== GADO ==========
  Future<void> inserirGado(Map<String, dynamic> gado) async {
    if (!_validarGado(gado)) {
      throw ArgumentError('Dados de gado inválidos');
    }
    _gadosMemoria.add({
      ...gado,
      'nome': _sanitizarString(gado['nome']),
      'vacinas': _sanitizarString(gado['vacinas'] ?? ''),
    });
  }

  Future<List<Map<String, dynamic>>> buscarTodosGados() async {
    return List.from(_gadosMemoria);
  }

  Future<List<Map<String, dynamic>>> buscarGadosAtivos() async {
    return _gadosMemoria.where((g) => (g['ativo'] ?? 1) == 1).toList();
  }

  Future<Map<String, dynamic>?> buscarGadoPorId(String id) async {
    try {
      return _gadosMemoria.firstWhere((g) => g['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> atualizarGado(String id, Map<String, dynamic> gado) async {
    if (id.isEmpty) {
      throw ArgumentError('ID inválido');
    }
    if (!_validarGado(gado)) {
      throw ArgumentError('Dados de gado inválidos');
    }
    final index = _gadosMemoria.indexWhere((g) => g['id'] == id);
    if (index != -1) {
      _gadosMemoria[index] = gado;
    } else {
      throw StateError('Gado não encontrado');
    }
  }

  Future<void> deletarGado(String id) async {
    _gadosMemoria.removeWhere((g) => g['id'] == id);
  }

  // ========== PROPRIETÁRIOS ==========
  Future<List<Map<String, dynamic>>> buscarProprietarios() async {
    return List.from(_proprietariosMemoria);
  }

  Future<void> inserirProprietario(Map<String, dynamic> prop) async {
    _proprietariosMemoria.add(prop);
  }

  // ========== PROPRIEDADES ==========
  Future<List<Map<String, dynamic>>> buscarPropriedadesPorProprietario(String proprietarioId) async {
    return _propriedadesMemoria.where((p) => p['proprietario_id'] == proprietarioId).toList();
  }

  Future<void> inserirPropriedade(Map<String, dynamic> prop) async {
    _propriedadesMemoria.add(prop);
  }

  // ========== LOTES ==========
  Future<List<Map<String, dynamic>>> buscarLotesPorPropriedade(String propriedadeId) async {
    return _lotesMemoria.where((l) => l['propriedade_id'] == propriedadeId).toList();
  }

  Future<void> inserirLote(Map<String, dynamic> lote) async {
    _lotesMemoria.add(lote);
  }

  // ========== NOTIFICAÇÕES ==========
  Future<List<Map<String, dynamic>>> buscarNotificacoesPendentes() async {
    final agora = DateTime.now();
    return _notificacoesMemoria.where((n) {
      if (n['enviada'] == 1) return false;
      try {
        final dataAgendada = DateTime.parse(n['data_agendada']);
        return dataAgendada.isBefore(agora) || dataAgendada.isAtSameMomentAs(agora);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<void> marcarNotificacaoEnviada(int id) async {
    final index = _notificacoesMemoria.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notificacoesMemoria[index]['enviada'] = 1;
    }
  }

  Future<void> inserirNotificacaoVacina(Map<String, dynamic> notif) async {
    _notificacoesMemoria.add({...notif, 'id': _notificacoesMemoria.length + 1});
  }

  // ========== TRANSFERÊNCIAS ==========
  Future<void> inserirTransferencia(Map<String, dynamic> transf) async {
    _transferenciasMemoria.add({...transf, 'id': _transferenciasMemoria.length + 1});
  }

  Future<List<Map<String, dynamic>>> buscarTransferenciasPorGado(String gadoId) async {
    return _transferenciasMemoria.where((t) => t['gado_id'] == gadoId).toList();
  }

  // ========== SAÍDAS ==========
  Future<void> registrarSaida({
    required String gadoId,
    required String tipo,
    required DateTime data,
    String? observacoes,
  }) async {
    _saidasMemoria.add({
      'id': _saidasMemoria.length + 1,
      'gado_id': gadoId,
      'tipo': tipo,
      'data_saida': data.toIso8601String(),
      'observacoes': observacoes,
    });

    // Marcar gado como inativo
    final index = _gadosMemoria.indexWhere((g) => g['id'] == gadoId);
    if (index != -1) {
      _gadosMemoria[index]['ativo'] = 0;
      _gadosMemoria[index]['atualizado_em'] = DateTime.now().toIso8601String();
    }
  }

  Future<List<Map<String, dynamic>>> buscarSaidasPorPeriodo({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    return _saidasMemoria.where((s) {
      try {
        final data = DateTime.parse(s['data_saida']);
        return (data.isAfter(inicio) || data.isAtSameMomentAs(inicio)) &&
               (data.isBefore(fim) || data.isAtSameMomentAs(fim));
      } catch (_) {
        return false;
      }
    }).toList();
  }

  // ========== VACINAS APLICADAS ==========
  Future<void> inserirVacinaAplicada(Map<String, dynamic> vacina) async {
    _vacinasMemoria.add({...vacina, 'id': _vacinasMemoria.length + 1});
  }

  Future<List<Map<String, dynamic>>> buscarVacinasPorPeriodo({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    return _vacinasMemoria.where((v) {
      try {
        final data = DateTime.parse(v['data_aplicacao']);
        return (data.isAfter(inicio) || data.isAtSameMomentAs(inicio)) &&
               (data.isBefore(fim) || data.isAtSameMomentAs(fim));
      } catch (_) {
        return false;
      }
    }).toList();
  }

  // ========== MÉTRICAS DASHBOARD ==========
  Future<Map<String, int>> obterMetricasDashboard() async {
    final total = _gadosMemoria.length;
    final ativos = _gadosMemoria.where((g) => (g['ativo'] ?? 1) == 1).length;
    final inativos = total - ativos;

    final agora = DateTime.now();
    final inicio30 = agora.subtract(const Duration(days: 30));

    final vendas = _saidasMemoria.where((s) {
      if (s['tipo'] != 'venda') return false;
      try {
        final data = DateTime.parse(s['data_saida']);
        return data.isAfter(inicio30);
      } catch (_) {
        return false;
      }
    }).length;

    final perdas = _saidasMemoria.where((s) {
      if (s['tipo'] != 'perda') return false;
      try {
        final data = DateTime.parse(s['data_saida']);
        return data.isAfter(inicio30);
      } catch (_) {
        return false;
      }
    }).length;

    final fim7 = agora.add(const Duration(days: 7));
    final proximasVacinas = _notificacoesMemoria.where((n) {
      if (n['enviada'] == 1) return false;
      try {
        final data = DateTime.parse(n['data_agendada']);
        return data.isAfter(agora) && data.isBefore(fim7);
      } catch (_) {
        return false;
      }
    }).length;

    return {
      'total': total,
      'ativos': ativos,
      'inativos': inativos,
      'vendas30': vendas,
      'perdas30': perdas,
      'proximasVacinas7': proximasVacinas,
    };
  }

  // ========== MÉTODOS DE VALIDAÇÃO PRIVADOS ==========
  bool _validarEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _validarUsuario(Map<String, dynamic> usuario) {
    return usuario['nome'] != null && 
           usuario['nome'].toString().trim().isNotEmpty &&
           usuario['email'] != null && 
           _validarEmail(usuario['email'].toString()) &&
           usuario['senha_hash'] != null &&
           usuario['senha_hash'].toString().length >= 32;
  }

  bool _validarGado(Map<String, dynamic> gado) {
    if (gado['id'] == null || gado['id'].toString().isEmpty) return false;
    if (gado['nome'] == null || gado['nome'].toString().trim().isEmpty) return false;
    
    // Validar idade (entre 0 e 300 meses)
    final idade = gado['idade'];
    if (idade == null || idade is! int || idade < 0 || idade > 300) return false;
    
    // Validar peso (entre 0 e 2000 kg)
    final peso = gado['peso'];
    if (peso == null || peso is! int || peso < 0 || peso > 2000) return false;
    
    // Validar sexo
    final sexo = gado['sexo']?.toString();
    if (sexo == null || (sexo != 'Macho' && sexo != 'Fêmea')) return false;
    
    return true;
  }

  String _sanitizarString(String input) {
    return input.trim().replaceAll(RegExp(r'''[<>"']'''), '');
  }
}
