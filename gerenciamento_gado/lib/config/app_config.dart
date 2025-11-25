class AppConfig {
  // Configuração MySQL - SUBSTITUA pelos seus dados reais
  static const String mysqlHost = 'localhost'; // ou IP do servidor
  static const int mysqlPort = 3306;
  static const String mysqlUser = 'root'; // seu usuário
  static const String mysqlPassword = 'senha'; // sua senha
  static const String mysqlDb = 'gerenciamento_gado'; // nome do banco

  static bool get mysqlHabilitado => mysqlHost.isNotEmpty && mysqlUser.isNotEmpty && mysqlDb.isNotEmpty;
}
