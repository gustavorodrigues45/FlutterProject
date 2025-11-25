import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../config/app_config.dart';
import 'mysql_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Connectivity _connectivity = Connectivity();
  
  bool _modoOffline = false;
  bool get modoOffline => _modoOffline;

  Future<void> inicializar() async {
    // Verificar conexão inicial
    await verificarConexao();
    
    // Escutar mudanças de conectividade
    _connectivity.onConnectivityChanged.listen((result) {
      _handleConectividadeChanged(result);
    });
  }

  Future<bool> verificarConexao() async {
    try {
      final result = await _connectivity.checkConnectivity();
      // Trata tanto List quanto single ConnectivityResult
      if (result is List) {
        _modoOffline = (result as List).isEmpty || 
                       (result as List).every((r) => r == ConnectivityResult.none);
      } else {
        _modoOffline = result == ConnectivityResult.none;
      }
      return !_modoOffline;
    } catch (e) {
      _modoOffline = true;
      return false;
    }
  }

  void _handleConectividadeChanged(dynamic result) {
    bool temConexao;
    
    if (result is List<ConnectivityResult>) {
      temConexao = result.isNotEmpty && !result.every((r) => r == ConnectivityResult.none);
    } else {
      temConexao = result != ConnectivityResult.none;
    }
    
    if (!_modoOffline && !temConexao) {
      // Perdeu conexão
      _modoOffline = true;
      debugPrint('Modo offline ativado');
    } else if (_modoOffline && temConexao) {
      // Recuperou conexão
      _modoOffline = false;
      debugPrint('Conexão restaurada - sincronizando dados...');
      sincronizarDados();
    }
  }

  Future<void> sincronizarDados() async {
    if (_modoOffline) {
      debugPrint('Sem conexão - sincronização adiada');
      return;
    }

    try {
      // Conectar ao MySQL se habilitado
      if (AppConfig.mysqlHabilitado) {
        final ok = await MySqlService().conectar(
          host: AppConfig.mysqlHost,
          port: AppConfig.mysqlPort,
          user: AppConfig.mysqlUser,
          password: AppConfig.mysqlPassword,
          db: AppConfig.mysqlDb,
        );
        if (!ok) {
          debugPrint('Falha ao conectar ao MySQL. Continuando sem sincronização remota.');
        }
      }

      // Buscar dados não sincronizados
      final gados = await _dbHelper.buscarTodosGados();
      final gadosNaoSincronizados = gados.where((g) => g['sincronizado'] == 0).toList();

      debugPrint('Sincronizando ${gadosNaoSincronizados.length} registros...');

      // Sincroniza com MySQL se disponível, senão apenas marca como sincronizado
      if (AppConfig.mysqlHabilitado && MySqlService().conectado) {
        for (var gado in gadosNaoSincronizados) {
          await MySqlService().syncGado(gado);
          await _dbHelper.atualizarGado(
            gado['id'],
            {...gado, 'sincronizado': 1},
          );
        }
        await MySqlService().fechar();
      } else {
        for (var gado in gadosNaoSincronizados) {
          await _dbHelper.atualizarGado(
            gado['id'],
            {...gado, 'sincronizado': 1},
          );
        }
      }

      debugPrint('Sincronização concluída');
    } catch (e) {
      debugPrint('Erro na sincronização: $e');
    }
  }

  Future<void> marcarParaSincronizar(String gadoId) async {
    final gado = await _dbHelper.buscarGadoPorId(gadoId);
    if (gado != null) {
      await _dbHelper.atualizarGado(
        gadoId,
        {...gado, 'sincronizado': 0},
      );
    }
  }
}
