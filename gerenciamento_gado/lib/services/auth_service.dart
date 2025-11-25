import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../database/database_helper.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _usuarioLogadoEmail;
  String? _usuarioLogadoNome;
  DateTime? _ultimaAtividade;
  
  String? get usuarioLogadoEmail => _usuarioLogadoEmail;
  String? get usuarioLogadoNome => _usuarioLogadoNome;
  bool get estaLogado => _usuarioLogadoEmail != null;

  // Timeout de 30 minutos
  static const Duration _timeoutDuracao = Duration(minutes: 30);

  String _hashSenha(String senha) {
    var bytes = utf8.encode(senha);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>> login(String email, String senha) async {
    try {
      // Validar entrada
      email = email.trim();
      if (email.isEmpty || senha.isEmpty) {
        return {
          'sucesso': false,
          'mensagem': 'E-mail e senha são obrigatórios',
        };
      }

      if (!_validarEmail(email)) {
        return {
          'sucesso': false,
          'mensagem': 'E-mail inválido',
        };
      }

      if (senha.length < 6) {
        return {
          'sucesso': false,
          'mensagem': 'Senha deve ter no mínimo 6 caracteres',
        };
      }

      final usuario = await _dbHelper.buscarUsuarioPorEmail(email);
      
      if (usuario == null) {
        return {
          'sucesso': false,
          'mensagem': 'Usuário não encontrado',
        };
      }

      final senhaHash = _hashSenha(senha);
      
      if (usuario['senha_hash'] != senhaHash) {
        return {
          'sucesso': false,
          'mensagem': 'Senha incorreta',
        };
      }

      _usuarioLogadoEmail = email;
      _usuarioLogadoNome = usuario['nome'];
      _ultimaAtividade = DateTime.now();

      return {
        'sucesso': true,
        'mensagem': 'Login realizado com sucesso',
        'usuario': usuario,
      };
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao fazer login: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> registrar(String nome, String email, String senha) async {
    try {
      // Sanitizar e validar entrada
      nome = nome.trim();
      email = email.trim();

      if (nome.isEmpty) {
        return {
          'sucesso': false,
          'mensagem': 'Nome é obrigatório',
        };
      }

      if (nome.length < 3 || nome.length > 100) {
        return {
          'sucesso': false,
          'mensagem': 'Nome deve ter entre 3 e 100 caracteres',
        };
      }

      if (!_validarEmail(email)) {
        return {
          'sucesso': false,
          'mensagem': 'E-mail inválido',
        };
      }

      if (senha.length < 6) {
        return {
          'sucesso': false,
          'mensagem': 'Senha deve ter no mínimo 6 caracteres',
        };
      }

      if (senha.length > 128) {
        return {
          'sucesso': false,
          'mensagem': 'Senha muito longa',
        };
      }

      // Verificar complexidade da senha
      if (!_validarSenhaForte(senha)) {
        return {
          'sucesso': false,
          'mensagem': 'Senha deve conter letras e números',
        };
      }

      // Verificar se o email já existe
      final usuarioExistente = await _dbHelper.buscarUsuarioPorEmail(email);
      
      if (usuarioExistente != null) {
        return {
          'sucesso': false,
          'mensagem': 'Este e-mail já está cadastrado',
        };
      }

      final senhaHash = _hashSenha(senha);
      
      await _dbHelper.inserirUsuario({
        'nome': nome,
        'email': email,
        'senha_hash': senhaHash,
        'criado_em': DateTime.now().toIso8601String(),
      });

      return {
        'sucesso': true,
        'mensagem': 'Usuário registrado com sucesso',
      };
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao registrar usuário: ${e.toString()}',
      };
    }
  }

  void logout() {
    _usuarioLogadoEmail = null;
    _usuarioLogadoNome = null;
    _ultimaAtividade = null;
  }

  void atualizarAtividade() {
    _ultimaAtividade = DateTime.now();
  }

  bool verificarTimeout() {
    if (_ultimaAtividade == null) return false;
    
    final agora = DateTime.now();
    final diferenca = agora.difference(_ultimaAtividade!);
    
    if (diferenca > _timeoutDuracao) {
      logout();
      return true;
    }
    
    return false;
  }

  Duration? getTempoRestante() {
    if (_ultimaAtividade == null) return null;
    
    final agora = DateTime.now();
    final tempoDecorrido = agora.difference(_ultimaAtividade!);
    final tempoRestante = _timeoutDuracao - tempoDecorrido;
    
    return tempoRestante.isNegative ? Duration.zero : tempoRestante;
  }

  // ========== MÉTODOS DE VALIDAÇÃO PRIVADOS ==========
  bool _validarEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailRegex.hasMatch(email) && email.length <= 255;
  }

  bool _validarSenhaForte(String senha) {
    // Senha deve conter letras e números
    final temLetra = RegExp(r'[a-zA-Z]').hasMatch(senha);
    final temNumero = RegExp(r'[0-9]').hasMatch(senha);
    return temLetra && temNumero;
  }
}
