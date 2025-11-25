import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:mysql1/mysql1.dart' as mysql;

/// MySqlService com proteções de segurança
/// Usa prepared statements para prevenir SQL Injection
class MySqlService {
  static final MySqlService _instance = MySqlService._internal();
  factory MySqlService() => _instance;
  MySqlService._internal();

  mysql.MySqlConnection? _conn;

  Future<bool> conectar({
    required String host,
    required int port,
    required String user,
    required String password,
    required String db,
  }) async {
    if (kIsWeb) {
      debugPrint('MySQL não suportado no Web');
      return false;
    }
    
    try {
      // Validar parâmetros de conexão
      if (host.isEmpty || user.isEmpty || db.isEmpty) {
        throw ArgumentError('Credenciais MySQL inválidas');
      }
      
      if (port < 1 || port > 65535) {
        throw ArgumentError('Porta MySQL inválida');
      }
      
      final settings = mysql.ConnectionSettings(
        host: host,
        port: port,
        user: user,
        password: password,
        db: db,
        timeout: const Duration(seconds: 5),
      );
      _conn = await mysql.MySqlConnection.connect(settings);
      debugPrint('Conectado ao MySQL com sucesso');
      return true;
    } catch (e) {
      debugPrint('Erro ao conectar MySQL: $e');
      _conn = null;
      return false;
    }
  }

  bool get conectado => _conn != null;

  Future<void> fechar() async {
    try {
      await _conn?.close();
    } catch (_) {}
    _conn = null;
  }

  // Exemplos de sincronização com prepared statements (proteção contra SQL Injection)
  Future<void> syncGado(Map<String, dynamic> gado) async {
    if (_conn == null) {
      throw StateError('MySQL não conectado');
    }
    
    try {
      // Validar dados antes de inserir
      _validarDadosGado(gado);
      
      // Usar prepared statement com placeholders (?)
      await _conn!.query(
        'INSERT INTO gado (id, nome, idade, peso, vacinas, sexo, foto, owner_id, propriedade_id, lote_id, ativo, criado_em, atualizado_em) '
        'VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?) '
        'ON DUPLICATE KEY UPDATE nome=VALUES(nome), idade=VALUES(idade), peso=VALUES(peso), vacinas=VALUES(vacinas), '
        'sexo=VALUES(sexo), foto=VALUES(foto), owner_id=VALUES(owner_id), propriedade_id=VALUES(propriedade_id), '
        'lote_id=VALUES(lote_id), ativo=VALUES(ativo), atualizado_em=VALUES(atualizado_em)',
        [
          gado['id'], gado['nome'], gado['idade'], gado['peso'], gado['vacinas'], gado['sexo'],
          gado['foto'], gado['owner_id'], gado['propriedade_id'], gado['lote_id'], gado['ativo'] ?? 1,
          gado['criado_em'], gado['atualizado_em'],
        ],
      );
    } catch (e) {
      debugPrint('Erro ao sincronizar gado: $e');
      rethrow;
    }
  }

  Future<void> syncSaida(Map<String, dynamic> saida) async {
    if (_conn == null) {
      throw StateError('MySQL não conectado');
    }
    
    try {
      _validarDadosSaida(saida);
      
      await _conn!.query(
        'INSERT INTO saidas (gado_id, tipo, data_saida, observacoes) VALUES (?,?,?,?)',
        [saida['gado_id'], saida['tipo'], saida['data_saida'], saida['observacoes']],
      );
    } catch (e) {
      debugPrint('Erro ao sincronizar saída: $e');
      rethrow;
    }
  }

  Future<void> syncVacina(Map<String, dynamic> vacina) async {
    if (_conn == null) {
      throw StateError('MySQL não conectado');
    }
    
    try {
      _validarDadosVacina(vacina);
      
      await _conn!.query(
        'INSERT INTO vacinas_aplicadas (gado_id, vacina, data_aplicacao, proxima_dose) VALUES (?,?,?,?)',
        [vacina['gado_id'], vacina['vacina'], vacina['data_aplicacao'], vacina['proxima_dose']],
      );
    } catch (e) {
      debugPrint('Erro ao sincronizar vacina: $e');
      rethrow;
    }
  }

  // ========== MÉTODOS DE VALIDAÇÃO PRIVADOS ==========
  void _validarDadosGado(Map<String, dynamic> gado) {
    if (gado['id'] == null || gado['id'].toString().isEmpty) {
      throw ArgumentError('ID do gado inválido');
    }
    if (gado['nome'] == null || gado['nome'].toString().trim().isEmpty) {
      throw ArgumentError('Nome do gado inválido');
    }
    if (gado['idade'] == null || gado['idade'] is! int || gado['idade'] < 0) {
      throw ArgumentError('Idade inválida');
    }
    if (gado['peso'] == null || gado['peso'] is! int || gado['peso'] <= 0) {
      throw ArgumentError('Peso inválido');
    }
  }

  void _validarDadosSaida(Map<String, dynamic> saida) {
    if (saida['gado_id'] == null || saida['gado_id'].toString().isEmpty) {
      throw ArgumentError('ID do gado inválido');
    }
    if (saida['tipo'] == null || (saida['tipo'] != 'venda' && saida['tipo'] != 'perda')) {
      throw ArgumentError('Tipo de saída inválido');
    }
    if (saida['data_saida'] == null) {
      throw ArgumentError('Data de saída inválida');
    }
  }

  void _validarDadosVacina(Map<String, dynamic> vacina) {
    if (vacina['gado_id'] == null || vacina['gado_id'].toString().isEmpty) {
      throw ArgumentError('ID do gado inválido');
    }
    if (vacina['vacina'] == null || vacina['vacina'].toString().trim().isEmpty) {
      throw ArgumentError('Nome da vacina inválido');
    }
    if (vacina['data_aplicacao'] == null) {
      throw ArgumentError('Data de aplicação inválida');
    }
  }
}
