/// Validadores reutilizáveis para formulários
class Validators {
  // Validação de nome
  static String? validarNome(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }
    if (value.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    if (value.trim().length > 100) {
      return 'Nome muito longo (máximo 100 caracteres)';
    }
    // Validar caracteres especiais perigosos
    if (value.contains(RegExp(r'[<>]'))) {
      return 'Nome contém caracteres inválidos';
    }
    return null;
  }

  // Validação de nome de gado
  static String? validarNomeGado(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o nome do gado';
    }
    if (value.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    if (value.trim().length > 50) {
      return 'Nome muito longo (máximo 50 caracteres)';
    }
    if (value.contains(RegExp(r'[<>]'))) {
      return 'Nome contém caracteres inválidos';
    }
    return null;
  }

  // Validação de idade
  static String? validarIdade(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a idade';
    }
    final idade = int.tryParse(value);
    if (idade == null) {
      return 'Idade deve ser um número';
    }
    if (idade < 0) {
      return 'Idade não pode ser negativa';
    }
    if (idade > 300) {
      return 'Idade inválida (máximo 300 meses)';
    }
    return null;
  }

  // Validação de peso
  static String? validarPeso(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe o peso';
    }
    final peso = int.tryParse(value);
    if (peso == null) {
      return 'Peso deve ser um número';
    }
    if (peso <= 0) {
      return 'Peso deve ser maior que zero';
    }
    if (peso > 2000) {
      return 'Peso inválido (máximo 2000 kg)';
    }
    return null;
  }

  // Validação de email
  static String? validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o e-mail';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    if (!emailRegex.hasMatch(value)) {
      return 'E-mail inválido';
    }
    if (value.length > 255) {
      return 'E-mail muito longo';
    }
    return null;
  }

  // Validação de senha
  static String? validarSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a senha';
    }
    if (value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    if (value.length > 128) {
      return 'Senha muito longa';
    }
    // Verificar se contém letras e números
    final temLetra = RegExp(r'[a-zA-Z]').hasMatch(value);
    final temNumero = RegExp(r'[0-9]').hasMatch(value);
    if (!temLetra || !temNumero) {
      return 'Senha deve conter letras e números';
    }
    return null;
  }

  // Sanitização de string (remove caracteres perigosos)
  static String sanitizar(String input) {
    return input.trim()
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '');
  }

  // Validação de campo obrigatório genérico
  static String? campoObrigatorio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
  }

  // Validação de número positivo
  static String? numeroPositivo(String? value, {String? nomeCampo}) {
    if (value == null || value.isEmpty) {
      return 'Informe ${nomeCampo ?? "o valor"}';
    }
    final numero = num.tryParse(value);
    if (numero == null) {
      return 'Deve ser um número válido';
    }
    if (numero <= 0) {
      return 'Deve ser maior que zero';
    }
    return null;
  }

  // Validação de texto com tamanho mínimo e máximo
  static String? validarTexto(String? value, {
    int min = 1,
    int max = 255,
    String? nomeCampo,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '${nomeCampo ?? "Campo"} é obrigatório';
    }
    if (value.trim().length < min) {
      return '${nomeCampo ?? "Campo"} deve ter pelo menos $min caracteres';
    }
    if (value.trim().length > max) {
      return '${nomeCampo ?? "Campo"} muito longo (máximo $max caracteres)';
    }
    return null;
  }
}
